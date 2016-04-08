# these commands are temporal solution until the package is included in the main repository.
# See: https://forums.aws.amazon.com/thread.jspa?threadID=174328

# install packages required by PostGIS.
%w{gdal proj-devel json-c}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

bash 'add a repository and install postgresql 9.4' do
  code <<-EOC
  rpm -ivh http://yum.postgresql.org/9.4/redhat/rhel-7-x86_64/pgdg-redhat94-9.4-2.noarch.rpm
  yum-config-manager --disable pgdg94
  yum erase -y postgresql92 postgresql92-devel postgresql92-libs postgresql93 postgresql93-devel postgresql93-libs
  yum --disablerepo="*" --enablerepo="pgdg94" --releasever="7" install -y postgresql94-devel postgis2_94
  EOC
end

# set permanent global PATH variable for postgresql.
cookbook_file "/etc/profile.d/pgsql.sh" do
  source "pgsql.sh"
end
# set it temporarily.
ENV['PATH'] += ":/usr/pgsql-9.4/bin"