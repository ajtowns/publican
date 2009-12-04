%define brand jboss-community

Name:		publican-%{brand}
Summary:	Publican documentation template files for %{brand}
Version:	1.0
Release:	0%{?dist}
License:	CC-BY-SA
Group:		Development/Libraries
Buildroot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Buildarch:	noarch
Source:		https://fedorahosted.org/releases/publican/%{name}-%{version}.tgz
Requires:	publican >= 1.0
BuildRequires:	publican >= 1.0
URL:		https://publican.fedorahosted.org/

%description
This package provides common files and templates needed to build documentation
for JBoss community documents with Publican.

%prep
%setup -q

%build
publican build --formats=xml --langs=all --publish

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p -m755 $RPM_BUILD_ROOT%{_datadir}/publican/Common_Content
publican installbrand --path=$RPM_BUILD_ROOT%{_datadir}/publican/Common_Content

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc README
%doc COPYING
%{_datadir}/publican/Common_Content/%{brand}

%changelog
* Wed Nov 25 2009 Rüdiger Landmann <rlandmann@redhat.com> 1.0-0
- Initial creation
