import sys
import requests

from requests.packages import urllib3
from com.vmware import nsx_policy_client
from vmware.vapi.bindings.stub import ApiClient
from vmware.vapi.bindings.stub import StubFactory
from vmware.vapi.lib import connect
from vmware.vapi.security.user_password import create_user_password_security_context
from vmware.vapi.stdlib.client.factories import StubConfigurationFactory
from com.vmware.nsx_policy.model_client import Segment
from com.vmware.nsx_policy.model_client import SegmentSubnet

def nsx_create_client(nsx_user, nsx_password, nsx_endpoint, nsx_host, nsx_port):
    """Create NSX client for a given endpoint (nsx_endpoint, nsx_policy_client)"""
    session = requests.session()
    session.verify = False
    urllib3.disable_warnings()

    connector = connect.get_requests_connector(
        session=session, msg_protocol='rest', url=f'https://{nsx_host}:{nsx_port}')
    stub_config = StubConfigurationFactory.new_runtime_configuration(
        connector, response_extractor=True)
    security_context = create_user_password_security_context(
        nsx_user, nsx_password)
    connector.set_security_context(security_context)

    stub_factory = nsx_endpoint.StubFactory(stub_config)

    return ApiClient(stub_factory)


def nsx_create_segment(nsx_client, segment_name, gateway_cidr, transport_zone_id, router_id):
    """Create NSX Segment"""
    subnet = SegmentSubnet(gateway_address=gateway_cidr)
    segment = Segment(transport_zone_path=transport_zone_id,
                      connectivity_path=router_id,
                      display_name=segment_name,
                      subnets=[subnet])
    nsx_client.infra.Segments.update(segment_name, segment)


def main(network_name, gateway_cidr):

    nsxMgrUrl = 'nsx-mgmt.vcf.sddc.lab'
    nsxMgrAdmin = 'admin'
    nsxMgrPassword = 'VMware123!VMware123!'
    t0Gateway = 'VLC-Tier-0'
    transportZoneId = '6a781f84-516e-4be6-afac-0a7d8abbfabf'

    """End to end segment creation with hardcoded HOL values"""
    print('Connecting to NSX Manager...')
    client = nsx_create_client(nsx_user=nsxMgrAdmin,
                               nsx_password=nsxMgrPassword,
                               nsx_endpoint=nsx_policy_client,
                               nsx_host=nsxMgrUrl, nsx_port=443)

    if network_name and gateway_cidr:
        print(f"Creating Network segment {network_name} - {gateway_cidr}")
        nsx_create_segment(client, network_name, gateway_cidr,
                           f'/infra/sites/default/enforcement-points/default/transport-zones/{transportZoneId}',
                           f'/infra/tier-0s/{t0Gateway}')
    else:
        raise Exception(
            'No value for Segment name or Gateway. Segment not created')


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
