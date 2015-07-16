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

directory('/etc/chef/ohai').run_action(:create)
directory('/etc/chef/ohai/hints').run_action(:create)
file('/etc/chef/ohai/hints/softlayer.json').run_action(:create)
file '/etc/chef/ohai/hints/softlayer_test.json' do
  content({'primary_ip_address' => '1.2.3.4'}.to_json)
end.run_action(:create)

include_recipe 'ohai-softlayer'

file '/softlayer.json' do
  content node['softlayer'].to_json
end

file '/cloud.json' do
  content node['cloud'].to_json
end

file '/cloud_v2.json' do
  content node['cloud_v2'].to_json
end
