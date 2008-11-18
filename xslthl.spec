%define sunjdk %(eval 'if [ "%{?dist}" = ".el5" ]; then echo "1"; else echo "0"; fi')

Name:		xslthl
Summary:	XSLT Syntax Highlighting
Version:	2.0.0
Release:	1%{?dist}
License:	zlib
URL:		http://sourceforge.net/projects/xslthl
Group:		Development/Tools
Buildroot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Buildarch:	noarch
Source:		%{name}-%{version}.tar.gz
# To reproduce:
# svn export https://xslthl.svn.sourceforge.net/svnroot/xslthl/trunk/xslthl
# cat xslthl/src/net/sf/xslthl/version.properties (to get major.minor.revision)
# mv xslthl xslthl-[Maj.min.rev]
# tar -zcf xslthl-[Maj.min.rev].tar.gz xslthl-[Maj.min.rev]
#
#  release=`cat xslthl/src/net/sf/xslthl/version.properties | xargs echo | perl -p -e 's/[^\d]*(\d)/$1./g;s/[^\d.]//g;s/[^\d]*$//'`; mv xslthl xslthl-$release; tar --remove-files -zcf xslthl-$release.tar.gz xslthl-$release

BuildRequires:	ant dos2unix

%if %{sunjdk}
BuildRequires:  java-1.5.0-sun-devel
Requires:	java-1.5.0-sun
%else
BuildRequires:	java-devel >= 1:1.6.0
Requires:	java >= 1:1.6.0
%endif

%description
This is an implementation of syntax highlighting as an extension module
for XSLT processors, so if you have e.g. article about programming written
in DocBook, code examples can be automatically syntax highlighted during
the XSLT processing phase.

%prep
%setup -q

%build
ant jar

%install
rm -rf $RPM_BUILD_ROOT
install -d -m 755 $RPM_BUILD_ROOT%{_javadir}
install -m 644 dist/%{name}-%{version}.jar $RPM_BUILD_ROOT%{_javadir}/%{name}-%{version}.jar
(cd $RPM_BUILD_ROOT%{_javadir} && ln -sf %{name}-%{version}.jar %{name}.jar)

install -d -m 755 $RPM_BUILD_ROOT%{_datadir}/%{name}
cp -pr highlighters/*.xml $RPM_BUILD_ROOT%{_datadir}/%{name}/.

dos2unix LICENSE.txt

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc LICENSE.txt
%{_javadir}/*.jar
%{_datadir}/%{name}

%changelog
* Mon Oct 13 2008 Jeff Fearn <jfearn@redhat.com> 2.0.0-1
- Change Java version to fix koji build error.

* Thu Sep 11 2008 Jeff Fearn <jfearn@redhat.com> 2.0.0-0
- initial package

