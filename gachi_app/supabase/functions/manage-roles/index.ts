import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const allowedRoles = new Set(['student', 'parent', 'consultant', 'admin'])

function response(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  const authorization = request.headers.get('Authorization')
  if (!authorization?.startsWith('Bearer ')) {
    return response({ error: '로그인이 필요합니다.' }, 401)
  }

  const url = Deno.env.get('SUPABASE_URL') ?? ''
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  if (!url || !serviceRoleKey) {
    return response({ error: '서버 역할 관리 설정이 완료되지 않았습니다.' }, 500)
  }

  const admin = createClient(url, serviceRoleKey, { auth: { persistSession: false } })
  const token = authorization.replace('Bearer ', '')
  const { data: auth, error: authError } = await admin.auth.getUser(token)
  const actor = auth.user
  if (authError || !actor) return response({ error: '세션을 확인할 수 없습니다.' }, 401)
  if (actor.app_metadata?.gachi_role !== 'admin') {
    return response({ error: '관리자 권한이 필요합니다.' }, 403)
  }

  if (request.method === 'GET') {
    const { data, error } = await admin.auth.admin.listUsers({ page: 1, perPage: 200 })
    if (error) return response({ error: '사용자 목록을 불러오지 못했습니다.' }, 500)
    return response({
      users: data.users.map((user) => ({
        id: user.id,
        email: user.email ?? '',
        name: user.user_metadata?.full_name ?? user.email?.split('@')[0] ?? '이름 없음',
        role: user.app_metadata?.gachi_role ?? 'student',
      })),
    })
  }

  if (request.method !== 'POST') return response({ error: '허용되지 않은 요청입니다.' }, 405)

  const body = await request.json().catch(() => null) as { userId?: string; role?: string } | null
  const userId = body?.userId?.trim()
  const role = body?.role?.trim()
  if (!userId || !role || !allowedRoles.has(role)) {
    return response({ error: '역할 변경 요청이 올바르지 않습니다.' }, 400)
  }
  if (actor.id === userId && role !== 'admin') {
    return response({ error: '현재 관리자 계정의 관리자 권한은 이 화면에서 해제할 수 없습니다.' }, 400)
  }

  const { data: targetData, error: targetError } = await admin.auth.admin.getUserById(userId)
  if (targetError || !targetData.user) return response({ error: '대상 계정을 찾을 수 없습니다.' }, 404)
  const target = targetData.user
  const previousRole = target.app_metadata?.gachi_role ?? 'student'

  const { error: updateError } = await admin.auth.admin.updateUserById(userId, {
    app_metadata: { ...target.app_metadata, gachi_role: role },
  })
  if (updateError) return response({ error: '역할을 변경하지 못했습니다.' }, 500)

  await admin.from('role_change_log').insert({
    actor_user_id: actor.id,
    target_user_id: userId,
    from_role: previousRole,
    to_role: role,
  })

  return response({ ok: true, role })
})
