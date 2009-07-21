%define brand gimp

Name:		publican-gimp
Summary:	Common documentation files for %{brand}
Version:	0.6
Release:	0%{?dist}
License:	GFDL
Group:		Development/Libraries
Buildroot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Buildarch:	noarch
Source:		https://fedorahosted.org/releases/p/u/publican/%{name}-%{version}.tgz
Requires:	publican >= 1.0
BuildRequires:	publican >= 1.0
URL:		https://fedorahosted.org/publican

%description
This package provides common files and templates needed to build documentation
for %{brand} with publican.

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
%defattr(-,root,root)
%doc README
%doc COPYING
%{_datadir}/publican/Common_Content/%{brand}

%changelog
* Tue Jul 21 2009 Jeff Fearn <jfearn@redhat.com> 0.6
- port to publican 1.0.

* Wed Feb 25 2009  Jeff Fearn <jfearn@redhat.com> 0.5
- Add symlinks for langauges without country codes. BZ #487256

* Mon Jan 5 2009 Jeff Fearn <jfearn@redhat.com> 0.4
- Add LICENSE override for RPMs. BZ #477720

* Thu Dec 4 2008 Jeff Fearn <jfearn@redhat.com> 0.3
- Fix styles for publican 0.35 mods
- Removed common entity files as they break translation

* Mon Jun 16 2008 Jeff Fearn <jfearn@redhat.com> 0.2-0
- Added Article and Set Templates
- Added code highlighting to CSS

* Wed Apr 30 2008 Jeff Fearn <jfearn@redhat.com> 0.1-0
- Initial creation
