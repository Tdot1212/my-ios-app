const cheerio = require('cheerio');

const UA =
  'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile Safari';

async function fetchText(url) {
  const res = await fetch(url, {
    headers: { 'user-agent': UA, 'accept-language': 'en-US,en;q=0.8' },
  });
  if (!res.ok) throw new Error(`HTTP ${res.status} for ${url}`);
  return res.text();
}

function dedupeByTitle(items) {
  const seen = new Set();
  const out = [];
  for (const it of items) {
    const k = (it.title || '').toLowerCase().trim();
    if (!k || seen.has(k)) continue;
    seen.add(k);
    out.push(it);
  }
  return out;
}

/** ---------- Sources (RSS where possible) ---------- */

async function fromHighsnobiety(limit) {
  const xml = await fetchText('https://www.highsnobiety.com/feed');
  const $ = cheerio.load(xml, { xmlMode: true });
  const items = [];
  $('item').each((_, el) => {
    const title = $(el).find('title').first().text().trim();
    const url = $(el).find('link').first().text().trim();
    if (title && url) items.push({ source: 'Highsnobiety', title, url });
  });
  return items.slice(0, limit);
}

async function fromHypebeast(limit) {
  const xml = await fetchText('https://hypebeast.com/feed');
  const $ = cheerio.load(xml, { xmlMode: true });
  const items = [];
  $('item').each((_, el) => {
    const title = $(el).find('title').first().text().trim();
    const url = $(el).find('link').first().text().trim();
    if (title && url) items.push({ source: 'Hypebeast', title, url });
  });
  return items.slice(0, limit);
}

async function fromTMZ(limit) {
  const xml = await fetchText('https://www.tmz.com/rss.xml');
  const $ = cheerio.load(xml, { xmlMode: true });
  const items = [];
  $('item').each((_, el) => {
    const title = $(el).find('title').first().text().trim();
    const url = $(el).find('link').first().text().trim();
    if (title && url) items.push({ source: 'TMZ', title, url });
  });
  return items.slice(0, limit);
}

async function fromHotNewHipHop(limit) {
  const xml = await fetchText('https://www.hotnewhiphop.com/feeds/news.xml');
  const $ = cheerio.load(xml, { xmlMode: true });
  const items = [];
  $('item').each((_, el) => {
    const title = $(el).find('title').first().text().trim();
    const url = $(el).find('link').first().text().trim();
    if (title && url) items.push({ source: 'HotNewHipHop', title, url });
  });
  return items.slice(0, limit);
}

async function fromGoogleTrends(geo = 'US', limit = 12) {
  const url = `https://trends.google.com/trends/trendingsearches/daily/rss?geo=${encodeURIComponent(
    geo
  )}`;
  const xml = await fetchText(url);
  const $ = cheerio.load(xml, { xmlMode: true });
  const items = [];
  $('item').each((_, el) => {
    const title = $(el).find('title').first().text().trim();
    // Some RSS items have multiple links; grab the first
    let link = $(el).find('link').first().text().trim();
    if (!link) link = `https://www.google.com/search?q=${encodeURIComponent(title)}`;
    if (title) items.push({ source: 'GoogleTrends', title, url: link });
  });
  return items.slice(0, limit);
}

/** ---------- Handler ---------- */
module.exports = async (req, res) => {
  try {
    const geo = ((req.query.geo || 'US') + '').toUpperCase();
    const limit = Math.min(Math.max(parseInt(req.query.limit || '12', 10) || 12, 1), 25);

    const results = await Promise.allSettled([
      fromGoogleTrends(geo, limit),
      fromHighsnobiety(limit),
      fromHypebeast(limit),
      fromTMZ(limit),
      fromHotNewHipHop(limit),
    ]);

    let all = [];
    for (const r of results) {
      if (r.status === 'fulfilled') all = all.concat(r.value);
    }
    const items = dedupeByTitle(all).slice(0, limit);

    res.setHeader('Cache-Control', 's-maxage=300, stale-while-revalidate=900');
    res.status(200).json({ items, fetchedAt: new Date().toISOString() });
  } catch (e) {
    res.status(500).json({ error: e.message || 'trends fetch failed' });
  }
};
