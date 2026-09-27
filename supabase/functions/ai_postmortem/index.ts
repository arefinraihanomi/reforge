import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface DecisionPayload {
  type?: string;
  summary?: string;
  rationale?: string;
}

interface RequestBody {
  title?: string;
  mvpScope?: string;
  abandonReason?: string;
  abandonNote?: string;
  decisions?: DecisionPayload[];
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { title, mvpScope, abandonReason, abandonNote, decisions } = (await req.json()) as RequestBody;

    const geminiApiKey = Deno.env.get("GEMINI_API_KEY");

    if (!geminiApiKey) {
      // Fallback draft when API key is missing
      const fallbackResult = {
        whatWentWrong: `Project "${title || "Build"}" hit roadblocks due to ${abandonReason || "scope creep"}. Execution notes: ${abandonNote || "Scope boundary expanded past initial limits"}.`,
        whatWentWell: "Core database models and preliminary UI setup were completed successfully.",
        suggestedLessons: [
          {
            lesson: "Strictly enforce single-feature MVP scope boundary before expanding functionality.",
            category: "scope",
          },
          {
            lesson: "Decouple backend data access from UI view models to prevent tight coupling.",
            category: "architecture",
          },
        ],
      };

      return new Response(
        JSON.stringify(fallbackResult),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
      );
    }

    const decisionListText = decisions?.length
      ? decisions.map((d) => `- [${d.type || "note"}] ${d.summary}: ${d.rationale || ""}`).join("\n")
      : "No decisions recorded.";

    const prompt = `You are a pragmatic engineering post-mortem facilitator.
Summarize the following abandoned software project history into actionable learnings:

Project Title: ${title || "Untitled"}
MVP Scope: ${mvpScope || "Not specified"}
Abandonment Reason: ${abandonReason || "Unknown"}
Abandonment Note: ${abandonNote || "None"}
Log Decisions & Blockers:
${decisionListText}

Respond strictly with valid JSON conforming to this exact structure:
{
  "whatWentWrong": "Clear 2-3 sentence analysis of root causes",
  "whatWentWell": "Key technical achievements or good patterns built",
  "suggestedLessons": [
    { "lesson": "Concrete reusable takeaway", "category": "architecture" },
    { "lesson": "Concrete scope management takeaway", "category": "scope" }
  ]
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
