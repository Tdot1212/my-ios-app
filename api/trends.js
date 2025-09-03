const VERSION = 'prod-no-deps-1';
const UA = 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile Safari';

async function fetchText(url) {
  const r = await fetch(url, { headers: { 'user-agent': UA, 'accept-language': 'en-US,en;q=0.8' } });
  if (!r.ok) throw new Error(`HTTP ${r.status}`);
  return r.text();
}
function cdata(s){ return s.replace(/^<!\[CDATA\[(.*?)\]\]>$/s,'$1'); }
function parseRSS(xml, source, limit) {
  const items = xml.match(/<item\b[\s\S]*?<\/item>/gi) || [];
  const out = [];
  for (const block of items) {
    const t = cdata((block.match(/<title\b[^>]*>([\s\S]*?)<\/title>/i)?.[1] || '')).trim();
    const lraw = cdata((block.match(/<link\b[^>]*>([\s\S]*?)<\/link>/i)?.[1] || '')).trim();
    const url = lraw || (t ? `https://www.google.com/search?q=${encodeURIComponent(t)}` : '');
    if (t) out.push({ source, title: t, url });
    if (out.length >= limit) break;
  }
  return out;
}
function dedupeByTitle(arr){
  const seen=new Set(), out=[];
  for(const it of arr){ const k=(it.title||'').toLowerCase().trim(); if(!k||seen.has(k)) continue; seen.add(k); out.push(it); }
  return out;
}
async function fromFeed(url, source, limit){ return parseRSS(await fetchText(url), source, limit); }
async function fromGoogleTrends(geo, limit){
  const url=`https://trends.google.com/trends/trendingsearches/daily/rss?geo=${encodeURIComponent(geo)}`;
  return parseRSS(await fetchText(url),'GoogleTrends',limit);
}
module.exports = async (req,res)=>{
  try{
    const geo=((req.query.geo||'US')+'').toUpperCase();
    const limit=Math.min(Math.max(parseInt(req.query.limit||'10',10)||10,1),25);
    const rs=await Promise.allSettled([
      fromGoogleTrends(geo,limit),
      fromFeed('https://www.highsnobiety.com/feed','Highsnobiety',limit),
      fromFeed('https://www.hypebeast.com/feed','Hypebeast',limit),
      fromFeed('https://www.tmz.com/rss.xml','TMZ',limit),
      fromFeed('https://www.hotnewhiphop.com/feeds/news.xml','HotNewHipHop',limit),
    ]);
    let all=[]; for(const r of rs) if(r.status==='fulfilled') all=all.concat(r.value);
    const items=dedupeByTitle(all).slice(0,limit);
    res.setHeader('Cache-Control','s-maxage=300, stale-while-revalidate=900');
    res.status(200).json({ version: VERSION, items, fetchedAt: new Date().toISOString() });
  }catch(e){
    res.status(500).json({ version: 'prod-no-deps-1', error: e.message });
  }
};
