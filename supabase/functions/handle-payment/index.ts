import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const RAZORPAY_KEY_ID = Deno.env.get('RAZORPAY_KEY_ID')!;
const RAZORPAY_KEY_SECRET = Deno.env.get('RAZORPAY_KEY_SECRET')!;

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

const PLAN_PRICES: Record<string, number> = {
  free: 0,
  trial: 1,
  pro: 499,
  enterprise: 999,
};

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, apikey',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  const url = new URL(req.url);
  const path = url.pathname.replace(/\/$/, '');
  const bodyAction = await req.clone().json().then((b) => b.action).catch(() => '');
  const action = url.searchParams.get('action') || bodyAction;

  try {
    let res: Response;

    if (path.endsWith('/create-order') || path.endsWith('/create-payment-link') || action === 'create-order' || action === 'create-payment-link') {
      res = await handleCreateOrder(req);
    } else if (path.endsWith('/payment-callback')) {
      res = await handlePaymentCallback(url);
    } else if (path.endsWith('/webhook') || action === 'webhook') {
      res = await handleWebhook(req);
    } else {
      res = new Response(JSON.stringify({ error: 'Not found' }), { status: 404 });
    }

    Object.entries(corsHeaders).forEach(([k, v]) => res.headers.set(k, v));
    return res;
  } catch (e) {
    const res = new Response(JSON.stringify({ error: e.message }), { status: 500 });
    Object.entries(corsHeaders).forEach(([k, v]) => res.headers.set(k, v));
    return res;
  }
});

async function handleCreateOrder(req: Request): Promise<Response> {
  const body = await req.clone().json().catch(() => ({}));
  const { gym_id, plan_type, plan_name, created_by } = body;

  if (!gym_id || !plan_type) {
    return new Response(JSON.stringify({ error: 'gym_id and plan_type are required' }), { status: 400 });
  }

  const normalizedPlan = plan_type.toLowerCase();
  const price = PLAN_PRICES[normalizedPlan];
  if (price === undefined) {
    return new Response(JSON.stringify({ error: `Invalid plan_type: ${plan_type}` }), { status: 400 });
  }

  if (price <= 0) {
    const now = new Date().toISOString();
    await supabase.from('payment_requests').insert({
      gym_id,
      plan_type: normalizedPlan,
      plan_name: plan_name || normalizedPlan,
      amount: price,
      status: 'completed',
      razorpay_payment_id: 'free_upgrade',
      created_by: created_by || null,
      updated_at: now,
    });
    await supabase.from('gyms').update({
      subscription: normalizedPlan,
      subscription_expires_at: new Date(Date.now() + 365 * 86400000).toISOString(),
    }).eq('id', gym_id);
    return new Response(JSON.stringify({
      success: true,
      message: 'Free plan activated',
      checkout_url: null,
    }), { status: 200 });
  }

  const { data: request, error } = await supabase
    .from('payment_requests')
    .insert({
      gym_id,
      plan_type: normalizedPlan,
      plan_name: plan_name || normalizedPlan,
      amount: price,
      status: 'pending',
      created_by: created_by || null,
    })
    .select()
    .single();

  if (error || !request) {
    return new Response(JSON.stringify({ error: `Failed to create payment request: ${error?.message}` }), { status: 500 });
  }

  const amountInPaise = price * 100;
  const basicAuth = btoa(`${RAZORPAY_KEY_ID}:${RAZORPAY_KEY_SECRET}`);

  const linkRes = await fetch('https://api.razorpay.com/v1/payment_links/', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Basic ${basicAuth}`,
    },
    body: JSON.stringify({
      amount: amountInPaise,
      currency: 'INR',
      description: `IronBook ${plan_name || normalizedPlan} Plan`,
      callback_url: `${SUPABASE_URL}/functions/v1/handle-payment/payment-callback`,
      callback_method: 'get',
      notes: { request_id: request.id, gym_id, plan_type: normalizedPlan },
      notify: { sms: false, email: false },
    }),
  });

  if (!linkRes.ok) {
    const errText = await linkRes.text();
    await supabase.from('payment_requests').delete().eq('id', request.id);
    return new Response(JSON.stringify({ error: `Razorpay error: ${errText}` }), { status: 500 });
  }

  const link = await linkRes.json();

  await supabase
    .from('payment_requests')
    .update({ razorpay_order_id: link.id })
    .eq('id', request.id);

  return new Response(JSON.stringify({
    success: true,
    request_id: request.id,
    payment_link_id: link.id,
    checkout_url: link.short_url,
  }), { status: 200 });
}

async function handlePaymentCallback(url: URL): Promise<Response> {
  const paymentId = url.searchParams.get('razorpay_payment_id') || '';
  const paymentLinkId = url.searchParams.get('razorpay_payment_link_id') || '';
  const signature = url.searchParams.get('razorpay_signature') || '';

  if (!paymentId || !paymentLinkId) {
    return Response.redirect('ironbook://payment/result?status=failed', 302);
  }

  const message = `${paymentLinkId}|${paymentId}`;
  const expectedSig = await sha256(message, RAZORPAY_KEY_SECRET);
  if (signature !== expectedSig) {
    return Response.redirect('ironbook://payment/result?status=failed', 302);
  }

  const { data: request } = await supabase
    .from('payment_requests')
    .select('*')
    .eq('razorpay_order_id', paymentLinkId)
    .single();

  if (!request || request.status === 'completed') {
    return Response.redirect('ironbook://payment/result?status=success' + (paymentId ? '&payment_id=' + paymentId : ''), 302);
  }

  const now = new Date().toISOString();

  await supabase
    .from('payment_requests')
    .update({
      status: 'completed',
      razorpay_payment_id: paymentId,
      updated_at: now,
    })
    .eq('id', request.id);

  const days = request.plan_type === 'trial' ? 7 : 30;
  const expiresAt = new Date(Date.now() + days * 86400000).toISOString();

  await supabase
    .from('gyms')
    .update({
      subscription: request.plan_type,
      subscription_expires_at: expiresAt,
    })
    .eq('id', request.gym_id);

  return Response.redirect(
    'ironbook://payment/result?status=success' + (paymentId ? '&payment_id=' + paymentId : ''),
    302,
  );
}

async function handleWebhook(req: Request): Promise<Response> {
  const body = await req.text();
  const signature = req.headers.get('x-razorpay-signature') || '';
  const expectedSig = await sha256(body, RAZORPAY_KEY_SECRET);

  if (signature !== expectedSig) {
    return new Response(JSON.stringify({ error: 'Invalid signature' }), { status: 401 });
  }

  const event = JSON.parse(body);
  if (event.event !== 'payment.captured') {
    return new Response(JSON.stringify({ status: 'ignored' }), { status: 200 });
  }

  const payment = event.payload.payment.entity;
  const paymentId = payment.id;
  const requestId = payment.notes?.request_id || payment.receipt;

  if (!requestId) {
    return new Response(JSON.stringify({ error: 'No request_id' }), { status: 400 });
  }

  const { data: request } = await supabase
    .from('payment_requests')
    .select('*')
    .eq('id', requestId)
    .single();

  if (!request || request.status === 'completed') {
    return new Response(JSON.stringify({ status: 'already_processed' }), { status: 200 });
  }

  const now = new Date().toISOString();

  await supabase
    .from('payment_requests')
    .update({
      status: 'completed',
      razorpay_payment_id: paymentId,
      updated_at: now,
    })
    .eq('id', requestId);

  const days = request.plan_type === 'trial' ? 7 : 30;
  const expiresAt = new Date(Date.now() + days * 86400000).toISOString();

  const { data: gym } = await supabase
    .from('gyms')
    .select('subscription, subscription_expires_at')
    .eq('id', request.gym_id)
    .single();

  const currentExpiry = gym?.subscription_expires_at ? new Date(gym.subscription_expires_at) : null;
  const newExpiry = new Date(expiresAt);

  if (!gym || gym.subscription !== request.plan_type || !currentExpiry || currentExpiry < newExpiry) {
    await supabase
      .from('gyms')
      .update({
        subscription: request.plan_type,
        subscription_expires_at: expiresAt,
      })
      .eq('id', request.gym_id);
  }

  return new Response(JSON.stringify({ status: 'ok' }), { status: 200 });
}

async function sha256(data: string, secret: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    'raw', new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false, ['sign'],
  );
  const sig = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(data));
  return Array.from(new Uint8Array(sig)).map(b => b.toString(16).padStart(2, '0')).join('');
}
