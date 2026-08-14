// daily-challenge — GET today's challenge / POST a completion attempt.
// Evidence is aggregated health data from HealthKit / Health Connect, never
// self-reported numbers typed by the user.

import { createClient } from "jsr:@supabase/supabase-js@2";

interface CompletionAttempt {
  // Aggregates the client read from the health platform for today:
  steps?: number;
  active_kcal?: number;
  exercise_minutes?: number;
  longest_workout_minutes?: number;
}

Deno.serve(async (req) => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: req.headers.get("Authorization")! } } },
  );

  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return json({ error: "unauthorized" }, 401);

  // ensure_daily_challenge is deterministic per date — safe to call from any client.
  const { data: challenge, error } = await supabase
    .rpc("ensure_daily_challenge")
    .single();
  if (error || !challenge) return json({ error: "no challenge" }, 500);

  if (req.method === "GET") return json({ challenge });

  // --- POST: attempt completion ----------------------------------------
  const { data: profile } = await supabase
    .from("users").select("id").eq("auth_id", user.id).single();
  if (!profile) return json({ error: "no profile" }, 404);

  const evidence: CompletionAttempt = await req.json();
  const params = challenge.params as {
    metric: string;
    target: number;
    deadline_hour: number | null;
  };

  if (params.deadline_hour !== null &&
      new Date().getUTCHours() >= params.deadline_hour) {
    // NOTE(v1): deadline compared in UTC; per-user timezone lands in Fase 2
    // together with streak timezones.
    return json({ completed: false, reason: "deadline_passed" });
  }

  const value = {
    steps: evidence.steps,
    active_kcal: evidence.active_kcal,
    exercise_minutes: evidence.exercise_minutes,
    workout_any: evidence.longest_workout_minutes,
  }[params.metric];

  if (value === undefined || value < params.target) {
    return json({
      completed: false,
      reason: "target_not_met",
      progress: value ?? 0,
      target: params.target,
    });
  }

  const { data: completion, error: completionError } = await supabase
    .from("challenge_completions")
    .insert({ user_id: profile.id, challenge_id: challenge.id, evidence })
    .select("id").single();
  if (completionError) {
    return json({ completed: true, reason: "already_completed" });
  }

  const { data: config } = await supabase
    .from("block_profiles").select("reward_hours")
    .eq("user_id", profile.id).single();
  const rewardHours = config?.reward_hours ?? 0;
  const expires = rewardHours > 0
    ? new Date(Date.now() + rewardHours * 3600_000)
    : endOfDay();

  await supabase.from("unlocks").insert({
    user_id: profile.id,
    granted_by: "challenge",
    evidence_id: completion.id,
    expires_at: expires.toISOString(),
  });

  return json({ completed: true, expires_at: expires.toISOString() });
});

function endOfDay(): Date {
  const d = new Date();
  d.setHours(23, 59, 0, 0);
  return d;
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
