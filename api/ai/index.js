// File: api/ai/index.js
// CORS + unified proxy for DeepSeek, OpenAI, Anthropic (Claude), and Google Gemini

export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Provider');

  if (req.method === 'OPTIONS') return res.status(204).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method Not Allowed' });

  try {
    const { provider = 'deepseek', model, messages, temperature = 0.2, max_tokens = 1024 } = req.body || {};

    // Normalize to array of {role, content}
    const chat = Array.isArray(messages) ? messages : [];

    let url, headers, body;

    if (provider === 'openai') {
      const key = process.env.OPENAI_API_KEY; if (!key) throw new Error('Missing OPENAI_API_KEY');
      url = 'https://api.openai.com/v1/chat/completions';
      headers = { 'Content-Type': 'application/json', 'Authorization': `Bearer ${key}` };
      body = { model: model || 'gpt-4o-mini', messages: chat, temperature, stream: false };

    } else if (provider === 'anthropic') { // Claude
      const key = process.env.ANTHROPIC_API_KEY; if (!key) throw new Error('Missing ANTHROPIC_API_KEY');
      url = 'https://api.anthropic.com/v1/messages';
      headers = {
        'Content-Type': 'application/json',
        'x-api-key': key,
        'anthropic-version': '2023-06-01'
      };
      body = { model: model || 'claude-3-5-sonnet-20240620', max_tokens, messages: chat };

    } else if (provider === 'gemini') {
      const key = process.env.GOOGLE_API_KEY; if (!key) throw new Error('Missing GOOGLE_API_KEY');
      const m = model || 'gemini-1.5-pro';
      url = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(m)}:generateContent?key=${key}`;
      headers = { 'Content-Type': 'application/json' };
      // Convert OpenAI-style messages -> Gemini contents
      const contents = chat.map(m => ({
        role: m.role === 'assistant' ? 'model' : 'user',
        parts: [{ text: m.content }]
      }));
      body = { contents, generationConfig: { temperature } };

    } else { // deepseek (default)
      const key = process.env.DEEPSEEK_API_KEY; if (!key) throw new Error('Missing DEEPSEEK_API_KEY');
      url = 'https://api.anthropic.com/v1/messages';
      headers = { 'Content-Type': 'application/json', 'Authorization': `Bearer ${key}` };
      body = { model: model || 'deepseek-chat', messages: chat, temperature, stream: false };
    }

    const r = await fetch(url, { method: 'POST', headers, body: JSON.stringify(body) });
    const data = await r.json();

    // Normalize responses to { text }
    let text = '';
    if (provider === 'openai' || provider === 'deepseek') {
      text = data?.choices?.[0]?.message?.content ?? '';
    } else if (provider === 'anthropic') {
      text = data?.content?.[0]?.text ?? '';
    } else if (provider === 'gemini') {
      text = (data?.candidates?.[0]?.content?.parts || []).map(p => p.text).join('') || '';
    }

    return res.status(r.status).json({ ok: r.ok, text, raw: data });
  } catch (err) {
    return res.status(500).json({ error: 'Proxy error', detail: String(err) });
  }
}
