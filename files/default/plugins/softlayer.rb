#
# Copyright 2014-2015, Noah Kantrowitz
# Copyright 2014, BitPusher LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'ffi_yajl'
require 'net/http'

Ohai.plugin(:SoftLayer) do
  provides "softlayer"

  SOFTLAYER_METADATA_ADDR = 'api.service.softlayer.com'
  SOFTLAYER_METADATA_API = '/rest/v3/SoftLayer_Resource_Metadata/'
  SOFTLAYER_METADATA_KEYS = %w{
    backend_mac_addresses
    datacenter
    datacenter_id
    domain
    frontend_mac_addresses
    fully_qualified_domain_name
    hostname
    id
    primary_backend_ip_address
    primary_ip_address
    provision_state
    tags
    user_metadata
    service_resource
    service_resources
  }
  SOFTLAYER_NETWORK_METADATA_KEYS = %w{
    router
    vlan_ids
    vlans
  }

  # For bare metal there is no way to auto-detect
  # TODO: Check the MACs on SoftLayer Virtual
  def looks_like_softlayer?
    hint?('softlayer')
  end

  def softlayey_key(key, param=nil)
    'get' + key.split('_').map(&:capitalize!).join('') + (param ? '/'+param : '') + '.json'
  end

  def http_client
    Net::HTTP.start(SOFTLAYER_METADATA_ADDR, 443,
      read_timeout: 600,
      use_ssl: true,
      verify_mode: OpenSSL::SSL::VERIFY_PEER,
    )
  end

  def retreive_key(key, param=nil)
    return hint?('softlayer_test')[key] if hint?('softlayer_test') # Testing hook
    path = SOFTLAYER_METADATA_API + softlayey_key(key, param)
    Ohai::Log.debug("Reteiving SoftLayer metadata from https://#{SOFTLAYER_METADATA_ADDR}#{path}")
    response = http_client.get(path)
    softlayer[key] = case response.code
    when '200'
      begin
        # ffi-yajl can't parse simple values so wrap in an array for now.
        # Pending https://github.com/opscode/ffi-yajl/issues/16
        FFI_Yajl::Parser.parse('[' + response.body + ']').first
      rescue FFI_Yajl::ParseError => e
        response.body
      end
    when '404', '422', '500'
      Ohai::Log.debug("Encountered #{response.code} response retreiving SoftLayer metadata path: #{key} ; continuing.")
      nil
    else
      Ohai::Log.error("Encountered error retrieving SoftLayer metadata (#{key} returned #{response.code} response)")
      nil
    end
  end

  collect_data do
    if looks_like_softlayer?
      Ohai::Log.debug("looks_like_softlayer? == true")
      softlayer Mash.new
      SOFTLAYER_METADATA_KEYS.each do |key|
        softlayer[key] = retreive_key(key)
      end
      mac_addresses = ((softlayer[:frontend_mac_addresses] || []) + (softlayer[:backend_mac_addresses] || [])).uniq
      Ohai::Log.debug("Found MAC addresses: #{mac_addresses.join(', ')}")
      SOFTLAYER_NETWORK_METADATA_KEYS.each do |key|
        softlayer[key] = mac_addresses.inject({}) do |memo, mac|
          memo[mac] = retreive_key(key, mac)
          memo
        end
      end
      # Standard keys to make life a little easier
      softlayer[:public_ipv4] = softlayer[:primary_ip_address]
      softlayer[:local_ipv4] = softlayer[:primary_backend_ip_address]
    end
  end

end
