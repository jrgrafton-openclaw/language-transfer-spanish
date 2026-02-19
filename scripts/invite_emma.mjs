#!/usr/bin/env node
/**
 * Invite an external email to App Store Connect as a tester-only user,
 * then add them to the internal beta testing group.
 */

import { readFileSync } from 'fs';
import { createPrivateKey, createSign } from 'crypto';

const ASC_KEY_PATH = '/Users/familybot/.openclaw/secrets/app-store-connect/AuthKey_7UKLD4C2CC.p8';
const ASC_KEY_ID = '7UKLD4C2CC';
const ASC_ISSUER_ID = '69a6de70-79a7-47e3-e053-5b8c7c11a4d1';
const APP_ID = '6759312589';
const GROUP_ID = '201ce7f8-cd46-4bf9-8e28-34c2e5eeb8f0';
const INVITE_EMAIL = 'emma.mascall@icloud.com';
const INVITE_FIRST = 'Emma';
const INVITE_LAST = 'Mascall';

function base64url(buf) {
  return Buffer.from(buf).toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
}

function generateToken() {
  const now = Math.floor(Date.now() / 1000);
  const header = base64url(JSON.stringify({ alg: 'ES256', kid: ASC_KEY_ID, typ: 'JWT' }));
  const payload = base64url(JSON.stringify({ iss: ASC_ISSUER_ID, iat: now, exp: now + 1200, aud: 'appstoreconnect-v1' }));
  const unsigned = `${header}.${payload}`;
  const pem = readFileSync(ASC_KEY_PATH, 'utf8');
  const key = createPrivateKey(pem);
  const sign = createSign('SHA256');
  sign.update(unsigned);
  const sig = sign.sign({ key, dsaEncoding: 'ieee-p1363' });
  return `${unsigned}.${base64url(sig)}`;
}

async function api(method, path, body) {
  const token = generateToken();
  const opts = {
    method,
    headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' }
  };
  if (body) opts.body = JSON.stringify(body);
  const res = await fetch(`https://api.appstoreconnect.apple.com/v1${path}`, opts);
  const text = await res.text();
  let data;
  try { data = JSON.parse(text); } catch { data = { raw: text }; }
  return { ok: res.ok, status: res.status, data };
}

console.log(`=== Inviting ${INVITE_EMAIL} to TestFlight ===\n`);

// Step 1: Check if already a beta tester
console.log('Step 1: Checking if already a beta tester...');
let r = await api('GET', `/betaTesters?filter[email]=${encodeURIComponent(INVITE_EMAIL)}`);
let betaTesterId = r.data?.data?.[0]?.id;

if (betaTesterId) {
  console.log(`✓ Already a beta tester: ${betaTesterId}`);
} else {
  // Step 2: Create beta tester directly (external flow — no App Store Connect account required)
  console.log('Step 2: Creating beta tester + adding to group...');
  r = await api('POST', '/betaTesters', {
    data: {
      type: 'betaTesters',
      attributes: {
        email: INVITE_EMAIL,
        firstName: INVITE_FIRST,
        lastName: INVITE_LAST
      },
      relationships: {
        betaGroups: {
          data: [{ type: 'betaGroups', id: GROUP_ID }]
        }
      }
    }
  });

  if (r.ok) {
    betaTesterId = r.data.data?.id;
    console.log(`✓ Beta tester created: ${betaTesterId}`);
  } else {
    console.log(`Response (${r.status}):`, JSON.stringify(r.data, null, 2));
    throw new Error('Failed to create beta tester');
  }
}

// Step 3: Ensure added to group
console.log('\nStep 3: Ensuring membership in InternalTesters group...');
r = await api('POST', `/betaGroups/${GROUP_ID}/relationships/betaTesters`, {
  data: [{ type: 'betaTesters', id: betaTesterId }]
});

if (r.ok || r.status === 409) {
  console.log('✓ Added to InternalTesters group');
} else {
  console.log(`⚠ Group add response (${r.status}):`, JSON.stringify(r.data, null, 2));
}

console.log(`\n✅ ${INVITE_EMAIL} has been invited to TestFlight!`);
console.log('She will receive an email from Apple with a link to download the app.');
