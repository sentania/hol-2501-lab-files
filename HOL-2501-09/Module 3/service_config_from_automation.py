#!/usr/bin/env python3

import sys
import requests
import json
import urllib3

'''
    Helper script that, given an Automation VA IP or hostname, outputs a YAML configuration containing
    the JWKS and issuer URL to STDOUT, suitable to use as the service configuration YAML when
    installing CCI Supervisor Service on Supervisor.
'''

def print_usage():
    print('''
    Usage: {0} <Automation IP or Hostname>
'''.format(sys.argv[0]))


def get_well_known_config(automation_ip):
    '''
        GET the OIDC well-known configuration endpoint of the Automation VA to get the JWKS URL and the issuer URL.
    '''
    well_known_config_endpoint = "https://{0}/.well-known/openid-configuration".format(automation_ip)
    resp = requests.get(well_known_config_endpoint, verify=False)
    return json.loads(resp.content)

def get_jwks_config(jwks_endpoint):
    '''
        GET the JWKS URI from the OIDC configuration to obtain the public keys for JWT verification.
    '''
    resp = requests.get(jwks_endpoint, verify=False)
    return json.loads(resp.content)

def emit_config(well_known_config, jwks_config):
    '''
        Returns a JSON object suitable for consumption by CCI Service.
    '''
    output_obj = {}
    output_obj['issuer_url'] = well_known_config['issuer']
    output_obj['keyset'] = jwks_config

    return output_obj

def main():
    if len(sys.argv) != 2:
        print_usage()
        sys.exit(1)

    # Disable warnings for self-signed certificates.
    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

    automation_ip = sys.argv[1]
    well_known_config = get_well_known_config(automation_ip)
    jwks_endpoint = well_known_config['jwks_uri']
    jwks_config = get_jwks_config(jwks_endpoint)

    str = json.dumps(emit_config(well_known_config, jwks_config))
    print('''
idpConfig: |
  {0}
'''.format(str))

if __name__ == '__main__':
    main()
