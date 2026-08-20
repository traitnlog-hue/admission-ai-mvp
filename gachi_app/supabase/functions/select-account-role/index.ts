import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

type RequestedRole = 'student' | 'parent' | 'consultant' | 'admin'
const allowedRoles = new Set<RequestedRole>(['student', 'parent', 'consultant', 'admin'])

function response(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

// This function deliberately never grants the consultant or admin role.
// Consultant approval remains an administrator action after private evidence review.
Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (request.method !== 'POST') return response({ error: '허용되지 않은 요청입니다.' }, 405)

  const authorization = request.headers.get('Authorization')
  if (!authorization?.startsWith('Bearer ')) return response({ error: '로그인이 필요합니다.' }, 401)

  const url = Deno.env.get('SUPABASE_URL') ?? ''
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  if (!url || !serviceRoleKey) return response({ error: '서버 역할 설정이 필요합니다.' }, 500)

  const admin = createClient(url, serviceRoleKey, { auth: { persistSession: false } })
  const token = authorization.replace('Bearer ', '')
  const { data: auth, error: authError } = await admin.auth.getUser(token)
  const actor = auth.user
  if (authError || !actor) return response({ error: '세션을 확인할 수 없습니다.' }, 401)

  const body = await request.json().catch(() => null) as { role?: RequestedRole } | null
  const role = body?.role
  if (!role || !allowedRoles.has(role)) return response({ error: '역할 선택이 올바르지 않습니다.' }, 400)

  const appMetadata = actor.app_metadata ?? {}
  const userMetadata = actor.user_metadata ?? {}
  const currentRole = appMetadata.gachi_role ?? 'student'

  if (role === 'admin') {
    if (currentRole !== 'admin') return response({ error: '관리자 계정으로 승인된 사용자만 선택할 수 있습니다.' }, 403)
    return response({ role: 'admin', status: 'active' })
  }

  if (role === 'consultant') {
    const { error } = await admin.auth.admin.updateUserById(actor.id, {
      user_metadata: { ...userMetadata, requested_account_type: 'consultant' },
    })
    if (error) return response({ error: '컨설턴트 등록 상태를 저장하지 못했습니다.' }, 500)
    return response({
      role: currentRole === 'consultant' ? 'consultant' : 'student',
      status: currentRole === 'consultant' ? 'active' : 'verification_required',
    })
  }

  // 학생·학부모는 가입 목적에 맞춘 기본 화면 역할이며, 관리자 권한과 무관합니다.
  const { error } = await admin.auth.admin.updateUserById(actor.id, {
    app_metadata: { ...appMetadata, gachi_role: role },
    user_metadata: { ...userMetadata, requested_account_type: role },
  })
  if (error) return response({ error: '역할을 저장하지 못했습니다.' }, 500)
  return response({ role, status: 'active' })
})
