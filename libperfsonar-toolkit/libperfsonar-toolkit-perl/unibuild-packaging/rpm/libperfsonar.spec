%define install_base /usr/lib/perfsonar/
%define config_base  /etc/perfsonar

%define perfsonar_auto_version 5.0.0
%define perfsonar_auto_relnum 0.b1.1

Name:      	libperfsonar-toolkit-perl
Version:      %{perfsonar_auto_version}
Release:      %{perfsonar_auto_relnum}%{?dist}
Summary:      Shared libraries for perfSONAR Toolkit distributions
License:      ASL 2.0
Group:      	Development/Libraries
URL:      	http://www.perfsonar.net
Source0:      %{name}-%{version}.tar.gz
BuildArch:      noarch
Requires:       perl(CGI)
Requires:       perl(CGI::Ajax)
Requires:       perl(CGI::Carp)
Requires:       perl(CGI::Session)
Requires:       perl(Carp)
Requires:       perl(Class::MOP::Class)
Requires:       perl(Config::General)
Requires:       perl(DBI)
Requires:       perl(Data::Dumper)
Requires:       perl(Data::UUID)
Requires:       perl(Data::Validate::Domain)
Requires:       perl(Data::Validate::IP)
Requires:       perl(DateTime)
Requires:       perl(DateTime::Format::ISO8601)
Requires:       perl(Digest::MD5)
Requires:       perl(English)
Requires:       perl(Exporter)
Requires:       perl(File::Basename)
Requires:       perl(File::Path)
Requires:       perl(File::Spec)
Requires:       perl(File::Temp)
Requires:       perl(IO::File)
Requires:       perl(IO::Select)
Requires:       perl(IO::Socket::SSL)
Requires:       perl(IO::Socket::INET6)
Requires:       perl(IPC::Open3)
Requires:       perl(IPC::Run)
Requires:       perl(JSON)
Requires:       perl(JSON::XS)
Requires:       perl(Log::Log4perl)
Requires:       perl(Math::Int64)
Requires:       perl(Module::Load)
Requires:       perl(Moose)
Requires:       perl(Net::CIDR)
Requires:       perl(Net::DNS)
Requires:       perl(Net::IP)
Requires:       perl(Net::NTP)
Requires:       perl(Net::Server)
Requires:       perl(Net::Traceroute)
Requires:       perl(NetAddr::IP)
Requires:       perl(POSIX)
Requires:       perl(Params::Validate)
Requires:       perl(RPC::XML)
Requires:       perl(RPC::XML::Client)
Requires:       perl(RPC::XML::Server)
Requires:       perl(RPM2)
Requires:       perl(Regexp::Common)
Requires:       perl(Scalar::Util)
Requires:       perl(Socket)
Requires:       perl(Socket6)
Requires:       perl(Statistics::Descriptive)
Requires:       perl(Storable)
Requires:       perl(Symbol)
Requires:       perl(Sys::Hostname)
Requires:       perl(Sys::Statistics::Linux)
Requires:       perl(Template)
Requires:       perl(Template::Filters)
Requires:       perl(Time::HiRes)
Requires:       perl(URI)
Requires:       perl(URI::Split)
Requires:       perl(XML::LibXML)
Requires:       perfsonar-common
Requires:       libperfsonar-perl
Requires:       libperfsonar-sls-perl
Requires:       libperfsonar-regulartesting-perl
Requires:       perfsonar-psconfig-pscheduler-devel
Obsoletes:      perl-perfSONAR_PS-Toolkit-Library
Obsoletes:      perl-perfSONAR_PS-serviceTest
Obsoletes:      perl-perfSONAR_PS-Toolkit
Obsoletes:      perl-perfSONAR-graphs
Obsoletes:      perl-perfSONAR_PS-MeshConfig-Shared
Obsoletes:      perl-perfSONAR_PS-LSRegistrationDaemon

%description
Shared libraries for perfSONAR Toolkit distributions

%pre
/usr/sbin/groupadd -r perfsonar 2> /dev/null || :
/usr/sbin/useradd -g perfsonar -r -s /sbin/nologin -c "perfSONAR User" -d /tmp perfsonar 2> /dev/null || :

%prep
%setup -q -n %{name}-%{version}

%build

%install
rm -rf %{buildroot}
make ROOTPATH=%{buildroot}/%{install_base} CONFIGPATH=%{buildroot}/%{config_base} install

%clean
rm -rf %{buildroot}

%files toolkit-perl
%license LICENSE
%defattr(0644,perfsonar,perfsonar,0755)
%{install_base}/lib/perfSONAR_PS/NPToolkit/*
%{install_base}/lib/perfSONAR_PS/Web/Sidebar.pm
%{install_base}/lib/perfSONAR_PS/Client/gLS/Keywords.pm
%{install_base}/lib/perfSONAR_PS/Utils/Config/*

%changelog
* Fri Jun 10 2022 andy@es.net 5.0.0-0.1.b1
- Initial spec file
