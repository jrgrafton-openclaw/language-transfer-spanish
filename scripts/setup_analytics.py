#!/usr/bin/env python3
"""
Google Analytics Setup for Firebase
Creates Analytics account, GA4 property, iOS data stream, and links to Firebase
"""

import json
import subprocess
import sys
import time
from urllib.request import Request, urlopen
from urllib.error import HTTPError

PROJECT_ID = 'lobsterproject'
BUNDLE_ID = 'com.grafton.languagetransfer.spanish'
APP_NAME = 'Language Transfer Spanish'

def get_access_token():
    """Get access token via gcloud"""
    subprocess.run([
        'gcloud', 'auth', 'activate-service-account',
        '--key-file=/Users/familybot/.openclaw/secrets/firebase/service-account.json'
    ], check=True, capture_output=True)
    
    result = subprocess.run([
        'gcloud', 'auth', 'print-access-token'
    ], check=True, capture_output=True, text=True)
    
    return result.stdout.strip()

def api_call(method, url, token, body=None):
    """Make API call with proper error handling"""
    req = Request(url, method=method)
    req.add_header('Authorization', f'Bearer {token}')
    
    if body:
        req.add_header('Content-Type', 'application/json')
        req.data = json.dumps(body).encode()
    
    try:
        response = urlopen(req)
        text = response.read().decode()
        return {'status': response.status, 'data': json.loads(text) if text else None, 'ok': True}
    except HTTPError as e:
        text = e.read().decode()
        try:
            data = json.loads(text)
        except:
            data = {'error': text}
        return {'status': e.code, 'data': data, 'ok': False}

def provision_account(token):
    """Step 1: Create Analytics account ticket"""
    print('=== Step 1: Creating Analytics Account Ticket ===\n')
    
    url = 'https://analyticsadmin.googleapis.com/v1beta/accounts:provisionAccountTicket'
    body = {
        'account': {
            'displayName': 'OpenClaw Mobile Studio',
            'regionCode': 'US'
        },
        'redirectUri': 'https://analytics.google.com'
    }
    
    r = api_call('POST', url, token, body)
    
    if not r['ok']:
        print(f"❌ Failed to create account ticket: {r['status']}")
        print(json.dumps(r['data'], indent=2))
        return None
    
    account_ticket_id = r['data'].get('accountTicketId')
    if not account_ticket_id:
        print('❌ No accountTicketId in response')
        print(json.dumps(r['data'], indent=2))
        return None
    
    tos_url = f'https://analytics.google.com/analytics/web/?provisioningSignup=false#/termsofservice/{account_ticket_id}'
    
    print('✅ Account ticket created!')
    print(f'Account Ticket ID: {account_ticket_id}')
    print()
    print('=' * 70)
    print('⚠️  MANUAL STEP REQUIRED')
    print('=' * 70)
    print()
    print('Please visit this URL to accept Google Analytics Terms of Service:')
    print()
    print(f'  {tos_url}')
    print()
    print('After accepting the TOS, the Analytics account will be created.')
    print('Then run this script again with: --complete-setup')
    print()
    
    # Save ticket ID for later
    with open('/tmp/analytics_ticket.json', 'w') as f:
        json.dump({'ticketId': account_ticket_id, 'tosUrl': tos_url}, f)
    
    return account_ticket_id

def list_accounts(token):
    """List available Analytics accounts"""
    print('=== Listing Analytics Accounts ===\n')
    
    url = 'https://analyticsadmin.googleapis.com/v1beta/accounts'
    r = api_call('GET', url, token)
    
    if not r['ok']:
        print(f"Error: {r['status']}")
        print(json.dumps(r['data'], indent=2))
        return []
    
    accounts = r['data'].get('accounts', [])
    
    if not accounts:
        print('No Analytics accounts found.')
        return []
    
    print(f'Found {len(accounts)} account(s):')
    for acc in accounts:
        name = acc.get('name', '')
        display_name = acc.get('displayName', 'Unnamed')
        print(f'  - {display_name} ({name})')
    
    return accounts

def create_ga4_property(token, account_name):
    """Step 2: Create GA4 property under the account"""
    print(f'\n=== Step 2: Creating GA4 Property ===\n')
    
    url = 'https://analyticsadmin.googleapis.com/v1beta/properties'
    body = {
        'parent': account_name,
        'displayName': APP_NAME,
        'industryCategory': 'EDUCATION',
        'timeZone': 'America/Chicago',
        'currencyCode': 'USD',
        'propertyType': 'PROPERTY_TYPE_ORDINARY'
    }
    
    r = api_call('POST', url, token, body)
    
    if not r['ok']:
        print(f"❌ Failed to create property: {r['status']}")
        print(json.dumps(r['data'], indent=2))
        return None
    
    property_name = r['data'].get('name')
    property_id = property_name.split('/')[-1]
    
    print(f'✅ GA4 Property created: {property_id}')
    return property_name

def create_ios_stream(token, property_name):
    """Step 3: Create iOS data stream"""
    print(f'\n=== Step 3: Creating iOS Data Stream ===\n')
    
    url = f'https://analyticsadmin.googleapis.com/v1beta/{property_name}/dataStreams'
    body = {
        'displayName': f'{APP_NAME} - iOS',
        'type': 'IOS_APP_DATA_STREAM',
        'iosAppStreamData': {
            'bundleId': BUNDLE_ID
        }
    }
    
    r = api_call('POST', url, token, body)
    
    if not r['ok']:
        print(f"❌ Failed to create data stream: {r['status']}")
        print(json.dumps(r['data'], indent=2))
        return None
    
    stream_name = r['data'].get('name')
    stream_id = stream_name.split('/')[-1]
    measurement_id = r['data'].get('iosAppStreamData', {}).get('firebaseAppId') or stream_id
    
    print(f'✅ iOS Data Stream created: {stream_id}')
    print(f'Measurement ID: {measurement_id}')
    
    return r['data']

def link_firebase_to_analytics(token, property_name):
    """Step 4: Link Firebase project to Analytics"""
    print(f'\n=== Step 4: Linking Firebase to Analytics ===\n')
    
    # Use Firebase Management API to link Analytics
    property_id = property_name.split('/')[-1]
    
    url = f'https://firebase.googleapis.com/v1beta1/projects/{PROJECT_ID}:addGoogleAnalytics'
    body = {
        'analyticsPropertyId': property_id
    }
    
    r = api_call('POST', url, token, body)
    
    if not r['ok']:
        print(f"⚠️  Link may already exist or requires different approach: {r['status']}")
        print(json.dumps(r['data'], indent=2))
        return False
    
    print('✅ Firebase linked to Analytics!')
    
    # Check operation status
    if 'name' in r['data']:
        operation_name = r['data']['name']
        print(f'Operation: {operation_name}')
        
        # Poll for completion
        for i in range(10):
            time.sleep(2)
            url = f'https://firebase.googleapis.com/v1beta1/{operation_name}'
            status = api_call('GET', url, token)
            
            if status['ok'] and status['data'].get('done'):
                print('✅ Link operation complete!')
                return True
            
            print(f'  Waiting... ({i+1}/10)')
        
        print('⏳ Operation still in progress')
    
    return True

def complete_setup(token):
    """Complete setup after TOS acceptance"""
    # List accounts to find the newly created one
    accounts = list_accounts(token)
    
    if not accounts:
        print('\n❌ No Analytics accounts found.')
        print('Please ensure you accepted the TOS at the URL provided.')
        return False
    
    # Use the most recent account (likely the one just created)
    # Or look for "OpenClaw Mobile Studio"
    account = None
    for acc in accounts:
        if 'OpenClaw Mobile Studio' in acc.get('displayName', ''):
            account = acc
            break
    
    if not account:
        account = accounts[-1]  # Use last account (most recent)
    
    account_name = account['name']
    print(f'\n✅ Using account: {account["displayName"]} ({account_name})')
    
    # Create GA4 property
    property_name = create_ga4_property(token, account_name)
    if not property_name:
        return False
    
    # Create iOS stream
    stream_data = create_ios_stream(token, property_name)
    if not stream_data:
        return False
    
    # Link to Firebase
    link_firebase_to_analytics(token, property_name)
    
    print('\n' + '=' * 70)
    print('✅ SETUP COMPLETE!')
    print('=' * 70)
    print()
    print(f'Analytics Property: {property_name}')
    print(f'iOS Data Stream: {stream_data.get("name")}')
    print()
    print('Analytics will start collecting data from the next app launch.')
    print(f'View at: https://analytics.google.com/analytics/web/#/p{property_name.split("/")[-1]}/reports/intelligenthome')
    
    return True

def main():
    token = get_access_token()
    
    if len(sys.argv) > 1 and sys.argv[1] == '--complete-setup':
        # User accepted TOS, complete the setup
        success = complete_setup(token)
        sys.exit(0 if success else 1)
    else:
        # Step 1: Create account ticket
        ticket_id = provision_account(token)
        if ticket_id:
            print('Save this ticket ID:', ticket_id)
            sys.exit(0)
        else:
            sys.exit(1)

if __name__ == '__main__':
    main()
