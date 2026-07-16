import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
  throw new Error('Missing required environment variables');
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, apikey',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get('Authorization') || '';
    const token = authHeader.replace(/^Bearer\s+/i, '');
    if (!token) {
      return new Response(JSON.stringify({ error: 'Authentication required' }), { status: 401, headers: corsHeaders });
    }

    const { data: { user: adminUser }, error: authError } = await supabase.auth.getUser(token);
    if (authError || !adminUser) {
      return new Response(JSON.stringify({ error: 'Invalid or expired token' }), { status: 401, headers: corsHeaders });
    }

    const { data: adminProfile } = await supabase
      .from('profiles')
      .select('role, gym_id')
      .eq('id', adminUser.id)
      .single();

    if (!adminProfile || !['owner', 'admin', 'superadmin'].includes(adminProfile.role)) {
      return new Response(JSON.stringify({ error: 'Only owners, admins, or superadmins can add staff' }), { status: 403, headers: corsHeaders });
    }

    const body = await req.json();
    const { name, email, password, phone, role, gym_id, is_active, avatar_url } = body;

    if (!email || !password || !name || !role) {
      return new Response(JSON.stringify({ error: 'name, email, password, and role are required' }), { status: 400, headers: corsHeaders });
    }

    const targetGymId = gym_id || (adminProfile.role !== 'superadmin' ? adminProfile.gym_id : null);
    if (!targetGymId) {
      return new Response(JSON.stringify({ error: 'gym_id is required for non-superadmin' }), { status: 400, headers: corsHeaders });
    }

    if (adminProfile.role !== 'superadmin' && targetGymId !== adminProfile.gym_id) {
      return new Response(JSON.stringify({ error: 'Cannot add staff to a different gym' }), { status: 403, headers: corsHeaders });
    }

    const { data: authData, error: createError } = await supabase.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { name, role },
    });

    if (createError) {
      const msg = createError.message.toLowerCase();
      if (msg.includes('already registered') || msg.includes('already exists')) {
        return new Response(JSON.stringify({ error: 'Email already registered' }), { status: 409, headers: corsHeaders });
      }
      return new Response(JSON.stringify({ error: createError.message }), { status: 500, headers: corsHeaders });
    }

    const userId = authData.user!.id;
    const safeRole = role === 'superadmin' ? 'staff' : role;

    const { data: profile, error: updateError } = await supabase
      .from('profiles')
      .update({
        name,
        phone: phone || null,
        role: safeRole,
        gym_id: targetGymId,
        is_active: is_active ?? true,
        avatar_url: avatar_url || null,
      })
      .eq('id', userId)
      .select()
      .single();

    if (updateError) {
      return new Response(JSON.stringify({ error: 'Failed to update profile' }), { status: 500, headers: corsHeaders });
    }

    return new Response(JSON.stringify({ success: true, staff: profile }), { status: 200, headers: corsHeaders });
  } catch (e) {
    console.error('create-staff error:', e);
    return new Response(JSON.stringify({ error: e instanceof Error ? e.message : 'Internal server error' }), { status: 500, headers: corsHeaders });
  }
});
