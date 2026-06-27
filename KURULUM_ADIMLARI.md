# Kurulum & Devreye Alma — Adım Adım (Supabase'i ilk kez kullananlar için)

Toplam süre ~15 dk. Sırayla yapın.

---

## BÖLÜM 1 — Supabase projesi oluştur (~5 dk)

1. https://supabase.com → sağ üstten **Start your project** / **Sign in**.
   GitHub hesabıyla veya e-posta ile ücretsiz kaydolun.
2. Açılan panelde **New project**.
   - **Name:** afad-tercih (ne isterseniz)
   - **Database Password:** güçlü bir şifre girin ve **bir yere kaydedin** (lazım olmayabilir ama saklayın).
   - **Region:** **Central EU (Frankfurt)** seçin (Türkiye'ye en yakın, en hızlısı).
   - **Plan:** Free.
   - **Create new project** → kurulum 1-2 dk sürer, bekleyin.

---

## BÖLÜM 2 — Veritabanını kur (SQL çalıştır) (~3 dk)

1. Sol menüde **SQL Editor** (terminal ikonu) → **+ New query**.
2. Bilgisayarınızdaki **`SUPABASE_KURULUM.sql`** dosyasını bir metin editörüyle açın, **tümünü kopyalayın**, SQL Editor'a **yapıştırın**.
3. **ÖNEMLİ:** Yapıştırdığınız metinde şu satırı bulun ve tırnak içini **kendi gizli anahtarınızla** değiştirin:
   ```
   values ('admin_key', 'BUNU-DEGISTIRIN-gizli-bir-anahtar')
   ```
   Örn: `values ('admin_key', 'Afad2026!yonetici')`
   → Bu, **yönetici anahtarınız**. Kimseyle paylaşmayın; yerleştirme verisini sadece bununla çekebilirsiniz.
4. Sağ alttaki **Run** (veya Ctrl/Cmd+Enter). "Success. No rows returned" görmelisiniz.
   - Kontrol için yeni bir sorgu: `select count(*) from quota;` → **63** dönmeli.

---

## BÖLÜM 3 — API bilgilerini al ve config.js'e yaz (~2 dk)

1. Sol altta **Project Settings** (dişli) → **API**.
2. İki değeri kopyalayın:
   - **Project URL** (örn. `https://abcd1234.supabase.co`)
   - **Project API keys** altındaki **`anon` `public`** anahtarı (uzun `eyJ...` ile başlayan).
     > ⚠️ **`service_role` / `secret` anahtarını ASLA kullanmayın/paylaşmayın.** Sadece `anon public`.
3. Bilgisayarınızda **`config.js`** dosyasını açın, şu iki satırı doldurun:
   ```js
   window.SUPABASE_URL = "https://abcd1234.supabase.co";
   window.SUPABASE_ANON_KEY = "eyJhbGciOi....(anon public anahtarınız)";
   ```
   (`MAX_PREFS = 4` aynı kalsın — tercih sayısı.)
4. Kaydedin.

> Not: `anon public` anahtarı tarayıcıda görünmek için tasarlanmıştır, güvenlidir.
> Veriyi RLS kuralları ve fonksiyonlar korur. `admin_key` ise hiçbir dosyada değildir,
> yalnızca yönetici panelinde çalışırken yazılır.

---

## BÖLÜM 4 — Siteyi yayına al (GitHub Pages, ~3 dk)

1. https://github.com → giriş yapın → **New repository** → ad verin (örn. `tercih`) → **Public** → **Create**.
2. Repo sayfasında **Add file → Upload files** → şu 5 dosyayı sürükleyip bırakın:
   `index.html`, `tercih.html`, `data.js`, `map.js`, `config.js`
   (doldurduğunuz config.js dahil) → **Commit changes**.
3. **Settings → Pages** → **Source: Deploy from a branch** → **Branch: main**, klasör **/(root)** → **Save**.
4. 1-2 dk sonra sayfanın üstünde adres çıkar:
   - Yönetici: `https://KULLANICI.github.io/tercih/index.html`
   - Aday:     `https://KULLANICI.github.io/tercih/tercih.html`

> Güvenlik tercihi: index.html herkese açık olsa bile yönetici işlemleri `admin_key` ister.
> Daha da güvenli istiyorsanız index.html'i siteye koymayıp kendi bilgisayarınızda açabilirsiniz;
> adaylara yalnızca tercih.html linkini verirsiniz.

---

## BÖLÜM 5 — Aday listesini sisteme yükle (~2 dk)

1. **index.html**'i açın (yayındaki adres veya yerel).
2. **📥 Veri Yükle** sekmesi → **📂 Excel Seç** → güncel Excel'inizi (`AFAD ŞUBE MÜDÜRÜ.xlsx`) seçin.
   109 aday okunur.
3. Aynı sekmedeki **Supabase** bölümünde **Yönetici anahtarı** kutusuna BÖLÜM 2'de belirlediğiniz
   `admin_key`'i yazın.
4. **⬆️ Aday Listesini Supabase'e Yükle** → "109 aday yazıldı" mesajı.
   (Bu, sıra no + ad + soyad + il bilgisini Supabase'e kaydeder; doğrulama bunlarla yapılır.)

---

## BÖLÜM 6 — Test et (1 aday gibi gir)

1. **tercih.html**'i açın.
2. Örn. Sıra No **54**, İl **Bursa** (54. sıradaki kişinin ili) → **Giriş yap**.
3. Harita + tablo açılmalı; birkaç il seçip **Kaydet** → "kaydedildi" mesajı.
4. index.html → **📊 Dashboard** → anahtarı yazıp **🔄 Supabase'ten Yenile** → seçimin yansıdığını görün.

---

## BÖLÜM 7 — Adaylara duyur

- Adaylara **tercih.html linkini** ve **kendi sıra numaralarını** iletin.
  (İllerini zaten biliyorlar — giriş = sıra no + mevcut il.)
- Aday: girer → uygun illerden 4 taneye kadar sıralar → Kaydet → isterse 🖨️ Özet/PDF alır.

## BÖLÜM 8 — İzleme ve kapatma

- **Dashboard** → **oto-yenile (15sn)** ile süreci canlı izleyin (harita + tablo).
- Süre bitince **📥 Veri Yükle** → **🔒 Tercihleri Kilitle** → adaylar artık değiştiremez.
- Nihai sonuç: **✅ Yerleştirme** sekmesi (Excel'e aktarılabilir), **⚔️ Çakışmalar** detayları.

---

### Sık sorunlar
- **"yapılandırılmamış (config.js boş)"** → BÖLÜM 3'teki URL/anahtar boş ya da yanlış.
- **Aday "Kimlik doğrulanamadı"** → sıra no ya da il, Supabase'teki kayıtla uyuşmuyor
  (önce BÖLÜM 5'i yaptınız mı? İl yazımı önemli değil, sistem normalize eder).
- **Dashboard "Yetkisiz"** → yönetici anahtarı, SQL'de yazdığınız `admin_key` ile birebir aynı olmalı.
- **Harita çıkmıyor** → internet gerekir (harita ve kütüphaneler CDN'den yüklenir).
