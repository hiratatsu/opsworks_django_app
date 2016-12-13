include_recipe 'gunicorn'

# disable multi-thread until DB-lock issues go away. 
# pip install required packages for threading in python 2.7.
#bash "pip install futures trollius" do
#  code <<-EOC
#  #{node[:virtualenv][:path]}/bin/pip install futures trollius
#  EOC
#end

app_directory = "#{node[:app][:directory]}/#{node[:app][:host]}"
gunicorn_config_path = "/etc/gunicorn/#{node[:app][:name]}.py"

gunicorn_config gunicorn_config_path do
  listen '127.0.0.1:8000'
  worker_processes (node['cpu'] && node['cpu']['total']) && [node['cpu']['total'].to_i * 4, 4].max || 4
  worker_max_requests node['gunicorn']['worker_max_requests']
  worker_timeout node['gunicorn']['worker_timeout']
#  threads (node['cpu'] && node['cpu']['total']) && [node['cpu']['total'].to_i * 2 + 1, 12].min || 4
  action :create
end

# supervisor config for gunicorn
supervisor_service "gunicorn-#{node[:app][:name]}" do
  command "#{::File.join(node[:virtualenv][:path], 'bin', 'gunicorn')} #{node[:app][:wsgi]} -c #{gunicorn_config_path}"
  autostart true
  autorestart true
  startsecs 10
  user node[:app][:owner]
  directory "#{app_directory}/#{node[:app][:name]}"
  stderr_logfile "#{node[:supervisor][:log_dir]}/gunicorn-#{node[:app][:name]}-stderr.log"
end
