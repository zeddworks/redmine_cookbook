#
# Cookbook Name:: redmine
# Recipe:: default
#
# Copyright 2011, ZeddWorks
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

system "gem update --system 1.4.2"

gem_package "mysql" do
  action :install
end

rvm_wrapper "update rvm wrappers" do
  ruby_string "ree-1.8.7-2011.03"
  action :create
end
