%define brand jboss-community-jbt

Name:		publican-jboss-community-jbt
Summary:	Common documentation files for JBoss Tools community documents
Version:	1.0
Release:	0%{?dist}
License:	CC-BY-SA
Group:		Applications/Text
Buildroot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Buildarch:	noarch
Source:		https://fedorahosted.org/releases/publican/%{name}-%{version}.tgz
Requires:	publican >= 2.3
BuildRequires:	publican >= 2.0
URL:		https://publican.fedorahosted.org/

%description
This package provides common files and templates needed to build documentation
for JBoss Tools community documents with Publican.

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
* Thu Oct 21 2010 Rüdiger Landmann <r.landmann@redhat.com> 1.0-0
- Created brand based on JBoss Community brand


