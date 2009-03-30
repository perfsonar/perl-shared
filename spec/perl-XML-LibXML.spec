%define pkgname XML-LibXML
%define filelist %{pkgname}-%{version}-filelist
%define NVR %{pkgname}-%{version}-%{release}
%define maketest 1

Name:           perl-XML-LibXML
Summary:        Perl Binding for libxml2
Version:        1.69
Release:        1
Vendor:         Petr Pajas
Packager:       Arix International <cpan2rpm@arix.com>
License:        Distributable, see LICENSE
Group:          Development/Libraries
URL:            http://search.cpan.org/dist/XML-LibXML/
Buildroot:      %{_tmppath}/%{name}-%{version}-%(id -u -n)
Buildarch:      i386
BuildRequires:  perl(ExtUtils::MakeMaker)
BuildRequires:  perl(XML::LibXML::Common) >= 0.13
BuildRequires:  perl(XML::NamespaceSupport) >= 1.07
BuildRequires:  perl(XML::SAX) >= 0.11
Requires:       perl
Requires:       libxml2
Requires:       libxml2-devel
Requires:       perl(XML::LibXML::Common) >= 0.13
Requires:       perl(XML::NamespaceSupport) >= 1.07
Requires:       perl(XML::SAX) >= 0.11
prefix:         %(echo %{_prefix})
Source:         http://www.cpan.org/modules/by-module/XML/XML-LibXML-%{version}.tar.gz

%description
This module is an interface to libxml2, providing XML and HTML parsers with
DOM, SAX and XMLReader interfaces, a large subset of DOM Layer 3 interface
and a XML::XPath-like interface to XPath API of libxml2. The module is
split into several packages which are not described in this section; unless
stated otherwise, you only need to use XML::LibXML; in your programs.

%prep
%setup -q -n %{pkgname}-%{version} 
chmod -R u+w %{_builddir}/%{pkgname}-%{version}

%build
grep -rsl '^#!.*perl' . |
grep -v '.bak$' |xargs --no-run-if-empty \
%__perl -MExtUtils::MakeMaker -e 'MY->fixin(@ARGV)'
CFLAGS="$RPM_OPT_FLAGS"
%{__perl} Makefile.PL `%{__perl} -MExtUtils::MakeMaker -e ' print qq|PREFIX=%{buildroot}%{_prefix}| if \$ExtUtils::MakeMaker::VERSION =~ /5\.9[1-6]|6\.0[0-5]/ '`
%{__make} 
%if %maketest
%{__make} test
%endif

%install
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

%{makeinstall} `%{__perl} -MExtUtils::MakeMaker -e ' print \$ExtUtils::MakeMaker::VERSION <= 6.05 ? qq|PREFIX=%{buildroot}%{_prefix}| : qq|DESTDIR=%{buildroot}| '`

cmd=/usr/share/spec-helper/compress_files
[ -x $cmd ] || cmd=/usr/lib/rpm/brp-compress
[ -x $cmd ] && $cmd

# SuSE Linux

if [ -e /etc/SuSE-release -o -e /etc/UnitedLinux-release ]
then
    %{__mkdir_p} %{buildroot}/var/adm/perl-modules
    fname=`find %{buildroot} -name "perllocal.pod" | head -1`
    if [ -f "$fname" ] ; then                             \
        %{__cat} `find %{buildroot} -name "perllocal.pod"`  \
        | %{__sed} -e s+%{buildroot}++g                     \
        < /dev/null                                         \
        > %{buildroot}/var/adm/perl-modules/%{name} ;      \
    fi
fi

# remove special files
find %{buildroot} -name "perllocal.pod" \
    -o -name ".packlist"                \
    -o -name "*.bs"                     \
    |xargs -i rm -f {}

# no empty directories
find %{buildroot}%{_prefix}             \
    -type d -depth                      \
    -exec rmdir {} \; 2>/dev/null

%{__perl} -MFile::Find -le '
    find({ wanted => \&wanted, no_chdir => 1}, "%{buildroot}");
    print "%doc  test debian example Changes docs README LICENSE";
    for my $x (sort @dirs, @files) {
        push @ret, $x unless indirs($x);
        }
    print join "\n", sort @ret;

    sub wanted {
        return if /auto$/;

        local $_ = $File::Find::name;
        my $f = $_; s|^\Q%{buildroot}\E||;
        return unless length;
        return $files[@files] = $_ if -f $f;

        $d = $_;
        /\Q$d\E/ && return for reverse sort @INC;
        $d =~ /\Q$_\E/ && return
            for qw|/etc %_prefix/man %_prefix/bin %_prefix/share|;

        $dirs[@dirs] = $_;
        }

    sub indirs {
        my $x = shift;
        $x =~ /^\Q$_\E\// && $x ne $_ && return 1 for @dirs;
        }
    ' > %filelist

[ -z %filelist ] && {
    echo "ERROR: empty %files listing"
    exit -1
    }

%clean
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

%files -f %filelist
%defattr(-,root,root)

%changelog
* Mon Mar 30 2009 Jason Zurawski 1.69-1
- Compat changes for Fedora/Centos

* Mon Feb 9 2009 root@localhost.localdomain
- Initial build.
