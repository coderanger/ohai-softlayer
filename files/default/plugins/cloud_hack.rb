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

Ohai.plugin(:CloudHack) do
  provides 'cloud_hack'
  depends "softlayer"
  depends "cloud"
  depends "cloud_v2"

  def on_softlayer?
    softlayer != nil
  end

  def get_values_cloud
    cloud Mash.new unless cloud
    cloud[:public_ips] ||= Array.new
    cloud[:private_ips] ||= Array.new
    cloud[:public_ips] << softlayer['public_ipv4']
    cloud[:private_ips] << softlayer['local_ipv4']
    cloud[:public_ipv4] = softlayer['public_ipv4']
    cloud[:local_ipv4] = softlayer['local_ipv4']
    cloud[:provider] = "softlayer"
  end

  def get_values_cloud_v2
    cloud_v2 Mash.new unless cloud_v2
    cloud_v2[:public_ipv4_addrs] ||= Array.new
    cloud_v2[:local_ipv4_addrs] ||= Array.new
    cloud_v2[:public_ipv4_addrs] << softlayer['public_ipv4']
    cloud_v2[:local_ipv4_addrs] << softlayer['local_ipv4']
    cloud_v2[:public_ipv4] = softlayer['public_ipv4']
    cloud_v2[:local_ipv4] = softlayer['local_ipv4']
    cloud_v2[:provider] = "softlayer"
  end

  collect_data do
    cloud_hack Hash.new
    if on_softlayer?
      get_values_cloud
      get_values_cloud_v2
    end
  end
end
