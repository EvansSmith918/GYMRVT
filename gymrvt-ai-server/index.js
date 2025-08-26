import express from "express";
import cors from "cors";
import multer from "multer";
import fs from "fs";
import OpenAI from "openai";

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
  if (!req.file) return res.status(400).json({ error: "No image uploaded." });

  const path = req.file.path;
  try {
    // Read image and base64 encode
    const base64 = fs.readFileSync(path, { encoding: "base64" });

    // Ask the model to return STRICT JSON so Flutter can parse it easily
    const prompt = `
You are a fitness advisor AI. Analyze the user's physique from the image and
return STRICT JSON with these keys only:
{
  "summary": "1-2 sentence overview of workout balance this week",
  "focus": ["underworked-muscle", "..."],
  "caution": ["possibly-fatigued/overused note ...", "..."]
}
Keep it concise, no markdown or extra text outside JSON.
`;

    const resp = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: "You are an expert fitness coach." },
        {
          role: "user",
          content: [
            { type: "text", text: prompt },
            {
              type: "image_url",
              image_url: { url: `data:image/jpeg;base64,${base64}` }
            }
          ]
        }
      ],
      temperature: 0.2
    });

    let json;
    try {
      json = JSON.parse(resp.choices[0].message.content);
    } catch {
      // fallback: return all text inside 'summary'
      json = { summary: resp.choices[0].message.content, focus: [], caution: [] };
    }

    res.json({
      summary: json.summary ?? "Analysis complete.",
      focus: Array.isArray(json.focus) ? json.focus : [],
      caution: Array.isArray(json.caution) ? json.caution : []
    });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: "Failed to analyze image." });
  } finally {
    fs.existsSync(path) && fs.unlinkSync(path); // cleanup temp file
  }
});

app.listen(port, () => console.log(`AI server running on http://localhost:${port}`));
