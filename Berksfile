source "https://supermarket.chef.io"

# opsworks depends on ohai and the newer versions are not compatible with Chef 11.
cookbook 'ohai', '= 3.0.1'
# apt 4.0.0 breaks backward compatibility with Chef 11.
cookbook 'apt', '= 3.0.0'
# build-essential 2.3.0 contains bug.
cookbook 'build-essential', '= 2.2.4'
cookbook 'python'
# 2014-07-31
cookbook 'supervisor', github: 'poise/supervisor', ref: 'e5ad4bf21c2aa4dc56e7bad84b836d897a87dedf'
cookbook 'gunicorn'
cookbook 'td-agent', github: 'treasure-data/chef-td-agent', ref: '7a0fb20d56e620d04dac3c6d547734a398d2dff6'
cookbook 'postfix'
