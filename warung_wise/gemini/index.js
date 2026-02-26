const { onRequest } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const { defineSecret } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const { GoogleGenAI } = require("@google/genai");

// optional: set defaults
setGlobalOptions({ maxInstances: 10, region: "asia-southeast1" });

// ✅ Secret (stored via firebase functions:secrets:set)
const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");

// Simple CORS (enough for Flutter + web)
function setCors(res) {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST,OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");
}

// ✅ POST { prompt: "..." } -> { result: "..." }
exports.askGemini = onRequest(
  { secrets: [GEMINI_API_KEY] },
  async (req, res) => {
    setCors(res);
    if (req.method === "OPTIONS") return res.status(204).send("");
    if (req.method !== "POST") return res.status(405).send("Use POST");

    try {
      const prompt = req.body?.prompt;
      if (!prompt) return res.status(400).json({ error: "Missing prompt" });

      const ai = new GoogleGenAI({ apiKey: GEMINI_API_KEY.value() });

      const response = await ai.models.generateContent({
        model: 'gemini-2.5-flash',
        contents: prompt,
      });

      return res.json({ result: response.text });
    } catch (e) {
      logger.error(e);
      return res.status(500).json({ error: String(e) });
    }
  }
);