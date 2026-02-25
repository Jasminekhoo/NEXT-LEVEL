/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");
const logger = require("firebase-functions/logger");

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({ maxInstances: 10 });

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const vision = require("@google-cloud/vision");
const fetch = require("node-fetch");

admin.initializeApp();

const visionClient = new vision.ImageAnnotatorClient();

// ⚠️ Set your Gemini key using firebase config
const GEMINI_API_KEY = functions.config().gemini.key;

exports.analyzeReceipt = functions.https.onCall(async (data, context) => {
  try {
    const base64 = data.imageBase64;
    if (!base64) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing imageBase64"
      );
    }

    // 1️⃣ OCR using Cloud Vision
    const [result] = await visionClient.textDetection({
      image: { content: base64 },
    });

    const ocrText =
      result.fullTextAnnotation?.text ||
      result.textAnnotations?.[0]?.description ||
      "";

    if (!ocrText.trim()) {
      return { items: [], rawText: "" };
    }

    // 2️⃣ Gemini structuring
    const prompt = `
Extract purchase line items from this Malaysian receipt OCR text.

Return ONLY valid JSON:
{
  "items": [
    { "name": string, "price": number }
  ]
}

Rules:
- price must be number only (12.5 not "RM12.50")
- ignore totals, tax, change
- merge quantity into name if present
- remove duplicates

OCR TEXT:
"""${ocrText}"""
`;

    const geminiUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=" +
      GEMINI_API_KEY;

    const geminiRes = await fetch(geminiUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: {
          temperature: 0.2,
        },
      }),
    });

    const geminiJson = await geminiRes.json();

    const textOut =
      geminiJson?.candidates?.[0]?.content?.parts?.[0]?.text || "";

    const cleaned = textOut
      .replace(/^```json/i, "")
      .replace(/^```/, "")
      .replace(/```$/, "")
      .trim();

    let parsed;
    try {
      parsed = JSON.parse(cleaned);
    } catch (e) {
      parsed = { items: [] };
    }

    const items = Array.isArray(parsed.items) ? parsed.items : [];

    return {
      items: items
        .filter((x) => x.name && x.price)
        .map((x) => ({
          name: String(x.name),
          price: Number(x.price),
        })),
      rawText: ocrText,
    };
  } catch (err) {
    console.error(err);
    throw new functions.https.HttpsError("internal", err.message);
  }
});