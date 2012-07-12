%define brand rhev
%define wwwdir /var/www/html/docs

Name:		publican-rhev
Summary:	Common documentation files for %{brand}
Version:	2.0
Release:	2%{?dist}
License:	CC-BY-SA
Group:		Applications/Text
Buildroot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:   noarch
Source:		https://fedorahosted.org/releases/p/u/publican/publican-rhev-%{version}.tgz
BuildRequires:	publican >= 3.0
Requires:	publican >= 3.0
URL:		https://fedorahosted.org/publican
Provides:	documentation-devel-%{brand} = %{version}-%{release}
Obsoletes:	documentation-devel-%{brand} < %{version}-%{release}

%description
This package provides common files and templates needed to build documentation
for %{brand} with publican.

%package web
Summary:        Web styles for %{brand}
Group:          Documentation
Requires:	publican >= 3.0

%description web
Web Site common files for the %{brand} brand.

%prep
%setup -q

%build
publican build --formats=xml --langs=all --publish

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p -m755 $RPM_BUILD_ROOT%{_datadir}/publican/Common_Content
publican install_brand --path=$RPM_BUILD_ROOT%{_datadir}/publican/Common_Content
mkdir -p -m755 $RPM_BUILD_ROOT/%{wwwdir}/%{brand}
publican install_brand --web --path=$RPM_BUILD_ROOT/%{wwwdir}/%{brand}

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc README
%doc COPYING
%{_datadir}/publican/Common_Content/%{brand}

%files web
%defattr(-,root,root,-)
%{wwwdir}/%{brand}

%changelog
* Thu Jul 12 2012 Rüdiger Landmann <rlandman@redhat.com> 2.0-2
- Remove backup files

* Thu Jul 12 2012 Rüdiger Landmann <rlandman@redhat.com> 2.0-1
- Update for Publican 3.0

* Fri Mar 02 2012 Tim Hildred <thildred@redhat.com> 1.0-1
- Initial creation
