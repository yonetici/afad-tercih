-- ============================================================
-- AFAD Tercih Sistemi — Supabase kurulum SQL'i
-- Supabase > SQL Editor'a yapıştırıp "Run" deyin.
-- (Ücretsiz proje yeterlidir.)
-- ============================================================

-- 1) TABLOLAR -------------------------------------------------
create table if not exists candidates (
  sira    int primary key,          -- liyakat / başarı sırası (küçük = yüksek öncelik)
  ad      text,
  soyad   text,
  il      text,                      -- mevcut görev yeri
  locked  boolean not null default false  -- admin son tarihte tercihleri kilitleyebilir
);

create table if not exists preferences (
  sira       int primary key references candidates(sira) on delete cascade,
  prefs      jsonb not null default '[]'::jsonb,   -- ["Hatay","Mersin",...] (sıralı)
  updated_at timestamptz not null default now()
);

create table if not exists app_settings (
  key text primary key,
  value text
);

-- açık kadrolar (EK-1 PDF, Şube Müdürü Sayısı — 63 il / 109)
create table if not exists quota (
  il   text primary key,
  sayi int  not null
);
insert into quota(il, sayi) values
 ('Adana',3),('Adıyaman',2),('Ağrı',3),('Aksaray',2),('Amasya',2),('Antalya',3),('Ardahan',1),('Artvin',2),('Aydın',2),('Balıkesir',2),
 ('Bartın',2),('Bayburt',1),('Bilecik',1),('Bitlis',1),('Bolu',2),('Burdur',1),('Çanakkale',1),('Denizli',2),('Diyarbakır',1),('Düzce',1),
 ('Edirne',2),('Elazığ',3),('Erzincan',1),('Giresun',3),('Hakkari',2),('Hatay',4),('Iğdır',1),('Isparta',1),('İstanbul',1),('İzmir',1),
 ('Karabük',1),('Karaman',2),('Kars',2),('Kastamonu',2),('Kayseri',2),('Kırıkkale',1),('Kırklareli',1),('Kilis',1),('Kocaeli',2),('Kütahya',1),
 ('Malatya',3),('Manisa',1),('Mardin',1),('Mersin',4),('Muğla',1),('Nevşehir',1),('Niğde',1),('Ordu',2),('Osmaniye',2),('Rize',2),
 ('Sakarya',1),('Siirt',2),('Sinop',1),('Şanlıurfa',2),('Şırnak',2),('Tekirdağ',2),('Trabzon',2),('Tunceli',1),('Uşak',2),('Van',1),
 ('Yalova',2),('Yozgat',1),('Zonguldak',3)
on conflict (il) do nothing;
alter table quota enable row level security;

-- 2) YÖNETİCİ ANAHTARI — MUTLAKA DEĞİŞTİRİN ------------------
insert into app_settings(key, value)
values ('admin_key', 'BUNU-DEGISTIRIN-gizli-bir-anahtar')
on conflict (key) do nothing;

-- 3) RLS: tablolara doğrudan erişimi kapat (her şey fonksiyonla)
alter table candidates   enable row level security;
alter table preferences  enable row level security;
alter table app_settings enable row level security;

-- 4) FONKSİYONLAR -------------------------------------------
create or replace function _is_admin(p_key text) returns boolean
language sql security definer stable as $$
  select exists(select 1 from app_settings where key='admin_key' and value=p_key);
$$;

-- isim normalizasyonu (Türkçe karakter/boşluk/büyük-küçük farkını giderir)
create or replace function _norm(t text) returns text
language sql immutable as $$
  select btrim(upper(regexp_replace(
    translate(coalesce(t,''), 'çÇğĞıİöÖşŞüÜ', 'cCgGiIoOsSuU'),
    '\s+', ' ', 'g')));
$$;

-- GİRİŞ: sıra no + İL (mevcut görev yeri) doğrula; eşleşirse {prefs, locked, ad, soyad} döndür, yoksa null
create or replace function login(p_sira int, p_il text)
returns jsonb language plpgsql security definer stable as $$
declare c candidates; pr jsonb;
begin
  select * into c from candidates where sira=p_sira;
  if not found then return null; end if;
  if _norm(c.il)<>_norm(p_il) then return null; end if;
  select prefs into pr from preferences where sira=p_sira;
  return jsonb_build_object('prefs', coalesce(pr,'[]'::jsonb), 'locked', c.locked,
                            'ad', c.ad, 'soyad', c.soyad);
end; $$;

-- aday tercih kaydet/güncelle (sıra+İL doğrulamalı)
create or replace function save_preferences(p_sira int, p_il text, p_prefs jsonb)
returns text language plpgsql security definer as $$
declare c candidates;
begin
  select * into c from candidates where sira=p_sira;
  if not found then return 'NOTFOUND'; end if;
  if _norm(c.il)<>_norm(p_il) then return 'BADIDENTITY'; end if;
  if c.locked then return 'LOCKED'; end if;
  insert into preferences(sira, prefs, updated_at) values (p_sira, p_prefs, now())
    on conflict (sira) do update set prefs=excluded.prefs, updated_at=now();
  return 'OK';
end; $$;

-- LİYAKAT-DUYARLI UYGUNLUK: p_sira'dan YÜKSEK sıradaki (sira<p_sira) adaylar
-- tercihleriyle yerleştirildikten sonra her ilde KALAN kadro. 0 olanlar adaya kapalıdır.
create or replace function available_quota(p_sira int)
returns table(il text, kalan int)
language plpgsql security definer stable as $$
declare
  rem jsonb;
  c   record;
  arr jsonb;
  i   int;
  pr  text;
begin
  select jsonb_object_agg(q.il, q.sayi) into rem from quota q;
  for c in
    select cand.sira, p.prefs
    from candidates cand join preferences p on p.sira=cand.sira
    where cand.sira < p_sira
    order by cand.sira asc
  loop
    arr := c.prefs;
    for i in 0 .. coalesce(jsonb_array_length(arr),0)-1 loop
      pr := arr->>i;
      if (rem ? pr) and (rem->>pr)::int > 0 then
        rem := jsonb_set(rem, array[pr], to_jsonb((rem->>pr)::int - 1));
        exit;
      end if;
    end loop;
  end loop;
  return query select key, value::int from jsonb_each_text(rem);
end; $$;

-- ADMIN: tüm tercihleri çek
create or replace function admin_export(p_key text)
returns table(sira int, ad text, soyad text, il text, prefs jsonb)
language plpgsql security definer as $$
begin
  if not _is_admin(p_key) then return; end if;
  return query
    select c.sira, c.ad, c.soyad, c.il, coalesce(p.prefs, '[]'::jsonb)
    from candidates c left join preferences p on p.sira=c.sira
    order by c.sira;
end; $$;

-- ADMIN: tüm tercihleri kilitle/aç (kilitliyken aday değiştiremez)
create or replace function admin_set_lock(p_key text, p_locked boolean)
returns int language plpgsql security definer as $$
declare n int;
begin
  if not _is_admin(p_key) then return -1; end if;
  update candidates set locked=p_locked;
  get diagnostics n = row_count;
  return n;
end; $$;

-- ADMIN: aday listesini yükle/güncelle (tercihleri korur)
create or replace function admin_seed(p_key text, p_rows jsonb)
returns int language plpgsql security definer as $$
declare r jsonb; n int := 0;
begin
  if not _is_admin(p_key) then return -1; end if;
  for r in select * from jsonb_array_elements(p_rows) loop
    insert into candidates(sira, ad, soyad, il)
    values ((r->>'sira')::int, r->>'ad', r->>'soyad', r->>'il')
    on conflict (sira) do update
      set ad=excluded.ad, soyad=excluded.soyad, il=excluded.il;
    n := n + 1;
  end loop;
  return n;
end; $$;

-- 5) anon role'a fonksiyon çalıştırma yetkisi
grant execute on function login(int,text)                      to anon;
grant execute on function available_quota(int)                 to anon;
grant execute on function save_preferences(int,text,jsonb)     to anon;
grant execute on function admin_export(text)                   to anon;
grant execute on function admin_seed(text,jsonb)               to anon;
grant execute on function admin_set_lock(text,boolean)         to anon;

-- BİTTİ. Kontrol: select * from admin_export('YONETICI-ANAHTARINIZ');
