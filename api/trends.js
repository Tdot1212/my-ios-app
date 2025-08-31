const cheerio = require("cheerio");

// Small helpers
const uniqByTitle = (arr) => {
  const seen = new Set();
  return arr.filter((it) => {
    const key = (it.title || "").toLowerCase().trim();
    if (!key || seen.has(key)) return false;
    seen.add(key);
    return true;
  });
};

async function getHTML(url) {
  const ctl = new AbortController();
  const t = setTimeout(() => ctl.abort(), 10000);
  try {
    const res = await fetch(url, { signal: ctl.signal, headers: { "user-agent": "Mozilla/5.0 OrbitPlannerBot" }});
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return await res.text();
  } finally {
    clearTimeout(t);
  }
}

/** HIGH SNOBIETY */
async function fromHighsnobiety() {
  const html = await getHTML("https://www.highsnobiety.com/page/1/");
  const $ = cheerio.load(html);
  const items = [];
  $("a").each((_, a) => {
    const title = $(a).text().trim().replace(/\s+/g, " ");
    const url = $(a).attr("href");
    if (!url || !/^https?:/.test(url)) return;
    if (title.length < 20 || title.length > 140) return;
    if (url.includes("#") || /\/tag\//.test(url)) return;
    items.push({ source: "Highsnobiety", title, url });
  });
  return uniqByTitle(items).slice(0, 10);
}

/** HYPEBEAST */
async function fromHypebeast() {
  const html = await getHTML("https://hypebeast.com/");
  const $ = cheerio.load(html);
  const items = [];
  $("a").each((_, a) => {
    const title = $(a).attr("title")?.trim() || $(a).text().trim();
    const url = $(a).attr("href");
    if (!url || !/^https?:/.test(url)) return;
    if (!title || title.length < 20 || title.length > 140) return;
    if (url.includes("#") || /\/tag\//.test(url)) return;
    items.push({ source: "Hypebeast", title, url });
  });
  return uniqByTitle(items).slice(0, 10);
}

/** TMZ */
async function fromTMZ() {
  const html = await getHTML("https://www.tmz.com/");
  const $ = cheerio.load(html);
  const items = [];
  $("a").each((_, a) => {
    const title = $(a).text().trim();
    const url = $(a).attr("href");
    if (!url || !/^https?:/.test(url) || !title) return;
    if (title.length < 15 || title.length > 140) return;
    items.push({ source: "TMZ", title, url });
  });
  return uniqByTitle(items).slice(0, 10);
}

/** HotNewHipHop – news list */
async function fromHNH() {
  const html = await getHTML("https://www.hotnewhiphop.com/articles/news");
  const $ = cheerio.load(html);
  const items = [];
  $("a").each((_, a) => {
    const title = $(a).text().trim();
    const url = $(a).attr("href");
    if (!url || !/^https?:/.test(url) || !title) return;
    if (title.length < 15 || title.length > 140) return;
    items.push({ source: "HotNewHipHop", title, url });
  });
  return uniqByTitle(items).slice(0, 10);
}

/** Google Trends – best-effort scrape of the page you gave */
async function fromGoogleTrends(geo = "US") {
  const html = await getHTML(`https://trends.google.com/trending?geo=${encodeURIComponent(geo)}&hours=48`);
  const $ = cheerio.load(html);
  const items = [];
  // grab obvious anchors & headings
  $("a, h2, h3").each((_, el) => {
    const title = $(el).text().trim();
    const url = $(el).attr("href");
    if (!title || title.length < 3 || title.length > 80) return;
    if (url && /^https?:/.test(url)) {
      items.push({ source: "Google Trends", title, url });
    } else {
      items.push({ source: "Google Trends", title, url: `https://trends.google.com/trending?geo=${geo}` });
    }
  });
  return uniqByTitle(items).slice(0, 10);
}

const SOURCES = {
  hs: fromHighsnobiety,
  hypebeast: fromHypebeast,
  tmz: fromTMZ,
  hnhh: fromHNH,
  google: fromGoogleTrends,
};

module.exports = async (req, res) => {
  try {
    const { geo = "US", limit = "10", src = "hs,hypebeast,tmz,hnhh" } = req.query;
    const which = src.split(",").map((s) => s.trim()).filter(Boolean);

    const lists = await Promise.allSettled(
      which.map((key) => (SOURCES[key] ? SOURCES[key](geo) : Promise.resolve([])))
    );

    let items = [];
    for (const r of lists) {
      if (r.status === "fulfilled") items = items.concat(r.value);
    }
    items = uniqByTitle(items).slice(0, Math.max(1, Math.min(50, parseInt(limit, 10) || 10)));

    res.setHeader("Cache-Control", "s-maxage=300, stale-while-revalidate=3600");
    res.status(200).json({ items, fetchedAt: new Date().toISOString() });
  } catch (err) {
    res.status(500).json({ error: String(err?.message || err) });
  }
};
