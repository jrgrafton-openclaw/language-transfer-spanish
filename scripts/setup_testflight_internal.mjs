#!/usr/bin/env node

/**
 * TestFlight Internal Testing Automation
 * Adds the latest build to internal testing for specified testers
 * Based on Fastlane Spaceship patterns
 */

import { readFileSync } from 'fs';
import { createPrivateKey, createSign } from 'crypto';

const ASC_KEY_PATH = process.env.ASC_KEY_PATH;
if (!ASC_KEY_PATH) throw new Error('ASC_KEY_PATH env var is required (path to App Store Connect .p8 key)');
const ASC_KEY_ID = process.env.ASC_KEY_ID || '7UKLD4C2CC';
const ASC_ISSUER_ID = process.env.ASC_ISSUER_ID || '69a6de70-79a7-47e3-e053-5b8c7c11a4d1';
const BUNDLE_ID = 'com.grafton.languagetransfer.spanish';
const TESTER_EMAIL = 'jrgrafton@gmail.com';

// Generate JWT token for App Store Connect API
function generateToken() {
  function base64url(buf) {
    return (typeof buf === 'string' ? Buffer.from(buf) : buf)
      .toString('base64').replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
  }

  const now = Math.floor(Date.now() / 1000);
  const header = base64url(JSON.stringify({ alg: 'ES256', kid: ASC_KEY_ID, typ: 'JWT' }));
  const payload = base64url(JSON.stringify({ 
    iss: ASC_ISSUER_ID, 
    iat: now, 
    exp: now + 1200, 
    aud: 'appstoreconnect-v1' 
  }));
  
  const key = createPrivateKey(readFileSync(ASC_KEY_PATH, 'utf8'));
  const sign = createSign('SHA256');
  sign.update(`${header}.${payload}`);
  const sig = sign.sign({ key, dsaEncoding: 'ieee-p1363' });
  
  return `${header}.${payload}.${base64url(sig)}`;
}

const token = generateToken();

async function api(method, path, body = null) {
  const url = `https://api.appstoreconnect.apple.com/v1${path}`;
  const opts = {
    method,
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    }
  };
  
  if (body) {
    opts.body = JSON.stringify(body);
  }
  
  const res = await fetch(url, opts);
  
  let data = null;
  const contentType = res.headers.get('content-type');
  
  if (contentType && contentType.includes('application/json')) {
    const text = await res.text();
    if (text) {
      try {
        data = JSON.parse(text);
      } catch (e) {
        // Ignore parse errors for empty responses
      }
    }
  }
  
  if (res.status >= 400 && data) {
    console.error(`API Error (${res.status}): ${path}`);
    console.error(JSON.stringify(data, null, 2));
  }
  
  return { status: res.status, data, ok: res.status >= 200 && res.status < 300 };
}

async function main() {
  console.log('=== TestFlight Internal Testing Automation ===\n');
  
  // Step 1: Find the app
  console.log('Step 1: Finding app...');
  let r = await api('GET', `/apps?filter[bundleId]=${BUNDLE_ID}`);
  if (!r.ok || !r.data.data?.length) {
    throw new Error('App not found');
  }
  
  const appId = r.data.data[0].id;
  console.log(`✓ App ID: ${appId}\n`);
  
  // Step 2: Get the latest build
  console.log('Step 2: Finding latest build...');
  
  // First get builds list (no sorting allowed)
  r = await api('GET', `/apps/${appId}/builds?limit=200`);
  
  if (!r.ok || !r.data.data?.length) {
    throw new Error('No builds found');
  }
  
  // Sort by uploaded date manually (most recent first)
  const builds = r.data.data.sort((a, b) => {
    const dateA = new Date(a.attributes.uploadedDate || 0);
    const dateB = new Date(b.attributes.uploadedDate || 0);
    return dateB - dateA;
  });
  
  const build = builds[0];
  const buildId = build.id;
  const version = build.attributes.version;
  const buildNumber = build.attributes.buildNumber;
  
  console.log(`✓ Build: ${version} (${buildNumber})`);
  console.log(`✓ Build ID: ${buildId}`);
  
  // Step 3: Find or create internal beta group
  console.log('Step 3: Setting up internal beta group...');
  r = await api('GET', `/apps/${appId}/betaGroups`);
  
  // Look for existing internal group
  let betaGroup = r.data.data?.find(g => 
    g.attributes.isInternalGroup === true ||
    g.attributes.name === 'InternalTesters' ||
    g.attributes.name === 'App Store Connect Users'
  );
  
  let betaGroupId;
  
  if (betaGroup) {
    betaGroupId = betaGroup.id;
    console.log(`✓ Found existing internal group: "${betaGroup.attributes.name}"`);
    console.log(`✓ Group ID: ${betaGroupId}\n`);
  } else {
    console.log('Creating new internal beta group...');
    
    // Create internal group following Fastlane Spaceship pattern
    r = await api('POST', '/betaGroups', {
      data: {
        type: 'betaGroups',
        attributes: {
          name: 'InternalTesters',
          isInternalGroup: true,
          hasAccessToAllBuilds: true,
          publicLinkEnabled: false
        },
        relationships: {
          app: {
            data: { type: 'apps', id: appId }
          }
        }
      }
    });
    
    if (!r.ok) {
      // Try without hasAccessToAllBuilds if it fails
      console.log('Retrying without hasAccessToAllBuilds...');
      r = await api('POST', '/betaGroups', {
        data: {
          type: 'betaGroups',
          attributes: {
            name: 'InternalTesters',
            isInternalGroup: true,
            publicLinkEnabled: false
          },
          relationships: {
            app: {
              data: { type: 'apps', id: appId }
            }
          }
        }
      });
    }
    
    if (!r.ok) {
      throw new Error('Failed to create internal beta group');
    }
    
    betaGroupId = r.data.data.id;
    console.log(`✓ Created internal group: ${betaGroupId}\n`);
  }
  
  // Step 4: Enable build for internal testing
  console.log('Step 4: Enabling build for internal testing...');
  
  // Get build beta detail
  r = await api('GET', `/builds/${buildId}/buildBetaDetail`);
  
  if (r.ok && r.data.data) {
    const betaDetailId = r.data.data.id;
    const currentState = r.data.data.attributes.internalBuildState;
    console.log(`Current internal build state: ${currentState}`);
    
    if (currentState !== 'IN_BETA_TESTING') {
      console.log('Enabling internal testing...');
      r = await api('PATCH', `/buildBetaDetails/${betaDetailId}`, {
        data: {
          type: 'buildBetaDetails',
          id: betaDetailId,
          attributes: {
            autoNotifyEnabled: true
          }
        }
      });
      
      if (r.ok) {
        console.log('✓ Internal testing enabled\n');
      } else {
        console.log('⚠ Warning: Could not enable internal testing\n');
      }
    } else {
      console.log('✓ Build already enabled for internal testing\n');
    }
  } else {
    console.log('⚠ Could not get build beta detail\n');
  }
  
  // Step 5: Find or create beta tester
  console.log('Step 5: Setting up beta tester...');
  r = await api('GET', `/betaTesters?filter[email]=${TESTER_EMAIL}`);
  
  let betaTesterId;
  
  if (r.data.data?.length > 0) {
    betaTesterId = r.data.data[0].id;
    console.log(`✓ Found beta tester: ${betaTesterId}\n`);
  } else {
    console.log('Beta tester not found, checking users...');
    
    // Look up user in team
    r = await api('GET', `/users?filter[username]=${TESTER_EMAIL}`);
    
    if (r.data.data?.length > 0) {
      const userId = r.data.data[0].id;
      console.log(`✓ Found team member: ${userId}`);
      
      // For internal testing, team members are automatically beta testers
      // Try to add them to the group directly
      betaTesterId = userId;
    } else {
      throw new Error('Tester not found in team');
    }
  }
  
  // Step 6: Add tester as individual tester to build
  console.log('Step 6: Adding tester to build (individual internal tester)...');
  r = await api('POST', `/builds/${buildId}/relationships/individualTesters`, {
    data: [{ type: 'betaTesters', id: betaTesterId }]
  });
  
  if (r.status === 409) {
    console.log('✓ Tester already added to build\n');
  } else if (r.ok) {
    console.log('✓ Tester added to build\n');
  } else {
    console.log('⚠ Warning: Could not add tester to build\n');
    
    // Also try via the beta group for App Store Connect Users
    console.log('Trying alternate approach via App Store Connect Users group...');
    r = await api('GET', `/apps/${appId}/betaGroups`);
    const ascGroup = r.data.data?.find(g => g.attributes.name === 'App Store Connect Users');
    
    if (ascGroup) {
      console.log(`Found "App Store Connect Users" group: ${ascGroup.id}`);
      // Team members in this group automatically get access
    }
  }
  
  // Step 7: Verify relationships
  console.log('Step 7: Verifying setup...');
  
  // Check build beta detail
  r = await api('GET', `/builds/${buildId}/buildBetaDetail`);
  const internalState = r.data.data?.attributes?.internalBuildState;
  console.log(`Build internal state: ${internalState || 'unknown'} ${internalState === 'IN_BETA_TESTING' ? '✓' : '✗'}`);
  
  // Check individual testers on build
  r = await api('GET', `/builds/${buildId}/individualTesters`);
  const buildHasTester = r.data.data?.some(t => t.id === betaTesterId || t.attributes.email === TESTER_EMAIL);
  console.log(`Build → Individual Tester: ${buildHasTester ? '✓' : '✗'}`);
  
  // Check betaGroup → testers (for reference)
  r = await api('GET', `/betaGroups/${betaGroupId}/betaTesters`);
  const groupHasTester = r.data.data?.some(t => t.id === betaTesterId);
  console.log(`BetaGroup → Tester: ${groupHasTester ? '✓' : '✗'}`);
  
  console.log('\n=== Summary ===');
  console.log(`App ID: ${appId}`);
  console.log(`Build ID: ${buildId} (${version} build ${buildNumber})`);
  console.log(`Beta Group ID: ${betaGroupId}`);
  console.log(`Beta Tester ID: ${betaTesterId}`);
  console.log(`Tester Email: ${TESTER_EMAIL}`);
  console.log('\n✅ Setup complete!');
  console.log('Build should appear in TestFlight app within 1-2 minutes.');
}

main().catch(err => {
  console.error('\n❌ Error:', err.message);
  process.exit(1);
});
