import { createClient } from 'npm:@supabase/supabase-js@2.116.0'

const corsHeaders = {
  'access-control-allow-origin': '*',
  'access-control-allow-headers': 'authorization, x-client-info, apikey, content-type',
  'access-control-allow-methods': 'POST, OPTIONS',
  'content-type': 'application/json',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'method not allowed' }), { status: 405, headers: corsHeaders })
  }

  const auth = req.headers.get('Authorization') ?? ''
  if (!auth.startsWith('Bearer ')) {
    return new Response(JSON.stringify({ error: 'missing authorization' }), { status: 401, headers: corsHeaders })
  }

  const url = Deno.env.get('SUPABASE_URL')
  const publishableKey = Deno.env.get('SUPABASE_PUBLISHABLE_KEY') ?? Deno.env.get('SUPABASE_ANON_KEY')
  if (!url || !publishableKey) {
    return new Response(JSON.stringify({ error: 'server configuration missing' }), { status: 500, headers: corsHeaders })
  }

  const client = createClient(url, publishableKey, {
    global: { headers: { Authorization: auth } },
    auth: { persistSession: false },
  })

  let body: { workoutLogId?: string; difficulty?: string }
  try {
    body = await req.json()
  } catch {
    return new Response(JSON.stringify({ error: 'invalid JSON' }), { status: 400, headers: corsHeaders })
  }

  if (!body.workoutLogId || !body.difficulty) {
    return new Response(JSON.stringify({ error: 'workoutLogId and difficulty are required' }), { status: 400, headers: corsHeaders })
  }

  const { data, error } = await client.rpc('complete_workout_and_reward', {
    p_workout_log_id: body.workoutLogId,
    p_difficulty: body.difficulty,
  })

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 400, headers: corsHeaders })
  }
  return new Response(JSON.stringify(data?.[0] ?? null), { status: 200, headers: corsHeaders })
})
