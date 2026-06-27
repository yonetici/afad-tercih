// Google Sheets -> Supabase senkronu (GitHub Actions saatlik çalıştırır)
// Sadece ADMIN_KEY secret'ı gerekir; URL/anon/sheet bilgisi repodaki config.js/data.js'ten okunur.
import fs from 'node:fs';

const here = (p) => new URL(p, import.meta.url);

// --- data.js'ten ortak fonksiyonlar ---
const dataCode = fs.readFileSync(here('../data.js'), 'utf8');
const M = new Function(dataCode + '; return {parseCandidateRows, sheetCsvUrl, DEFAULT_SHEET_URL, DEFAULT_QUOTA};')();

// --- config.js'ten Supabase bilgileri ---
const cfgCode = fs.readFileSync(here('../config.js'), 'utf8');
const win = {};
new Function('window', cfgCode)(win);

const SUPABASE_URL = process.env.SUPABASE_URL || win.SUPABASE_URL;
const ANON         = process.env.SUPABASE_ANON_KEY || win.SUPABASE_ANON_KEY;
const SHEET        = process.env.SHEET_URL || win.SHEET_URL || M.DEFAULT_SHEET_URL;
const ADMIN_KEY    = process.env.ADMIN_KEY;

if (!SUPABASE_URL || !ANON) { console.error('HATA: config.js içinde SUPABASE_URL/ANON yok.'); process.exit(1); }
if (!ADMIN_KEY) { console.error('HATA: ADMIN_KEY secret tanımlı değil (repo Settings > Secrets).'); process.exit(1); }

// --- basit CSV ayrıştırıcı (tırnaklı hücre destekli) ---
function parseCSV(t){
  const rows=[]; let row=[], cur='', q=false;
  for (let i=0;i<t.length;i++){ const ch=t[i];
    if (q){ if (ch==='"'){ if (t[i+1]==='"'){ cur+='"'; i++; } else q=false; } else cur+=ch; }
    else { if (ch==='"') q=true;
      else if (ch===',') { row.push(cur); cur=''; }
      else if (ch==='\n'){ row.push(cur); rows.push(row); row=[]; cur=''; }
      else if (ch!=='\r') cur+=ch; }
  }
  if (cur!=='' || row.length){ row.push(cur); rows.push(row); }
  return rows;
}

async function rpc(fn, body){
  const r = await fetch(`${SUPABASE_URL}/rest/v1/rpc/${fn}`, {
    method:'POST',
    headers:{ apikey:ANON, Authorization:`Bearer ${ANON}`, 'Content-Type':'application/json' },
    body: JSON.stringify(body)
  });
  const txt = await r.text();
  if (!r.ok) throw new Error(`${fn} -> HTTP ${r.status}: ${txt}`);
  return txt.trim();
}

(async () => {
  const res = await fetch(M.sheetCsvUrl(SHEET));
  if (!res.ok) throw new Error('Sheet çekilemedi: HTTP ' + res.status);
  const csv = await res.text();
  if (/<html/i.test(csv)) throw new Error('Sheet herkese açık değil (giriş istiyor).');

  const cands = M.parseCandidateRows(parseCSV(csv));
  if (!cands.length) throw new Error('Sheet boş ya da format farklı.');

  const candidatesRows = cands.map(c => ({ sira:c.sira, ad:c.ad, soyad:c.soyad, il:c.il }));
  const prefsRows = cands
    .map(c => ({ sira:c.sira, prefs: c.prefs.filter(p => p.valid && M.DEFAULT_QUOTA[p.canon] != null).map(p => p.canon) }))
    .filter(r => r.prefs.length);

  const a = await rpc('admin_seed',       { p_key:ADMIN_KEY, p_rows:candidatesRows });
  if (a === '-1') throw new Error('admin_seed: yetkisiz (ADMIN_KEY yanlış).');
  const b = await rpc('admin_seed_prefs', { p_key:ADMIN_KEY, p_rows:prefsRows });

  console.log(`✓ Senkron tamam — aday: ${a}, tercih kaydı: ${b} (toplam ${cands.length} aday).`);
})().catch(e => { console.error('SENKRON HATASI:', e.message); process.exit(1); });
