import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface RequestBody {
  title?: string;
  description?: string;
  tags?: string[];
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { title, description, tags } = (await req.json()) as RequestBody;

    if (!title) {
      return new Response(
        JSON.stringify({ error: "Idea title is required" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 }
      );
    }

    const geminiApiKey = Deno.env.get("GEMINI_API_KEY");

    if (!geminiApiKey) {
      // Deterministic fallback response when GEMINI_API_KEY is not configured
      const fallbackResult = {
        summary: `Idea "${title}" targets feature expansion. Recommend focusing strictly on 1 core flow before adding integrations.`,
        risks: [
          "Potential scope creep from multiple initial feature targets",
          "Unbounded state complexity without early architecture constraints",
        ],
        recommendedMvpCut: "Strip secondary integrations and build 1 single primary screen MVP first.",
      };

      return new Response(
        JSON.stringify(fallbackResult),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
      );
    }

    const prompt = `You are an expert software architect auditing early product ideas for scope risk.
Analyze the following idea:
Title: ${title}
Description: ${description || "None provided"}
Tags: ${tags ? tags.join(", ") : "None"}

Respond strictly with valid JSON conforming to this exact structure:
{
  "summary": "Brief 1-2 sentence complexity summary",
  "risks": ["Risk 1", "Risk 2"],
  "recommendedMvpCut": "Single most impactful recommendation to trim scope for MVP"
}`;

    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${geminiApiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: { responseMimeType: "application/json" },
        }),
      }
    );

    if (!response.ok) {
      throw new Error(`Gemini API error: ${response.statusText}`);
    }

    const data = await response.json();
    const candidateText = data.candidates?.[0]?.content?.parts?.[0]?.text;
    const parsed = JSON.parse(candidateText || "{}");

    return new Response(
      JSON.stringify(parsed),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
    );
  } catch (error) {
    const errMessage = error instanceof Error ? error.message : "Unknown error";
    return new Response(
      JSON.stringify({ error: errMessage }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 500 }
    );
  }
});
