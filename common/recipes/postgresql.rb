# these commands are temporal solution until the package is included in the main repository.
# See: https://forums.aws.amazon.com/thread.jspa?threadID=174328

# install packages required by PostGIS.
%w{gdal proj-devel json-c}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

bash 'add a repository and install postgresql 9.5' do
  code <<-EOC
  rpm -ivh https://download.postgresql.org/pub/repos/yum/9.5/redhat/rhel-6-x86_64/pgdg-ami201503-95-9.5-3.noarch.rpm
  yum-config-manager --disable pgdg95
  yum erase -y postgresql92 postgresql92-devel postgresql92-libs postgresql93 postgresql93-devel postgresql93-libs
  yum --disablerepo="*" --enablerepo="pgdg95" --releasever="6" install -y postgresql95-devel postgis2_95
  EOC
end

# set permanent global PATH variable for postgresql.
cookbook_file "/etc/profile.d/pgsql.sh" do
  source "pgsql.sh"
end
# set it temporarily.
ENV['PATH'] += ":/usr/pgsql-9.5/bin"
