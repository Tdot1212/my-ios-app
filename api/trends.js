// api/trends.js
import * as cheerio from 'cheerio';
import { fetch } from 'undici';

const UA =
  'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile Safari';

const ok = (s) => (s || '').replace(/\s+/g, ' ').trim();
const withUA = (url) =>
  fetch(url, { headers: { 'user-agent': UA, 'accept-language': 'en-US,en;q=0.8' } });

function uniqueByTitle(arr) {
  const seen = new Set();
  const out = [];
  for (const x of arr) {
    const k = (x.title || '').toLowerCase();
    if (k && !seen.has(k)) {
      seen.add(k);
      out.push(x);
    }
  }
  return out;
}

async function scrapeHighsnobiety(limit) {
  const r = await withUA('https://www.highsnobiety.com/page/1/');
  const $ = cheerio.load(await r.text());
  const items = [];
  $('article a').each((_, el) => {
    const href = $(el).attr('href');
    const t = ok($(el).text());
    if (href && t && t.length > 6) {
      items.push({
        source: 'highsnobiety',
        title: t,
        url: new URL(href, 'https://www.highsnobiety.com').href,
      });
    }
  });
  return uniqueByTitle(items).slice(0, limit);
}

async function scrapeHypebeast(limit) {
  const r = await withUA('https://hypebeast.com/');
  const $ = cheerio.load(await r.text());
  const items = [];
  $('article a').each((_, el) => {
    const href = $(el).attr('href');
    const t = ok($(el).text());
    if (href && t && t.length > 6) {
      items.push({
        source: 'hypebeast',
        title: t,
        url: new URL(href, 'https://hypebeast.com').href,
      });
    }
  });
  return uniqueByTitle(items).slice(0, limit);
}

async function scrapeTMZ(limit) {
  const r = await withUA('https://www.tmz.com/');
  const $ = cheerio.load(await r.text());
  const items = [];
  $('article a, .content-list a').each((_, el) => {
    const href = $(el).attr('href');
    const t = ok($(el).text());
    if (href && t && t.length > 6) {
      items.push({ source: 'tmz', title: t, url: new URL(href, 'https://www.tmz.com').href });
    }
  });
  return uniqueByTitle(items).slice(0, limit);
}

async function scrapeHotNewHipHop(limit) {
  const r = await withUA('https://www.hotnewhiphop.com/articles/news');
  const $ = cheerio.load(await r.text());
  const items = [];
  $('article a').each((_, el) => {
    const href = $(el).attr('href');
    const t = ok($(el).text());
    if (href && t && t.length > 6) {
      items.push({
        source: 'hotnewhiphop',
        title: t,
        url: new URL(href, 'https://www.hotnewhiphop.com').href,
      });
    }
  });
  return uniqueByTitle(items).slice(0, limit);
}

// Google Trends via RSS (works server-side)
async function fetchGoogleTrendsRSS(geo = 'US', limit = 12) {
  const urls = [
    `https://trends.google.com/trends/trendingsearches/daily/rss?geo=${geo}`,
    `https://trends.google.com/trends/trendingsearches/daily/rss?geo=${geo}&ns=1`,
  ];
  const items = [];
  for (const u of urls) {
    const r = await withUA(u);
    const xml = await r.text();
    const $ = cheerio.load(xml, { xmlMode: true });
    $('item').each((_, el) => {
      const title = ok($(el).find('title').text());
      const link = ok($(el).find('link').first().text());
      if (title) {
        items.push({
          source: 'google-trends',
          title,
          url: link || `https://www.google.com/search?q=${encodeURIComponent(title)}`,
        });
      }
    });
  }
  return uniqueByTitle(items).slice(0, limit);
}

export default async function handler(req, res) {
  try {
    const geo = (req.query.geo || 'US').toString().toUpperCase();
    const limit = Math.min(parseInt(req.query.limit || '12', 10), 25);

    const [hs, hb, tmz, hnhh, gt] = await Promise.all([
      scrapeHighsnobiety(limit),
      scrapeHypebeast(limit),
      scrapeTMZ(limit),
      scrapeHotNewHipHop(limit),
      fetchGoogleTrendsRSS(geo, limit),
    ]);

    const data = [...gt, ...hs, ...hb, ...tmz, ...hnhh];
    res.setHeader('Cache-Control', 's-maxage=300, stale-while-revalidate=900');
    res.status(200).json({ items: data, fetchedAt: new Date().toISOString() });
  } catch (e) {
    res.status(500).json({ error: e.message || 'scrape failed' });
  }
}
