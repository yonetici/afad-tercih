/* ============================================================
   SUPABASE AYARLARI  —  BURAYI BİR KEZ DOLDURUN
   ------------------------------------------------------------
   1) https://supabase.com adresinden ücretsiz bir proje açın.
   2) Project Settings > API ekranından:
        - "Project URL"  -> SUPABASE_URL
        - "anon public" anahtarı -> SUPABASE_ANON_KEY
      (anon anahtarı istemci tarafında paylaşılmak için tasarlanmıştır,
       güvenlidir; RLS kuralları korur.)
   3) README.md içindeki SQL'i Supabase SQL Editor'da çalıştırın.
   Doldurmadan bırakırsanız uygulama yalnızca Excel modunda çalışır.
   ============================================================ */
window.SUPABASE_URL = "";        // örn: "https://abcd1234.supabase.co"
window.SUPABASE_ANON_KEY = "";   // örn: "eyJhbGciOiJIUzI1NiІ...."

/* Aday girişi: Sıra No + Ad + Soyad ile doğrulanır (üçü de roster'la eşleşmeli).
   Ayrı bir kod dağıtmaya gerek yoktur. */

/* Bir adayın yapabileceği en fazla tercih sayısı (ilk aşama için 3-4 önerilir) */
window.MAX_PREFS = 4;
