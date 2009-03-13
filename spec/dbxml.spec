# threads
# values: pthreads, none
#%define threads pthreads

Summary:	Oracle Sleepycat XML Database
Name:		dbxml
Version:	2.3.11
Release:	2
URL:		http://xml.apache.org/xerces-c/
Source0:        %{name}-2.3.11.tar.gz
License:	Apache
Group:		Libraries
BuildRoot:	%{_tmppath}/%{name}-root
Prefix:		/usr

%description
Oracle Berkeley DB XML is an open source, embeddable XML database with
XQuery-based access to documents stored in containers and indexed based on
their content. Oracle Berkeley DB XML is built on top of Oracle Berkeley DB and
inherits its rich features and attributes. Like Oracle Berkeley DB, it runs in
process with the application with no need for human administration. Oracle
Berkeley DB XML adds a document parser, XML indexer and XQuery engine on top of
Oracle Berkeley DB to enable the fastest, most efficient retrieval of data.

%package devel
Requires:	dbxml = %{version}
Group:		Development/Libraries
Summary:	Header files for Oracle Sleepycat XML DB

%description devel
Header files you can use to develop XML applications with Oracle Sleepycat XML
DB

Oracle Berkeley DB XML is an open source, embeddable XML database with
XQuery-based access to documents stored in containers and indexed based on
their content. Oracle Berkeley DB XML is built on top of Oracle Berkeley DB and
inherits its rich features and attributes. Like Oracle Berkeley DB, it runs in
process with the application with no need for human administration. Oracle
Berkeley DB XML adds a document parser, XML indexer and XQuery engine on top of
Oracle Berkeley DB to enable the fastest, most efficient retrieval of data.

%package doc
Group:		Documentation
Summary:	Documentation for Oracle Sleepycat XML DB

%description doc
Documentation for Oracle Sleepycat XML DB

Oracle Berkeley DB XML is an open source, embeddable XML database with
XQuery-based access to documents stored in containers and indexed based on
their content. Oracle Berkeley DB XML is built on top of Oracle Berkeley DB and
inherits its rich features and attributes. Like Oracle Berkeley DB, it runs in
process with the application with no need for human administration. Oracle
Berkeley DB XML adds a document parser, XML indexer and XQuery engine on top of
Oracle Berkeley DB to enable the fastest, most efficient retrieval of data.

%prep
%setup -q -n %{name}-2.3.11

%build
$RPM_BUILD_DIR/%{name}-2.3.11/buildall.sh --prefix=$RPM_BUILD_ROOT/%{prefix}/%{name}-2.3.11
$RPM_BUILD_DIR/%{name}-2.3.11/buildall.sh --enable-perl --build-one=perl --prefix=$RPM_BUILD_ROOT/%{prefix}

%install

%clean
rm -rf $RPM_BUILD_ROOT

%post
echo %{prefix}/%{name}-2.3.11/lib > /etc/ld.so.conf.d/dbxml.conf
/sbin/ldconfig

%postun
rm /etc/ld.so.conf.d/dbxml.conf
/sbin/ldconfig

%files
%defattr(755,root,root)
%{prefix}/dbxml-2.3.11/bin/*
%{prefix}/dbxml-2.3.11/lib/*
%{prefix}/dbxml-2.3.11/include/*
%{_libdir}/perl5/*
%{prefix}/share/man/man3/*

%files devel
%defattr(-,root,root)
%{prefix}/src/*
%{prefix}/lib/debug/*

#%files perl
#%defattr(755,root,root)
#%{prefix}/lib/perl5/*
#%{prefix}/share/man/man3/*

%files doc
%defattr(-,root,root)
%{prefix}/dbxml-2.3.11/docs/*
#%doc LICENSE NOTICE STATUS credits.txt Readme.html doc/

%changelog
* Fri Jun  6 2003 Tuan Hoang <tqhoang@bigfoot.com>
- updated for new Xerces-C filename and directory format
- fixed date format in changelog section

* Fri Mar 14 2003 Tinny Ng <tng@ca.ibm.com>
- changed to 2.3

* Wed Dec 18 2002 Albert Strasheim <albert@stonethree.com>
- added symlink to libxerces-c.so in lib directory

* Fri Dec 13 2002 Albert Strasheim <albert@stonethree.com>
- added seperate doc package
- major cleanups

* Tue Sep 03 2002  <thomas@linux.de>
- fixed missing DESTDIR in Makefile.util.submodule

* Mon Sep 02 2002  <thomas@linux.de>
- Initial build.
