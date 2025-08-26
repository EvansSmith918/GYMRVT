import express from "express";
import cors from "cors";
import multer from "multer";
import fs from "fs";
import OpenAI from "openai";
import 'dotenv/config';

const app = express();
const upload = multer({ dest: "uploads/", limits: { fileSize: 8 * 1024 * 1024 } }); // 8 MB
const port = process.env.PORT || 3000;

app.use(cors()); // allow requests from your Flutter app
app.use(express.json());

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

app.get("/health", (_, res) => res.json({ ok: true }));

/**
 * POST /analyze
 * multipart/form-data with field "image"
 * Returns: { summary: string, focus: string[], caution: string[] }
 */
app.post("/analyze", upload.single("image"), async (req, res) => {
  let base64;

  try {
    // Case A: multipart/form-data (file field = "image")
    if (req.file) {
      base64 = fs.readFileSync(req.file.path, { encoding: "base64" });
    }

    // Case B: JSON { "image": "<base64>" }
    if (!base64 && req.is("application/json") && req.body?.image) {
      base64 = req.body.image.trim();
      // Strip data URL prefix if present
      const comma = base64.indexOf(",");
      if (comma !== -1) base64 = base64.slice(comma + 1);
    }

    if (!base64) {
      return res.status(400).json({ error: "No image provided (multipart or JSON Base64)." });
    }

    const prompt = `
You are a fitness advisor AI. Analyze the user's physique from the image and
return STRICT JSON with these keys only:
{
  "summary": "1-2 sentence overview of workout balance this week",
  "focus": ["underworked-muscle", "..."],
  "caution": ["possibly-fatigued/overused note ...", "..."]
}
No markdown. Only JSON.
`;

    const resp = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: "You are an expert fitness coach." },
        {
          role: "user",
          content: [
            { type: "text", text: prompt },
            { type: "image_url", image_url: { url: `data:image/jpeg;base64,${base64}` } }
          ]
        }
      ],
      temperature: 0.2
    });

    let json;
    try {
      json = JSON.parse(resp.choices[0].message.content);
    } catch {
      json = { summary: resp.choices[0].message.content, focus: [], caution: [] };
    }

    return res.json({
      summary: json.summary ?? "Analysis complete.",
      focus: Array.isArray(json.focus) ? json.focus : [],
      caution: Array.isArray(json.caution) ? json.caution : []
    });

  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: "Failed to analyze image." });
  } finally {
    if (req.file && fs.existsSync(req.file.path)) fs.unlinkSync(req.file.path);
  }
  app.use((err, req, res, next) => {
  if (err && err.code === "LIMIT_FILE_SIZE") {
    return res.status(413).json({ error: "Image too large. Try a smaller photo." });
  }
  next(err);
});
});
app.listen(port, () => console.log(`AI server running on http://localhost:${port}`));
