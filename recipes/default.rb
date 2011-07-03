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

redmine = Chef::EncryptedDataBagItem.load("apps", "redmine")
smtp = Chef::EncryptedDataBagItem.load("apps", "smtp")

redmine_url = redmine["redmine_url"]
redmine_path = "/srv/rails/#{redmine_url}"

package "memcached"

gem_package "postgres-pr"
gem_package "taps"
gem_package "rails" do
  version "2.3.11"
end
gem_package "i18n" do
  version "0.4.2"
end
package "libmagickwand-dev"
gem_package "rmagick"

passenger_nginx_vhost redmine_url

postgresql_user "redmine" do
  password "redmine"
end

postgresql_db "redmine_production" do
  owner "redmine"
end

directories = [
                "#{redmine_path}/shared/config","#{redmine_path}/shared/log",
                "#{redmine_path}/shared/system","#{redmine_path}/shared/pids",
                "#{redmine_path}/shared/config/environments","/var/redmine/files"
              ]
directories.each do |dir|
  directory dir do
    owner "nginx"
    group "nginx"
    mode "0755"
    recursive true
  end
end

cookbook_file "#{redmine_path}/shared/config/environments/production.rb" do
  source "production.rb"
  owner "nginx"
  group "nginx"
  mode "0400"
end

template "#{redmine_path}/shared/config/database.yml" do
  source "database.yml.erb"
  owner "nginx"
  group "nginx"
  mode "0400"
  variables({
    :db_adapter => redmine["db_adapter"],
    :db_name => redmine["db_name"],
    :db_host => redmine["db_host"],
    :db_user => redmine["db_user"],
    :db_password => redmine["db_password"]
  })
end

template "#{redmine_path}/shared/config/configuration.yml" do
  source "configuration.yml.erb"
  owner "nginx"
  group "nginx"
  mode "0400"
  variables({
    :smtp_host => smtp["smtp_host"],
    :domain => smtp["domain"],
    :port => smtp["port"],
    :attachments_path => redmine["attachments_path"]
  })
end

deploy_revision "#{redmine_path}" do
  repo "git://github.com/edavis10/redmine.git"
  revision "1.2.0" # or "HEAD" or "TAG_for_1.0" or (subversion) "1234"
  user "nginx"
  enable_submodules true
  before_migrate do
    execute "rake generate_session_store" do
      user 'nginx'
      group 'nginx'
      cwd release_path
    end
  end
  migrate true
  migration_command "rake db:migrate"
  symlink_before_migrate ({
                          "config/database.yml" => "config/database.yml",
                          "config/configuration.yml" => "config/configuration.yml",
                          "config/environments/production.rb" => "config/environments/production.rb"
                         })
  before_symlink do
    execute "rake redmine:load_default_data" do
      user 'nginx'
      group 'nginx'
      cwd release_path
      environment "RAILS_ENV" => "production", "REDMINE_LANG" => "en"
    end
  end
  environment "RAILS_ENV" => "production"
  action :deploy # or :rollback
  restart_command "touch tmp/restart.txt"
end
