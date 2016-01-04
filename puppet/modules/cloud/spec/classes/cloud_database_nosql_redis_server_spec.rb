#
# Copyright (C) 2014 eNovance SAS <licensing@enovance.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# Unit tests for cloud::cache::redis::server
#

require 'spec_helper'

describe 'cloud::database::nosql::redis::server' do

  shared_examples_for 'redis server' do

    let :params do
      { :port => '6379' }
    end

    it { should create_class('redis') }

    context 'with default firewall enabled' do
      let :pre_condition do
        "class { 'cloud': manage_firewall => true }"
      end
      it 'configure redis firewall rules' do
        is_expected.to contain_firewall('100 allow redis server access').with(
          :port   => '6379',
          :proto  => 'tcp',
          :action => 'accept',
        )
      end
    end

    context 'with custom firewall enabled' do
      let :pre_condition do
        "class { 'cloud': manage_firewall => true }"
      end
      before :each do
        params.merge!(:firewall_settings => { 'limit' => '50/sec' } )
      end
      it 'configure redis firewall rules with custom parameter' do
        is_expected.to contain_firewall('100 allow redis server access').with(
          :port   => '6379',
          :proto  => 'tcp',
          :action => 'accept',
          :limit  => '50/sec',
        )
      end
    end

  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    it_configures 'redis server'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    it_configures 'redis server'
  end

end
