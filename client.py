#!/usr/bin/env python3

import os
import sys
import ssl
import urllib.request
import json

def main():
    # Get configuration from environment variables
    hostname = os.getenv('KUBERNETES_HOSTNAME', 'kubernetes')
    ca_cert_path = os.getenv('KUBERNETES_CA_CERT', 'certs/1.16/ca.crt')
    verify_x509_strict = os.getenv('VERIFY_X509_STRICT', 'true').lower() in ('true', '1', 'yes')
    verify_x509_partial_chain = os.getenv('VERIFY_X509_PARTIAL_CHAIN', 'true').lower() in ('true', '1', 'yes')
    
    # Debug print
    print(f"Using CA certificate at: {ca_cert_path}", file=sys.stderr)
    print(f"File exists: {os.path.exists(ca_cert_path)}", file=sys.stderr)
    if os.path.exists(ca_cert_path):
        print(f"File is readable: {os.access(ca_cert_path, os.R_OK)}", file=sys.stderr)
    
    # Create SSL context with custom CA
    context = ssl.create_default_context()
    context.load_verify_locations(cafile=ca_cert_path)
    
    # Optionally disable VERIFY_X509_STRICT
    if not verify_x509_strict:
        context.verify_flags &= ~ssl.VERIFY_X509_STRICT
        print("VERIFY_X509_STRICT has been disabled", file=sys.stderr)
    if not verify_x509_partial_chain:
        context.verify_flags &= ~ssl.VERIFY_X509_PARTIAL_CHAIN
        print("VERIFY_X509_PARTIAL_CHAIN has been disabled", file=sys.stderr)
    
    # Create the URL
    url = f'https://{hostname}/'
    
    try:
        # Make the request
        with urllib.request.urlopen(url, context=context) as response:
            data = json.loads(response.read().decode())
            print(json.dumps(data, indent=2))
    except urllib.error.URLError as e:
        print(f"Error connecting to {url}: {e}", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Error decoding response: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main() 