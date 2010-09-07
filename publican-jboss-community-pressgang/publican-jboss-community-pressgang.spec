%define brand jboss-community-pressgang

Name:		publican-jboss-community-pressgang
Summary:	Common documentation files for PressGang documents
Version:	1.2
Release:	0%{?dist}
License:	CC-BY-SA
Group:		Applications/Text
Buildroot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Buildarch:	noarch
Source:		https://fedorahosted.org/releases/publican/%{name}-%{version}.tgz
Requires:	publican >= 2.0
BuildRequires:	publican >= 2.0
URL:		https://publican.fedorahosted.org/

%description
This package provides common files and templates needed to build documentation
for PressGang with Publican.

%prep
%setup -q 

%build
publican build --formats=xml --langs=all --publish

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p -m755 $RPM_BUILD_ROOT%{_datadir}/publican/Common_Content
publican install_brand --path=$RPM_BUILD_ROOT%{_datadir}/publican/Common_Content

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc README
%doc COPYING
%{_datadir}/publican/Common_Content/%{brand}

%changelog
* Tue Sep 7 2010 Rüdiger Landmann <r.landmann@redhat.com> 1.2-0
- add trademark notice for MySQL per Pamela Chestek <pchestek@redhat.com>
- Extend callout graphics to 40 -- BZ #629804 <r.landmann@redhat.com>

* Mon Jul 5 2010 Jeff Fearn <jfearn@redhat.com> 1.1
- Port to Publican 2

* Tue May 18 2010  Rüdiger Landmann <r.landmann@redhat.com> 1.0-0
- Created brand from JBoss community brand

