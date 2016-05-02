default['app']['owner'] = "ec2-user"
default['app']['group'] = "ec2-user"
default['app']['revision'] = 'master'
default['nginx']['cookbook'] = 'nginx'
default['nginx']['keepalive'] = 'on'
default['nginx']['keepalive_timeout'] = 2
default['gunicorn']['worker_max_requests'] = 8192
default['gunicorn']['worker_timeout'] = 60
