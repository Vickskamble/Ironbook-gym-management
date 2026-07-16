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
  const bodyAction = await req.clone().json().then((b) => b.action).catch(() => '');
  const action = url.searchParams.get('action') || bodyAction;

  try {
    let res: Response;

    if (path.endsWith('/create-order') || path.endsWith('/create-payment-link') || action === 'create-order' || action === 'create-payment-link') {
      res = await handleCreateOrder(req);
    } else if (path.endsWith('/checkout')) {
      res = await handleCheckoutPage(url);
    } else if (path.endsWith('/callback') || action === 'callback') {
      res = await handleDirectCallback(req);
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
  const { gym_id, plan_type, plan_name, amount, created_by } = body;

  if (!gym_id || !plan_type || !amount) {
    return new Response(JSON.stringify({ error: 'gym_id, plan_type, and amount are required' }), { status: 400 });
  }

  const { data: request, error } = await supabase
    .from('payment_requests')
    .insert({
      gym_id,
      plan_type,
      plan_name: plan_name || plan_type,
      amount,
      status: 'pending',
      created_by: created_by || null,
    })
    .select()
    .single();

  if (error || !request) {
    return new Response(JSON.stringify({ error: `Failed to create payment request: ${error?.message}` }), { status: 500 });
  }

  const amountInPaise = Math.round(parseFloat(amount) * 100);
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
      receipt: request.id,
      notes: { request_id: request.id },
    }),
  });

  if (!orderRes.ok) {
    const errText = await orderRes.text();
    await supabase.from('payment_requests').delete().eq('id', request.id);
    return new Response(JSON.stringify({ error: `Razorpay error: ${errText}` }), { status: 500 });
  }

  const order = await orderRes.json();

  await supabase
    .from('payment_requests')
    .update({ razorpay_order_id: order.id })
    .eq('id', request.id);

  const checkoutUrl = `${SUPABASE_URL}/functions/v1/handle-payment/checkout?order_id=${order.id}&key_id=${RAZORPAY_KEY_ID}&amount=${amountInPaise}&request_id=${request.id}`;

  return new Response(JSON.stringify({
    success: true,
    request_id: request.id,
    order_id: order.id,
    key_id: RAZORPAY_KEY_ID,
    amount: amountInPaise,
    checkout_url: checkoutUrl,
  }), { status: 200 });
}

async function handleCheckoutPage(url: URL): Promise<Response> {
  const orderId = url.searchParams.get('order_id') || '';
  const keyId = url.searchParams.get('key_id') || '';
  const amount = url.searchParams.get('amount') || '0';
  const requestId = url.searchParams.get('request_id') || '';
  const callbackUrl = `${SUPABASE_URL}/functions/v1/handle-payment/callback`;

  const html = `
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Processing Payment - IronBook</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; background: #f8f9fa; }
    .card { background: white; border-radius: 16px; padding: 40px; text-align: center; box-shadow: 0 4px 24px rgba(0,0,0,0.1); max-width: 400px; }
    .spinner { width: 40px; height: 40px; border: 4px solid #e2e8f0; border-top: 4px solid #6366F1; border-radius: 50%; animation: spin 1s linear infinite; margin: 0 auto 16px; }
    @keyframes spin { to { transform: rotate(360deg); } }
    h2 { color: #1e293b; margin: 0 0 8px 0; }
    p { color: #64748b; }
  </style>
  <script src="https://checkout.razorpay.com/v1/checkout.js"></script>
</head>
<body>
  <div class="card">
    <div class="spinner"></div>
    <h2>Opening Payment Gateway...</h2>
    <p>Please complete the payment in the popup.</p>
  </div>
  <script>
    var options = {
      key: "${keyId}",
      amount: ${amount},
      currency: "INR",
      name: "IronBook",
      description: "IronBook Subscription",
      order_id: "${orderId}",
      handler: function(response) {
        fetch("${callbackUrl}", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            razorpay_payment_id: response.razorpay_payment_id,
            razorpay_order_id: response.razorpay_order_id,
            request_id: "${requestId}"
          })
        })
        .then(function(r) { return r.json(); })
        .then(function(data) {
          document.body.innerHTML = data.html || '<div class="card"><div style="font-size:64px;margin-bottom:16px">✅</div><h2 style="color:#22c55e">Payment Successful!</h2><p>Your IronBook plan has been activated. You can close this tab.</p></div>';
          if (data.redirect_url) {
            setTimeout(function() { window.location.href = data.redirect_url; }, 1500);
          }
        })
        .catch(function() {
          document.body.innerHTML = '<div class="card"><div style="font-size:64px;margin-bottom:16px">✅</div><h2 style="color:#22c55e">Payment Successful!</h2><p>You can close this tab and return to the app.</p><a href="ironbook://payment/result?status=success&request_id=${requestId}" style="display:inline-block;margin-top:20px;padding:12px 32px;background:#6366F1;color:white;text-decoration:none;border-radius:8px;font-weight:600">Return to App</a></div>';
        });
      },
      modal: {
        ondismiss: function() {
          document.body.innerHTML = '<div class="card"><div style="font-size:64px;margin-bottom:16px">❌</div><h2 style="color:#ef4444">Payment Cancelled</h2><p>You closed the payment window. Please try again.</p><button onclick="window.close()" style="margin-top:20px;padding:12px 32px;background:#6366F1;color:white;border:none;border-radius:8px;font-weight:600;cursor:pointer">Close</button></div>';
        }
      },
      prefill: {},
      theme: { color: "#6366F1" }
    };
    var rzp = new Razorpay(options);
    rzp.open();
  </script>
</body>
</html>`;

  return new Response(html, {
    status: 200,
    headers: { 'Content-Type': 'text/html' },
  });
}

async function handleDirectCallback(req: Request): Promise<Response> {
  const body = await req.clone().json().catch(() => ({}));
  const { razorpay_payment_id, razorpay_order_id, request_id } = body;

  if (!razorpay_payment_id || !request_id) {
    return new Response(JSON.stringify({ error: 'Missing payment_id or request_id' }), { status: 400 });
  }

  const { data: request } = await supabase
    .from('payment_requests')
    .select('*')
    .eq('id', request_id)
    .single();

  if (!request) {
    return new Response(JSON.stringify({ error: 'Payment request not found' }), { status: 404 });
  }

  if (request.status === 'completed') {
    return new Response(JSON.stringify({
      status: 'already_processed',
      html: successHtml(true),
      redirect_url: 'ironbook://payment/result?status=success&request_id=' + request_id,
    }), { status: 200 });
  }

  const now = new Date().toISOString();

  await supabase
    .from('payment_requests')
    .update({
      status: 'completed',
      razorpay_payment_id,
      razorpay_order_id: razorpay_order_id || request.razorpay_order_id,
      updated_at: now,
    })
    .eq('id', request_id);

  const days = request.plan_type === 'trial' ? 7 : 30;
  const expiresAt = new Date(Date.now() + days * 86400000).toISOString();

  await supabase
    .from('gyms')
    .update({
      subscription: request.plan_type,
      subscription_expires_at: expiresAt,
    })
    .eq('id', request.gym_id);

  return new Response(JSON.stringify({
    status: 'completed',
    html: successHtml(true),
    redirect_url: 'ironbook://payment/result?status=success&request_id=' + request_id,
  }), { status: 200 });
}

function successHtml(success: boolean): string {
  if (success) {
    return '<div class="card"><div style="font-size:64px;margin-bottom:16px">✅</div><h2 style="color:#22c55e">Payment Successful!</h2><p>Your IronBook plan has been activated. You can close this tab.</p></div>';
  }
  return '<div class="card"><div style="font-size:64px;margin-bottom:16px">❌</div><h2 style="color:#ef4444">Payment Failed</h2><p>Something went wrong. Please try again.</p></div>';
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
    return new Response(JSON.stringify({ error: 'No request_id in payment notes' }), { status: 400 });
  }

  const { data: request } = await supabase
    .from('payment_requests')
    .select('*')
    .eq('id', requestId)
    .single();

  if (!request) {
    return new Response(JSON.stringify({ error: 'Payment request not found' }), { status: 404 });
  }

  if (request.status === 'completed') {
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
