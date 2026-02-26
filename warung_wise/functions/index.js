const functions = require("firebase-functions");
const { GoogleGenAI } = require("@google/genai");

const ai = new GoogleGenAI({
  apiKey: process.env.GEMINI_API_KEY,
});

exports.askGemini = functions.https.onRequest(async (req, res) => {
  try {
    const prompt = req.body.prompt;

    const response = await ai.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: prompt,
    });

    res.json({ result: response.text });
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

