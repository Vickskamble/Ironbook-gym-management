import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const RAZORPAY_KEY_ID = Deno.env.get('RAZORPAY_KEY_ID')!;
const RAZORPAY_KEY_SECRET = Deno.env.get('RAZORPAY_KEY_SECRET')!;

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

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
  const body = await req.clone().json().catch(() => ({}));
  const action = body.action || '';

  try {
    let res: Response;
    if (path.endsWith('/create-order') || action === 'create-order') {
      res = await handleCreateOrder(req);
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
  const { request_id } = await req.json();
  if (!request_id) {
    return new Response(JSON.stringify({ error: 'request_id is required' }), { status: 400 });
  }

  const { data: request, error } = await supabase
    .from('payment_requests')
    .select('*')
    .eq('id', request_id)
    .single();

  if (error || !request) {
    return new Response(JSON.stringify({ error: 'Payment request not found' }), { status: 404 });
  }

  if (request.status !== 'pending') {
    return new Response(JSON.stringify({ error: 'Payment already processed' }), { status: 400 });
  }

  const amountInPaise = Math.round(parseFloat(request.amount) * 100);
  const basicAuth = btoa(`${RAZORPAY_KEY_ID}:${RAZORPAY_KEY_SECRET}`);

  const orderRes = await fetch('https://api.razorpay.com/v1/orders', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Basic ${basicAuth}`,
    },
    body: JSON.stringify({
      amount: amountInPaise,
      currency: 'INR',
      receipt: request_id,
      notes: { request_id },
    }),
  });

  if (!orderRes.ok) {
    const errText = await orderRes.text();
    return new Response(JSON.stringify({ error: `Razorpay error: ${errText}` }), { status: 500 });
  }

  const order = await orderRes.json();

  await supabase
    .from('payment_requests')
    .update({ razorpay_order_id: order.id })
    .eq('id', request_id);

  return new Response(JSON.stringify({
    id: order.id,
    amount: order.amount,
    key_id: RAZORPAY_KEY_ID,
    description: request.plan_name || 'IronBook Subscription',
  }), { status: 200 });
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
  const orderId = payment.order_id;
  const paymentId = payment.id;
  const requestId = payment.notes?.request_id || payment.receipt;

  if (!requestId) {
    return new Response(JSON.stringify({ error: 'No request_id in payment notes' }), { status: 400 });
  }

  const { data: request } = await supabase
    .from('payment_requests')
    .select('*')
    .eq('id', requestId)
    .single();

  if (!request || request.status === 'completed') {
    return new Response(JSON.stringify({ status: 'already processed' }), { status: 200 });
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

  await supabase
    .from('gyms')
    .update({
      subscription: request.plan_type,
      subscription_expires_at: expiresAt,
    })
    .eq('id', request.gym_id);

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
