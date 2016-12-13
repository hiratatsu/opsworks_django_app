app_directory = "#{node[:app][:directory]}/#{node[:app][:host]}"

# deploy git repository.
git app_directory do
  repository node[:app][:repository]
  revision node[:app][:revision]
  user node[:app][:owner]
  group node[:app][:group]
  ssh_wrapper node[:sshignorehost][:path]
  action :sync
end

# update credential files.
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

# pip install
bash "pip install -r requirements.txt" do
  cwd app_directory
  user node[:app][:owner]
  group node[:app][:group]
  code <<-EOC
  export HOME=~#{node[:app][:owner]}
  export PATH=$PATH:/usr/pgsql-9.5/bin
  #{node[:virtualenv][:path]}/bin/pip install -r requirements.txt
  EOC
end

# install compilers of less and coffeescript.
bash 'npm install --production' do
  cwd app_directory
  code <<-EOC
  npm install --production
  EOC
end

# grunt deploy
bash "grunt #{node[:app][:grunt_target]}" do
  cwd app_directory
  code <<-EOC
  grunt #{node[:app][:grunt_target]}
  EOC
end

# collectstatic, migrate
bash "manage.py" do
  cwd "#{app_directory}/#{node[:app][:name]}"
  user node[:app][:owner]
  group node[:app][:group]
  code "#{node[:virtualenv][:path]}/bin/python manage.py collectstatic --noinput --settings=#{node[:app][:django_settings]} && " +
       "#{node[:virtualenv][:path]}/bin/python manage.py migrate --settings=#{node[:app][:django_settings]}"
end

# start or reload gunicorn depending on the current status.
if `supervisorctl status gunicorn-#{node[:app][:name]} | awk '{print $2}'` =~ /^RUNNING$/
  # reload it.
  bash "reload gunicorn" do
    code <<-EOC
    supervisorctl status gunicorn-#{node[:app][:name]} | awk '{gsub(/,$/, "", $4); print $4}' | xargs kill -HUP
    EOC
  end
else
  # or start it.
  supervisor_service "gunicorn-#{node[:app][:name]}" do
    action :restart
  end
end

# start or reload celeryd depending on the current status.
if `supervisorctl status celeryd-#{node[:app][:name]} | awk '{print $2}'` =~ /^RUNNING$/
  # reload it.
  bash "reload celeryd" do
    code <<-EOC
    supervisorctl status celeryd-#{node[:app][:name]} | awk '{gsub(/,$/, "", $4); print $4}' | xargs kill -HUP
    EOC
  end
else
  # or start it.
  supervisor_service "celeryd-#{node[:app][:name]}" do
    action :restart
  end
end
