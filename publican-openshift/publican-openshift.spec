%define brand OpenShift

Name:		publican-openshift
Summary:	Common documentation files for %{brand}
Version:	0.1
Release:	0%{?dist}
License:	SETUP: Set This
Group:		Applications/Text
Buildroot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Buildarch:	noarch
Source:		https://www.SETUP.set.me.example.com/source/%{name}-%{version}.tgz
Requires:	publican >= 1.99
BuildRequires:	publican >= 1.99
URL:		https://www.SETUP.set.me.example.com

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

