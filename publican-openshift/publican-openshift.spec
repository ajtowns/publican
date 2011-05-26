%define brand OpenShift
%define pub_name Publican
%define RHEL6 %(test %{?dist} == .el6 && echo 1 || echo 0)

Name:		publican-openshift
Summary:	Common documentation files for %{brand}
Version:	0.2
Release:	1%{?dist}
License:	CC-BY-SA
Group:		Applications/Text
Buildroot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
# Limited to these arches on RHEL 6 due to PDF + Java limitations
%if %{RHEL6}
ExclusiveArch:   i686 x86_64
%else
BuildArch:   noarch
%endif
Source:		https://fedorahosted.org/releases/p/u/publican/publican-openshift-%{version}.tgz
BuildRequires:	publican >= 2.5
Requires:	publican >= 2.5
URL:		https://fedorahosted.org/publican

%description
This package provides common files and templates needed to build documentation
for %{brand} with publican.

%prep
%setup -q 

%build
publican build --formats=xml --langs=en-US --publish

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
* Fri May 25 2011  David O'Brien <davido@redhat.com> 0.2
- Updated bug reporting options

* Wed May 20 2011 David O'Brien <davido@redhat.com> 0.1
- Created Brand
- Added common files for express and flex
- Updated support options

