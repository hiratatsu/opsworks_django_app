include_recipe 'common::virtualenv'

# install required packages.
%w{libmemcached libmemcached-devel npm libjpeg-devel pandoc}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

# install grunt-cli
bash 'npm install -g grunt-cli' do
  code <<-EOC
  npm install -g grunt-cli
  EOC
end

include_recipe 'common::postgresql'

include_recipe 'common::postfix'

include_recipe 'common::repository'

app_directory = "#{node[:app][:directory]}/#{node[:app][:host]}"
# place credential files. (downloadcertificate command needs these files.)
template "#{app_directory}/#{node[:app][:name]}/#{node[:app][:name]}/settings/settings_base_credential.py" do
  source 'settings_base_credential.py.erb'
  owner node[:app][:owner]
  group node[:app][:group]
  action :create
end
template "#{app_directory}/#{node[:app][:name]}/#{node[:app][:name]}/settings/#{node[:app][:credential]}" do
  source 'settings_env_credential.py.erb'
  owner node[:app][:owner]
  group node[:app][:group]
  action :create
end

# keyczar is needed to run manage.py.
include_recipe 'common::keyczar'

# create APNs certificates directory first.
directory File.dirname("#{app_directory}/#{node[:apns][:key_path]}") do
  owner node[:app][:owner]
  group node[:app][:group]
  mode '0755'
  recursive true
  action :create
  not_if { ::File.exists?(File.dirname("#{app_directory}/#{node[:apns][:key_path]}")) }
end

# install APNs key
s3_file "#{app_directory}/#{node[:apns][:key_path]}" do
  remote_path node[:apns][:key_s3]
  aws_access_key_id node[:aws][:key]
  aws_secret_access_key node[:aws][:secret]
  bucket node[:aws][:s3_bucket]
  owner node[:app][:owner]
  group node[:app][:group]
  mode 0644
  not_if { ::File.exists?("#{app_directory}/#{node[:apns][:key_path]}") }
end

# downloadcertificate
bash "manage.py" do
  cwd "#{app_directory}/#{node[:app][:name]}"
  user node[:app][:owner]
  group node[:app][:group]
  code "#{node[:virtualenv][:path]}/bin/python manage.py downloadcertificate --settings=#{node[:app][:django_settings]}"
end

# supervisor must be called before gunicorn and celeryd.
include_recipe 'supervisor'

include_recipe 'common::gunicorn'

include_recipe 'common::celeryd'

include_recipe 'common::dynamic_dynamodb'

include_recipe 'common::nginx'

# install additional nginx config.
cookbook_file "/etc/nginx/conf.d/security.conf" do
  source "nginx-security.conf"
end

# install api site-config
unless node[:app][:api_host].empty?
  nginx_web_app node[:app][:api_host] do
    cookbook node[:nginx][:cookbook]
    template 'nginx_site_api.erb'
  end
end

include_recipe 'common::td-agent'
# configuration
template "/etc/td-agent/td-agent.conf" do
  source 'td-agent.conf.erb'
  action :create
  # no need to notify since the template is subscribed.
end
