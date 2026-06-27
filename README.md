# AFAD Şube Müdürü — Tercih & Yerleştirme Sistemi

Görevde yükselme / ünvan değişikliği sınavı sonrası, adayların il tercihlerine göre
**liyakat sırasına dayalı otomatik yerleştirme** ve **çakışma analizi** yapan statik web uygulaması.

Sunucu gerektirmez. GitHub Pages / Netlify / Cloudflare Pages gibi statik bir yere yüklenir.
Adayların kendi tercihlerini girmesi için (isteğe bağlı) ücretsiz **Supabase** bulut veritabanı kullanılır
— bu da barındırılması gereken bir sunucu değil, yönetilen bir serviste tablodur.

## Dosyalar

| Dosya | Görevi |
|---|---|
| `index.html` | **Yönetici** paneli: Dashboard (harita), yerleştirme, çakışma, Excel **veya** Supabase. |
| `tercih.html` | **Aday** sayfası: harita + tablodan, liyakatına uygun kadrolardan tercih; Supabase'e kaydeder. |
| `data.js` | Ortak il listesi + kadrolar (EK-1 PDF, 63 il / 109 kadro). |
| `map.js` | Türkiye haritası (GeoJSON → SVG; bağımlılıksız). İki sayfa da kullanır. |
| `config.js` | Supabase URL + anahtar + `MAX_PREFS` (tercih sayısı) + `REQUIRE_CODE`. Boşsa sadece Excel modu. |
| `SUPABASE_KURULUM.sql` | Supabase'te bir kez çalıştırılacak kurulum SQL'i (tablolar, kadrolar, RLS, fonksiyonlar). |

## Aday tercih ekranı (tercih.html)

- Aday **sıra no + İL (mevcut görev yeri)** ile giriş yapar → **Türkiye haritası ve tablo** açılır.
  Haritada her açık il **adıyla** etiketlidir; üzerine gelince kadro/kalan/durum gösterilir.
- Kayıttan sonra **🖨️ Özet / PDF** ile kişisel tercih dökümü alınabilir.
- **Liyakat-duyarlı uygunluk:** kendisinden **üst sıradaki** adayların doldurduğu kadrolar
  haritada **kırmızı / "dolu"** olur ve **seçilemez**. Boş olanlar yeşil, kendi seçimi mavi.
- Haritadan il tıklayarak ya da tablodan "ekle" ile **en fazla `MAX_PREFS` (vars. 4)** tercih sıralar.
- Üstte **tahmini yerleşeceği il** canlı gösterilir (üst sıra adaylara göre).

## İki çalışma modu

### A) Sadece Excel / Google Sheets (Supabase'siz, en hızlı başlangıç)
`config.js` boş bırakılabilir. Yönetici, aday verisini `index.html`'e iki yoldan yükler:
- **Excel:** `.xlsx` dosyasını "Excel Seç" ile yükle.
- **Google Sheets (otomatik):** Herkese açık ("Bağlantıya sahip herkes görüntüleyebilir")
  bir Google Sheets bağlantısını yapıştırıp **Çek** → veri doğrudan çekilir (indirme yok).
  İsteğe bağlı: `config.js` içine `window.SHEET_URL = "...edit"` yazarsan alan otomatik dolar.

Beklenen kolonlar (her iki yolda da):

| f (sıra no) | İL (mevcut) | Ad | Soyad | 1. TERCİH | 2. TERCİH | … |

- Bir hücrede `/` ile birden fazla il yazılırsa otomatik ayrıştırılır.
- Türkçe karakter / büyük-küçük / boşluk farkları normalize edilir.

### B) Adaylar kendi girer (Supabase)
1. [supabase.com](https://supabase.com) → ücretsiz proje aç.
2. **SQL Editor** → `SUPABASE_KURULUM.sql` içeriğini yapıştır → Run. (İçindeki `admin_key`'i değiştir!)
3. **Project Settings > API** → `Project URL` ve `anon public` anahtarını `config.js`'e yaz.
4. `index.html`'i aç → önce **Excel'i yükle** (109 kişilik roster) → **"Aday Listesini Supabase'e Yükle"**.
   Bu, adayları (sıra no, ad, soyad, il) Supabase'e yazar.
5. Adaylara `tercih.html` linkini ve kendi **sıra numaralarını** ilet.
   Aday: **sıra no + mevcut görev ili** ile giriş yapar → uygun illerden tercihini sıralar → kaydeder.
   Aday kaydından sonra **🖨️ Özet / PDF** ile tercih dökümünü yazdırabilir/PDF alabilir.
6. Yönetici: `index.html` → **Dashboard** → yönetici anahtarını gir → **"🔄 Supabase'ten Yenile"**
   (veya oto-yenile) → yerleştirme ve harita canlı güncellenir.
7. Tercih süresi bitince **"🔒 Tercihleri Kilitle"** ile değişikliği kapatın (adaylar yalnız görüntüler).
   Gerekirse **"🔓 Tercihleri Aç"** ile yeniden açılır.

> Aday girişi **sıra no + İL** ile doğrulanır (Türkçe karakter/büyük-küçük/boşluk duyarsız;
> isimlerdeki noktalama/iki ad sorununu önler). Ayrı kod dağıtmaya gerek yoktur.
> `anon` anahtarı istemcide paylaşılmak için tasarlanmıştır; güvenliği RLS + fonksiyonlar sağlar.
> Tüm tablo erişimi kapalıdır; okuma/yazma yalnızca kimlik/anahtar doğrulayan fonksiyonlar üzerinden olur.

## Yönetici panelindeki sekmeler

- **📥 Veri Yükle** — Excel veya Supabase; yükleme özeti.
- **📊 Dashboard** — Türkiye haritası (doluluk renkli: yeşil boş / sarı kısmi / kırmızı dolu) +
  il bazında yerleşim tablosu; **🔄 Supabase'ten Yenile** ve **oto-yenile (15sn)** ile canlı izleme.
- **🏛️ Kadrolar** — düzenlenebilir kadro tablosu (EK-1 PDF: 63 il, **toplam 109**), talep vs kadro.
- **✅ Yerleştirme** — kim nereye / kaçıncı tercihiyle; açıkta kalanlar; Excel'e aktarma.
- **⚔️ Çakışmalar** — bir ili kadrodan fazla seçenleri liyakat sırasıyla dizer; kazananları ve
  kaybedenlerin **alternatif tercihine göre nereye düştüğünü** gösterir.
- **⚠️ Uyarılar** — tercih girmemiş/eksik girenler, tanınmayan il, açıkta kalanlar.

## Yerleştirme algoritması

Liyakat sırasına göre (`f` / sıra no — küçük numara = yüksek öncelik) **serial dictatorship**:

> Adaylar liyakat sırasıyla tek tek işlenir. Her aday, henüz kadrosu dolmamış **en yüksek
> sıradaki tercihine** yerleştirilir. Hiçbir tercihinde boş kadro yoksa açıkta kalır.

Deterministik, itiraz edilemez; "herkes mümkün olduğunca üst tercihine" sonucunu verir.

## GitHub Pages'e yükleme

1. Yeni repo oluşturun, bu klasördeki **tüm dosyaları** (index.html, tercih.html, data.js, config.js) köke koyun.
2. Repo ayarları → Pages → kaynak `main` / `(root)`.
3. Adaylara `https://<kullanıcı>.github.io/<repo>/tercih.html`, kendinize `.../index.html`.

## Notlar

- Kadrolar EK-1 Münhal Kadrolar PDF'indeki *Şube Müdürü "Sayısı"* sütunundan: **63 ilde 109 kadro = 109 aday**.
  Tüm adaylar tercihlerini eksiksiz girdiğinde kimse açıkta kalmaz.
- Excel okuma/yazma için SheetJS, bulut için supabase-js CDN'den yüklenir (internet gerekir).
