// validate-unlock — server-side unlock validation (PLAN.md §5.3).
// The client submits evidence (gym session or workout); this function applies
// the anti-cheat rules and, if valid, inserts an `unlocks` row. Clients enforce
// shields locally and reconcile with this record when online.

import { createClient } from "jsr:@supabase/supabase-js@2";

interface UnlockRequest {
  source: "gym" | "activity" | "challenge";
  gym_session?: {
    gym_id: string;
    entered_at: string;
    exited_at: string;
    verified_minutes: number;
  };
  workout?: {
    source: string;
    type: string;
    started_at: string;
    minutes: number;
    active_kcal?: number;
    avg_hr?: number;
    external_ref: string;
  };
}

Deno.serve(async (req) => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: req.headers.get("Authorization")! } } },
  );

  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return json({ error: "unauthorized" }, 401);

  const { data: profile } = await supabase
    .from("users").select("id").eq("auth_id", user.id).single();
  if (!profile) return json({ error: "no profile" }, 404);

  const body: UnlockRequest = await req.json();
  const { data: config } = await supabase
    .from("block_profiles")
    .select("goal_minutes, reward_hours")
    .eq("user_id", profile.id).single();
  const goal = config?.goal_minutes ?? 45;

  // --- Validation rules (anti-cheat v1) ---------------------------------
  let valid = false;
  let evidenceId: string | null = null;

  if (body.source === "gym" && body.gym_session) {
    const s = body.gym_session;
    const wallClock =
      (Date.parse(s.exited_at) - Date.parse(s.entered_at)) / 60000;
    // verified minutes can't exceed wall-clock time; session must be recent
    valid = s.verified_minutes >= goal &&
      s.verified_minutes <= wallClock + 1 &&
      Date.now() - Date.parse(s.exited_at) < 3 * 3600_000;
    if (valid) {
      const { data } = await supabase.from("gym_sessions").insert({
        user_id: profile.id, gym_id: s.gym_id,
        entered_at: s.entered_at, exited_at: s.exited_at,
        verified_minutes: s.verified_minutes, status: "completed",
      }).select("id").single();
      evidenceId = data?.id ?? null;
    }
  } else if (body.source === "activity" && body.workout) {
    const w = body.workout;
    // External activities always require device-recorded workouts (§3.5);
    // external_ref dedupes so one workout can't unlock twice.
    valid = w.minutes >= goal &&
      Date.now() - Date.parse(w.started_at) < 6 * 3600_000;
    if (valid) {
      const { data, error } = await supabase.from("workouts").insert({
        user_id: profile.id, ...w,
      }).select("id").single();
      if (error) valid = false; // duplicate external_ref → already used
      evidenceId = data?.id ?? null;
    }
  }

  if (!valid) return json({ granted: false }, 200);

  const rewardHours = config?.reward_hours ?? 0;
  const expires = rewardHours > 0
    ? new Date(Date.now() + rewardHours * 3600_000)
    : endOfDay();

  await supabase.from("unlocks").insert({
    user_id: profile.id,
    granted_by: body.source,
    evidence_id: evidenceId,
    expires_at: expires.toISOString(),
  });

  return json({ granted: true, expires_at: expires.toISOString() });
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
