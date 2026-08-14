import { createClient } from 'npm:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, apikey, content-type, x-client-info',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const json = (status: number, body: Record<string, unknown>) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json; charset=utf-8' },
  });

const sha256 = async (value: string) => {
  const bytes = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest('SHA-256', bytes);
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');
};

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (request.method !== 'POST') {
    return json(405, { code: 'method_not_allowed' });
  }

  let body: { email?: unknown; password?: unknown; website?: unknown };
  try {
    body = await request.json();
  } catch {
    return json(400, { code: 'invalid_request' });
  }

  // A hidden honeypot field blocks unsophisticated automated form posts while
  // staying invisible to legitimate Android clients.
  if (typeof body.website === 'string' && body.website.trim().length > 0) {
    return json(202, { ok: true });
  }

  const email = typeof body.email === 'string' ? body.email.trim().toLowerCase() : '';
  const password = typeof body.password === 'string' ? body.password : '';
  const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailPattern.test(email) || email.length > 254 || password.length < 10 || password.length > 72) {
    return json(400, { code: 'invalid_credentials' });
  }

  const projectUrl = Deno.env.get('SUPABASE_URL');
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!projectUrl || !serviceKey) {
    console.error('Gauss signup is missing its server environment.');
    return json(503, { code: 'service_unavailable' });
  }

  const forwarded = request.headers.get('x-forwarded-for')?.split(',')[0]?.trim();
  const networkIdentity = forwarded || request.headers.get('cf-connecting-ip') || 'unknown';
  const admin = createClient(projectUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const [networkHash, emailHash] = await Promise.all([
    sha256(networkIdentity),
    sha256(email),
  ]);
  const { data: allowed, error: throttleError } = await admin.rpc(
    'gauss_claim_registration_slot',
    {
      p_network_hash: networkHash,
      p_email_hash: emailHash,
    },
  );

  if (throttleError) {
    console.error('Gauss signup throttle failed:', throttleError.code);
    return json(503, { code: 'service_unavailable' });
  }
  if (allowed !== true) {
    return json(429, { code: 'try_later' });
  }

  const { data, error } = await admin.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    app_metadata: { product: 'gauss' },
    user_metadata: { gauss_email_hash: emailHash },
  });

  if (error || !data.user) {
    // Do not reveal whether an address already exists. The Android UI offers
    // sign-in beside registration, so an owner can recover without an account
    // enumeration oracle.
    console.warn('Gauss signup rejected:', error?.code ?? 'missing_user');
    return json(409, { code: 'account_unavailable' });
  }

  return json(201, { ok: true });
});
