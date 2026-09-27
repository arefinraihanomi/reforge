import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface RequestBody {
  ancestorTitle?: string;
  abandonReason?: string;
  selectedLessons?: string[];
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { ancestorTitle, abandonReason, selectedLessons } = (await req.json()) as RequestBody;

    const geminiApiKey = Deno.env.get("GEMINI_API_KEY");

    if (!geminiApiKey) {
      // Fallback strategy when API key is missing
      const fallbackResult = {
        suggestedV2Title: `${ancestorTitle || "Project"} v2`,
        tighterMvpScope: `Focus strictly on 1 primary screen and local-first state before adding external network synchronization.`,
        simplifications: [
          "Eliminate secondary configuration options in initial launch.",
          "Use direct Supabase queries with Riverpod without custom caching layers.",
          "Limit MVP scope to 3 core user tasks.",
        ],
        recommendedTasks: [
          "Initialize tight V2 layout container",
          "Hook core Riverpod provider directly to PostgreSQL table",
          "Verify end-to-end task checklist flow",
        ],
      };

      return new Response(
        JSON.stringify(fallbackResult),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
      );
    }

    const lessonsText = selectedLessons?.length
      ? selectedLessons.map((l) => `- ${l}`).join("\n")
      : "No historical lessons selected.";

    const prompt = `You are a software architect helping resurrect an abandoned V1 project into a focused, high-probability V2 project.

Ancestor V1 Title: ${ancestorTitle || "Untitled V1"}
Ancestor Abandonment Reason: ${abandonReason || "Scope creep / blocker"}
Carried Lessons from V1:
${lessonsText}

Provide 3 concrete architectural simplification strategies to ensure V2 succeeds where V1 stopped.

Respond strictly with valid JSON conforming to this exact structure:
{
  "suggestedV2Title": "${ancestorTitle || "Project"} v2",
  "tighterMvpScope": "Single clear MVP boundary description for V2",
  "simplifications": ["Strategy 1", "Strategy 2", "Strategy 3"],
  "recommendedTasks": ["Task 1", "Task 2"]
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
