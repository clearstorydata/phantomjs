#
# Cookbook Name:: phantomjs
# Recipe:: default
#
# Copyright 2012-2013, Seth Vargo (sethvargo@gmail.com)
# Copyright 2012-2013, CustomInk
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# External recipes
include_recipe 'build-essential::default'

# Internal recipes
include_recipe 'phantomjs::structure'

# Install supporting packages
node['phantomjs']['packages'].each { |name| package name }

version  = node['phantomjs']['version']
base_url = node['phantomjs']['base_url']
src_dir  = node['phantomjs']['src_dir']

# We need to have different binaries for different flavors of linux.
# PhantomJS doesn't suppiort this natively, so we need to fudge it a bit
# in order to support mutiple linuxes at the same time.
codename = ( node['lsb'] || {} )['codename'] || 'linux'
os = %w(trusty precise).include?(codename) ? codename : 'linux'
basename = "phantomjs-#{node['phantomjs']['version']}-#{os}-#{node['kernel']['machine']}"
checksum = node['phantomjs']['checksum']

remote_file "#{src_dir}/#{basename}.tar.bz2" do
  owner     'root'
  group     'root'
  mode      '0644'
  backup    false
  source    "#{base_url}/#{basename}.tar.bz2"
  checksum  checksum if checksum
  not_if    { ::File.exists?('/usr/local/bin/phantomjs') && `/usr/local/bin/phantomjs --version`.chomp == version } # ~FC048
  notifies  :run, 'execute[phantomjs-install]', :immediately
end

execute 'phantomjs-install' do
  command   "tar -xvjf #{src_dir}/#{basename}.tar.bz2 -C /usr/local/"
  action    :nothing
  notifies  :create, 'link[phantomjs-link]', :immediately
end

link 'phantomjs-link' do
  target_file   '/usr/local/bin/phantomjs'
  to            "/usr/local/#{basename}/bin/phantomjs"
  owner         'root'
  group         'root'
  action        :nothing
end
