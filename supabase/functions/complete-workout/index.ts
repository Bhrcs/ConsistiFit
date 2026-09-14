import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
Deno.serve(async (req) => {
  const auth = req.headers.get('Authorization') ?? ''
  const client = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!, { global: { headers: { Authorization: auth } } })
  const { workoutLogId, difficulty } = await req.json()
  const { data, error } = await client.rpc('complete_workout_and_reward', { p_workout_log_id: workoutLogId, p_difficulty: difficulty })
  if (error) return new Response(JSON.stringify({ error: error.message }), { status: 400, headers: { 'content-type': 'application/json' } })
  return new Response(JSON.stringify(data?.[0] ?? null), { headers: { 'content-type': 'application/json' } })
})
