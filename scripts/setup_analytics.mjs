#!/usr/bin/env node

/**
 * Google Analytics Setup for Firebase
 * Creates Analytics account via provisionAccountTicket flow
 */

import { readFileSync, writeFileSync } from 'fs';
import { createPrivateKey, createSign } from 'crypto';

const keyFile = process.env.FIREBASE_KEY_FILE;
if (!keyFile) throw new Error('FIREBASE_KEY_FILE env var is required (path to Firebase service account JSON)');
const keyData = JSON.parse(readFileSync(keyFile, 'utf8'));

const PROJECT_ID = 'lobsterproject';
const BUNDLE_ID = 'com.grafton.languagetransfer.spanish';
const APP_NAME = 'Language Transfer Spanish';

// Generate OAuth token with Analytics scopes
async function getAnalyticsToken() {
  function base64url(input) {
    const buf = Buffer.from(input, 'utf8');
    return buf.toString('base64')
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=/g, '');
  }
  
  const now = Math.floor(Date.now() / 1000);
  const header = base64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const payload = base64url(JSON.stringify({
    iss: keyData.client_email,
    sub: keyData.client_email,
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
    scope: 'https://www.googleapis.com/auth/analytics.edit https://www.googleapis.com/auth/firebase'
  }));
  
  const signingInput = `${header}.${payload}`;
  
  const key = createPrivateKey(keyData.private_key);
  const signer = createSign('RSA-SHA256');
  signer.update(signingInput);
  signer.end();
  
  const signatureBuffer = signer.sign(key);
  const signature = signatureBuffer.toString('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '');
  
  const jwt = `${header}.${payload}.${signature}`;
  
  // Exchange JWT for access token
  const body = `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${encodeURIComponent(jwt)}`;
  
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body
  });
  
  const data = await res.json();
  
  if (!res.ok) {
    throw new Error(`Token exchange failed: ${JSON.stringify(data)}`);
  }
  
  return data.access_token;
}

async function api(method, url, token, body = null) {
  const opts = {
    method,
    headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' }
  };
  
  if (body) opts.body = JSON.stringify(body);
  
  const res = await fetch(url, opts);
  const text = await res.text();
  let data = null;
  
  if (text) {
    try {
      data = JSON.parse(text);
    } catch (e) {
      data = text;
    }
  }
  
  return { status: res.status, data, ok: res.status >= 200 && res.status < 300 };
}

async function provisionAccount(token) {
  console.log('=== Step 1: Creating Analytics Account Ticket ===\n');
  
  const r = await api('POST', 'https://analyticsadmin.googleapis.com/v1beta/accounts:provisionAccountTicket', token, {
    account: {
      displayName: 'OpenClaw Mobile Studio',
      regionCode: 'US'
    },
    redirectUri: 'https://analytics.google.com'
  });
  
  if (!r.ok) {
    console.error(`❌ Failed: ${r.status}`);
    console.error(JSON.stringify(r.data, null, 2));
    return null;
  }
  
  const accountTicketId = r.data.accountTicketId;
  const tosUrl = `https://analytics.google.com/analytics/web/?provisioningSignup=false#/termsofservice/${accountTicketId}`;
  
  console.log('✅ Account ticket created!');
  console.log(`Account Ticket ID: ${accountTicketId}`);
  console.log();
  console.log('='.repeat(70));
  console.log('⚠️  MANUAL STEP REQUIRED');
  console.log('='.repeat(70));
  console.log();
  console.log('Please visit this URL to accept Google Analytics Terms of Service:');
  console.log();
  console.log(`  ${tosUrl}`);
  console.log();
  console.log('After accepting, run: node scripts/setup_analytics.mjs --complete');
  console.log();
  
  writeFileSync('/tmp/analytics_ticket.json', JSON.stringify({
    ticketId: accountTicketId,
    tosUrl
  }));
  
  return accountTicketId;
}

async function listAccounts(token) {
  console.log('=== Listing Analytics Accounts ===\n');
  
  const r = await api('GET', 'https://analyticsadmin.googleapis.com/v1beta/accounts', token);
  
  if (!r.ok) {
    console.error(`Error: ${r.status}`);
    console.error(JSON.stringify(r.data, null, 2));
    return [];
  }
  
  const accounts = r.data.accounts || [];
  
  if (!accounts.length) {
    console.log('No accounts found yet. Please ensure you accepted the TOS.');
    return [];
  }
  
  console.log(`Found ${accounts.length} account(s):`);
  for (const acc of accounts) {
    console.log(`  - ${acc.displayName} (${acc.name})`);
  }
  
  return accounts;
}

async function createGA4Property(token, accountName) {
  console.log('\n=== Step 2: Creating GA4 Property ===\n');
  
  const r = await api('POST', 'https://analyticsadmin.googleapis.com/v1beta/properties', token, {
    parent: accountName,
    displayName: APP_NAME,
    industryCategory: 'EDUCATION',
    timeZone: 'America/Chicago',
    currencyCode: 'USD',
    propertyType: 'PROPERTY_TYPE_ORDINARY'
  });
  
  if (!r.ok) {
    console.error(`❌ Failed: ${r.status}`);
    console.error(JSON.stringify(r.data, null, 2));
    return null;
  }
  
  const propertyName = r.data.name;
  const propertyId = propertyName.split('/')[1];
  
  console.log(`✅ GA4 Property created: ${propertyId}`);
  return propertyName;
}

async function createIOSStream(token, propertyName) {
  console.log('\n=== Step 3: Creating iOS Data Stream ===\n');
  
  const r = await api('POST', `https://analyticsadmin.googleapis.com/v1beta/${propertyName}/dataStreams`, token, {
    displayName: `${APP_NAME} - iOS`,
    type: 'IOS_APP_DATA_STREAM',
    iosAppStreamData: {
      bundleId: BUNDLE_ID
    }
  });
  
  if (!r.ok) {
    console.error(`❌ Failed: ${r.status}`);
    console.error(JSON.stringify(r.data, null, 2));
    return null;
  }
  
  const streamId = r.data.name.split('/').pop();
  const measurementId = r.data.webStreamData?.measurementId || streamId;
  
  console.log(`✅ iOS Data Stream created: ${streamId}`);
  console.log(`Measurement ID: ${measurementId}`);
  
  return r.data;
}

async function linkFirebase(token, propertyName) {
  console.log('\n=== Step 4: Linking Firebase to Analytics ===\n');
  
  const propertyId = propertyName.split('/')[1];
  
  const r = await api('POST', `https://firebase.googleapis.com/v1beta1/projects/${PROJECT_ID}:addGoogleAnalytics`, token, {
    analyticsPropertyId: propertyId
  });
  
  if (!r.ok) {
    console.log(`⚠️  Note: ${r.status}`);
    console.log(JSON.stringify(r.data, null, 2));
  } else {
    console.log('✅ Firebase linked to Analytics!');
  }
  
  return r.ok;
}

async function completeSetup(token) {
  const accounts = await listAccounts(token);
  
  if (!accounts.length) {
    console.log('\n❌ No accounts found. Please accept TOS first.');
    return false;
  }
  
  // Find "OpenClaw Mobile Studio" or use latest
  let account = accounts.find(a => a.displayName.includes('OpenClaw Mobile Studio'));
  if (!account) account = accounts[accounts.length - 1];
  
  console.log(`\n✅ Using account: ${account.displayName}`);
  
  const propertyName = await createGA4Property(token, account.name);
  if (!propertyName) return false;
  
  const stream = await createIOSStream(token, propertyName);
  if (!stream) return false;
  
  await linkFirebase(token, propertyName);
  
  const propertyId = propertyName.split('/')[1];
  
  console.log('\n' + '='.repeat(70));
  console.log('✅ SETUP COMPLETE!');
  console.log('='.repeat(70));
  console.log();
  console.log(`Property: ${propertyName}`);
  console.log(`Stream: ${stream.name}`);
  console.log();
  console.log(`View at: https://analytics.google.com/analytics/web/#/p${propertyId}/reports/intelligenthome`);
  console.log();
  
  return true;
}

async function main() {
  const token = await getAnalyticsToken();
  console.log('✅ Got Analytics Admin API token\n');
  
  if (process.argv.includes('--complete')) {
    const success = await completeSetup(token);
    process.exit(success ? 0 : 1);
  } else {
    const ticket = await provisionAccount(token);
    process.exit(ticket ? 0 : 1);
  }
}

main().catch(err => {
  console.error('❌ Error:', err.message);
  process.exit(1);
});
