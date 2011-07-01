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

gem_package "postgres-pr"
gem_package "rails" do
  version "2.3.11"
end
gem_package "i18n" do
  version "0.4.2"
end

passenger_nginx_vhost "redmine.zeddworks.com"

postgresql_user "redmine" do
  password "redmine"
end

postgresql_db "redmine_production" do
  owner "redmine"
end

directories = [ "/srv/rails/redmine/shared/config", "/srv/rails/redmine/shared/log" ]
directories.each do |dir|
  directory dir do
    owner "nginx"
    group "nginx"
    mode "0755"
    recursive true
  end
end

cookbook_file "/srv/rails/redmine/shared/config/database.yml" do
  source "database.yml"
  owner "nginx"
  group "nginx"
  mode "0400"
end

deploy_revision "/srv/rails/redmine" do
  repo "git://github.com/edavis10/redmine.git"
  revision "1.2.0" # or "HEAD" or "TAG_for_1.0" or (subversion) "1234"
  user "nginx"
  enable_submodules true
  before_migrate do
    execute "rake generate_session_store" do
      cwd release_path
    end
  end
  migrate true
  migration_command "rake db:migrate"
  before_symlink do
    execute "rake redmine:load_default_data" do
      cwd release_path
      environment "RAILS_ENV" => "production", "REDMINE_LANG" => "en"
    end
  end
  environment "RAILS_ENV" => "production"
  action :deploy # or :rollback
  restart_command "touch tmp/restart.txt"
end

gem_package "aasm"

redmine_kanban_path = "/srv/rails/redmine/current/vendor/plugins"

git "#{redmine_kanban_path}/redmine_kanban" do
  repository "git://github.com/edavis10/redmine_kanban.git"
  reference "v0.2.0"
  user 'nginx'
  group 'nginx'
  action :checkout
end

execute "migrate_plugins" do
  command "rake db:migrate_plugins"
  cwd redmine_kanban_path
  environment 'RAILS_ENV' => "production"
end
