%define install_base /usr/lib/perfsonar/
%define config_base  /etc/perfsonar

%define perfsonar_auto_version 4.3.0
%define perfsonar_auto_relnum 1

Name:			libperfsonar
Version:		%{perfsonar_auto_version}
Release:		%{perfsonar_auto_relnum}%{?dist}
Summary:		perfSONAR Shared Libraries
License:		ASL 2.0
Group:			Development/Libraries
URL:			http://www.perfsonar.net
Source0:		libperfsonar-%{version}.%{perfsonar_auto_relnum}.tar.gz
BuildRoot:		%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:		noarch

%description
perfSONAR shared libraries

%package perl
Summary:        Package common to all perfSONAR tools
Group:          Applications/Communications
Requires:		perl(Carp)
Requires:		perl(Data::Dumper)
Requires:		perl(Data::UUID)
Requires:		perl(Data::Validate::IP)
Requires:		perl(DateTime)
Requires:		perl(DateTime::Duration)
Requires:		perl(DateTime::Format::ISO8601)
Requires:		perl(English)
Requires:		perl(Exporter)
Requires:		perl(Fcntl)
Requires:		perl(File::Basename)
Requires:		perl(IO::File)
Requires:		perl(IO::Select)
Requires:		perl(IO::Socket::SSL)
Requires:       perl(IO::Socket::INET6)
Requires:		perl(IPC::Run3)
Requires:		perl(JSON::XS)
Requires:		perl(Log::Log4perl)
Requires:		perl(Net::CIDR)
Requires:		perl(Net::DNS)
Requires:		perl(Net::IP)
Requires:		perl(IO::Interface)
Requires:		perl(NetAddr::IP)
Requires:		perl(POSIX)
Requires:		perl(Params::Validate)
Requires:		perl(Regexp::Common)
Requires:		perl(Socket)
Requires:		perl(Socket6)
Requires:		perl(Sys::Statistics::Linux)
Requires:		perl(Time::HiRes)
Requires:		perl(URI)
Requires:		perl(URI::Split)
Requires:		perl(URI::URL)
Requires:		perl(XML::LibXML)
Requires:		perl-Mojolicious >= 7.80
Requires:		perfsonar-common
Requires:		iproute
Requires:		jq
%if 0%{?el7}
Requires:		GeoIP-data
%endif
Obsoletes:      perl-perfSONAR_PS-Toolkit
Obsoletes:      perl-perfSONAR_PS-Toolkit-Library
Obsoletes:      perl-perfSONAR_PS-serviceTest
Obsoletes:      perl-perfSONAR_PS-MeshConfig-Shared
Obsoletes:      perl-perfSONAR-graphs
Obsoletes:      perl-perfSONAR_PS-LSRegistrationDaemon
Obsoletes:      perl-perfSONAR_PS-RegularTesting
Obsoletes:      perl-perfSONAR_PS-Nagios
Obsoletes:      perl-perfSONAR_PS-LSCacheDaemon

%description perl
Libraries common to many of the perfSONAR perl components

%package sls-perl
Summary:        Simple Lookup Service (sLS) clients
Group:          Applications/Communications
Requires:		perl(Carp)
Requires:		perl(Data::Dumper)
Requires:		perl(Data::UUID)
Requires:		perl(DateTime::Format::ISO8601)
Requires:		perl(Exporter)
Requires:		perl(JSON)
Requires:		perl(Log::Log4perl)
Requires:		perl(Net::Ping)
Requires:   perl(Crypt::OpenSSL::RSA)
Requires:   perl(Crypt::OpenSSL::X509)
Requires:   perl(MIME::Base64)
Requires:		perl(Params::Validate)
Requires:		perl(Scalar::Util)
Requires:		perl(Time::HiRes)
Requires:		perl(URI)
Requires:		perl(YAML::Syck)
Requires:		perfsonar-common
Requires:		libperfsonar-perl
Obsoletes:      perl-perfSONAR_PS-Toolkit-Library
Obsoletes:      perl-perfSONAR_PS-LSRegistrationDaemon
Obsoletes:      perl-perfSONAR_PS-serviceTest
Obsoletes:      perl-perfSONAR_PS-Toolkit
Obsoletes:      perl-perfSONAR_PS-Nagios
Obsoletes:      perl-perfSONAR-graphs

%description sls-perl
Client libraries for perfSONAR's Simple Lookup Service (sLS)

%package esmond-perl
Summary:        perfSONAR Meaurement Archive perl clients for esmond
Group:          Applications/Communications
Requires:		perl(Exporter)
Requires:		perl(JSON)
Requires:		perl(Mouse)
Requires:		perl(POSIX)
Requires:		perl(Params::Validate)
Requires:		perl(URI::Split)
Requires:		perfsonar-common
Requires:		libperfsonar-perl
Obsoletes:      perl-perfSONAR_PS-Toolkit-Library
Obsoletes:      perl-perfSONAR_PS-LSRegistrationDaemon
Obsoletes:      perl-perfSONAR_PS-serviceTest
Obsoletes:      perl-perfSONAR_PS-Toolkit
Obsoletes:      perl-perfSONAR_PS-Nagios
Obsoletes:      perl-perfSONAR-graphs

%description esmond-perl
perfSONAR Meaurement Archive perl clients for esmond

%package pscheduler-perl
Summary:        perfSONAR Meaurement Archive perl clients for pScheduler
Group:          Applications/Communications
Requires:		perl(Exporter)
Requires:		perl(JSON)
Requires:		perl(Mouse)
Requires:		perl(POSIX)
Requires:		perl(Params::Validate)
Requires:		perl(URI::Split)
Requires:		perfsonar-common
Requires:		libperfsonar-perl

%description pscheduler-perl
pScheduler perl client libraries

%package psconfig-perl
Summary:        perfSONAR Meaurement Archive perl clients for pSConfig
Group:          Applications/Communications
Requires:		perl(Data::Validate::IP)
Requires:		perl(Data::Validate::Domain)
Requires:		perl(Digest::MD5)
Requires:		perl(Exporter)
Requires:		perl(JSON)
Requires:		perl(JSON::Validator)
Requires:		perl(Log::Log4perl)
Requires:		perl(Mouse)
Requires:		perl(POSIX)
Requires:		perl(Params::Validate)
Requires:		perfsonar-common
Requires:		libperfsonar-perl

%description psconfig-perl
pSConfig perl client libraries


%package toolkit-perl
Summary:        Shared libraries for perfSONAR Toolkit distributions
Group:          Applications/Communications
Requires:		perl(CGI)
Requires:		perl(CGI::Ajax)
Requires:		perl(CGI::Carp)
Requires:		perl(CGI::Session)
Requires:		perl(Carp)
Requires:		perl(Class::MOP::Class)
Requires:		perl(Config::General)
Requires:		perl(DBI)
Requires:		perl(Data::Dumper)
Requires:		perl(Data::UUID)
Requires:		perl(Data::Validate::Domain)
Requires:		perl(Data::Validate::IP)
Requires:		perl(DateTime)
Requires:		perl(DateTime::Format::ISO8601)
Requires:		perl(Digest::MD5)
Requires:		perl(English)
Requires:		perl(Exporter)
Requires:		perl(File::Basename)
Requires:		perl(File::Path)
Requires:		perl(File::Spec)
Requires:		perl(File::Temp)
Requires:		perl(IO::File)
Requires:		perl(IO::Select)
Requires:		perl(IO::Socket::SSL)
Requires:               perl(IO::Socket::INET6)
Requires:		perl(IPC::Open3)
Requires:		perl(IPC::Run)
Requires:		perl(JSON)
Requires:		perl(JSON::XS)
Requires:		perl(Log::Log4perl)
Requires:		perl(Math::Int64)
Requires:		perl(Module::Load)
Requires:		perl(Moose)
Requires:		perl(Net::CIDR)
Requires:		perl(Net::DNS)
Requires:		perl(Net::IP)
Requires:		perl(Net::NTP)
Requires:		perl(Net::Server)
Requires:		perl(Net::Traceroute)
Requires:		perl(NetAddr::IP)
Requires:		perl(POSIX)
Requires:		perl(Params::Validate)
Requires:		perl(RPC::XML)
Requires:		perl(RPC::XML::Client)
Requires:		perl(RPC::XML::Server)
Requires:		perl(RPM2)
Requires:		perl(Regexp::Common)
Requires:		perl(Scalar::Util)
Requires:		perl(Socket)
Requires:		perl(Socket6)
Requires:		perl(Statistics::Descriptive)
Requires:		perl(Storable)
Requires:		perl(Symbol)
Requires:		perl(Sys::Hostname)
Requires:		perl(Sys::Statistics::Linux)
Requires:		perl(Template)
Requires:		perl(Template::Filters)
Requires:		perl(Time::HiRes)
Requires:		perl(URI)
Requires:		perl(URI::Split)
Requires:		perl(XML::LibXML)
Requires:		perfsonar-common
Requires:		libperfsonar-perl
Requires:		libperfsonar-sls-perl
Requires:		libperfsonar-regulartesting-perl
Requires:		perfsonar-psconfig-pscheduler-devel
Obsoletes:      perl-perfSONAR_PS-Toolkit-Library
Obsoletes:      perl-perfSONAR_PS-serviceTest
Obsoletes:      perl-perfSONAR_PS-Toolkit
Obsoletes:      perl-perfSONAR-graphs
Obsoletes:      perl-perfSONAR_PS-MeshConfig-Shared
Obsoletes:      perl-perfSONAR_PS-LSRegistrationDaemon

%description toolkit-perl
Shared libraries for perfSONAR Toolkit distributions

%package regulartesting-perl
Summary:        Shared libaries for perfSONAR regular testing
Group:          Applications/Communications
Requires:		perl(Class::MOP::Class)
Requires:		perl(Config::General)
Requires:		perl(DBI)
Requires:		perl(Data::Dumper)
Requires:		perl(Data::UUID)
Requires:		perl(Data::Validate::Domain)
Requires:		perl(Data::Validate::IP)
Requires:		perl(DateTime)
Requires:		perl(DateTime::Format::ISO8601)
Requires:		perl(Digest::MD5)
Requires:		perl(Exporter)
Requires:		perl(File::Path)
Requires:		perl(File::Spec)
Requires:		perl(File::Temp)
Requires:		perl(HTTP::Request)
Requires:		perl(HTTP::Response)
Requires:		perl(Hash::Merge)
Requires:		perl(IO::Select)
Requires:		perl(IO::Socket::SSL)
Requires:       perl(IO::Socket::INET6)
Requires:		perl(IPC::DirQueue)
Requires:		perl(IPC::Open3)
Requires:		perl(IPC::Run)
Requires:		perl(JSON)
Requires:		perl(LWP)
Requires:		perl(Log::Log4perl)
Requires:		perl(Math::Int64)
Requires:		perl(Module::Load)
Requires:		perl(Moose)
Requires:		perl(Net::DNS)
Requires:		perl(Net::IP)
Requires:		perl(Net::Traceroute)
Requires:		perl(NetAddr::IP)
Requires:		perl(POSIX)
Requires:		perl(Params::Validate)
Requires:		perl(Regexp::Common)
Requires:		perl(Socket6)
Requires:		perl(Statistics::Descriptive)
Requires:		perl(Symbol)
Requires:		perl(Time::HiRes)
Requires:		perl(URI::Split)
Requires:		perfsonar-common
Requires:       libperfsonar-esmond-perl
Obsoletes:      perl-perfSONAR_PS-Toolkit-Library
Obsoletes:      perl-perfSONAR_PS-Toolkit
Obsoletes:      perl-perfSONAR_PS-MeshConfig-Agent
Obsoletes:      perl-perfSONAR_PS-RegularTesting


%description regulartesting-perl
Shared libaries for perfSONAR regular testing

%pre
/usr/sbin/groupadd -r perfsonar 2> /dev/null || :
/usr/sbin/useradd -g perfsonar -r -s /sbin/nologin -c "perfSONAR User" -d /tmp perfsonar 2> /dev/null || :

%prep
%setup -q -n libperfsonar-%{version}.%{perfsonar_auto_relnum}

%build

%install
rm -rf %{buildroot}
make ROOTPATH=%{buildroot}/%{install_base} CONFIGPATH=%{buildroot}/%{config_base} install

%clean
rm -rf %{buildroot}

%files perl
%license LICENSE
%defattr(0644,perfsonar,perfsonar,0755)
%{install_base}/lib/Net/NTP.pm
%{install_base}/lib/perfSONAR_PS/Common.pm
%{install_base}/lib/perfSONAR_PS/Utils/DNS.pm
%{install_base}/lib/perfSONAR_PS/Utils/Daemon.pm
%{install_base}/lib/perfSONAR_PS/Utils/GeoLookup.pm
%{install_base}/lib/perfSONAR_PS/Utils/HTTPS.pm
%{install_base}/lib/perfSONAR_PS/Utils/Host.pm
%{install_base}/lib/perfSONAR_PS/Utils/ISO8601.pm
%{install_base}/lib/perfSONAR_PS/Utils/JQ.pm
%{install_base}/lib/perfSONAR_PS/Utils/Logging.pm
%{install_base}/lib/perfSONAR_PS/Utils/NTP.pm
%{install_base}/lib/perfSONAR_PS/Utils/NetLogger.pm
%{install_base}/lib/perfSONAR_PS/Utils/ParameterValidation.pm
%{install_base}/lib/perfSONAR_PS/Client/Utils.pm

%files sls-perl
%license LICENSE
%defattr(0644,perfsonar,perfsonar,0755)
%{install_base}/lib/SimpleLookupService/*
%{install_base}/lib/perfSONAR_PS/Client/LS/*
%{install_base}/lib/perfSONAR_PS/Utils/LookupService.pm

%files esmond-perl
%license LICENSE
%defattr(0644,perfsonar,perfsonar,0755)
%{install_base}/lib/perfSONAR_PS/Client/Esmond/*

%files pscheduler-perl
%license LICENSE
%defattr(0644,perfsonar,perfsonar,0755)
%{install_base}/lib/perfSONAR_PS/Client/PScheduler/*

%files psconfig-perl
%license LICENSE
%defattr(0644,perfsonar,perfsonar,0755)
%{install_base}/lib/perfSONAR_PS/Client/PSConfig/*

%files toolkit-perl
%license LICENSE
%defattr(0644,perfsonar,perfsonar,0755)
%{install_base}/lib/perfSONAR_PS/NPToolkit/*
%{install_base}/lib/perfSONAR_PS/Web/Sidebar.pm
%{install_base}/lib/perfSONAR_PS/Client/gLS/Keywords.pm

%files regulartesting-perl
%license LICENSE
%defattr(0644,perfsonar,perfsonar,0755)
%{install_base}/lib/perfSONAR_PS/RegularTesting/*

%changelog
* Fri Jan 29 2016 andy@es.net 3.5.1-0.1.a1
- Initial spec file
