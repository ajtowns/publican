%define brand oVirt

Name:		publican-ovirt
Summary:	Common documentation files for %{brand}
Version:	0.7
Release:	0%{?dist}
License:	Open Publication
Group:		Applications/Text
Buildroot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Buildarch:	noarch
Source:		https://fedorahosted.org/releases/p/u/publican/%{name}-%{version}.tgz
Requires:	publican
BuildRequires:	publican
URL:		https://fedorahosted.org/publican

%description
This package provides common files and templates needed to build documentation
for %{brand} with publican.

%prep
%setup -q

%build
%{__make} Common_Content

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p -m755 $RPM_BUILD_ROOT%{_datadir}/publican/Templates
mkdir -p -m755 $RPM_BUILD_ROOT%{_datadir}/publican/make
mkdir -p -m755 $RPM_BUILD_ROOT%{_datadir}/publican/xsl/%{brand}
cp -rf Common_Content $RPM_BUILD_ROOT%{_datadir}/publican/
cp -rf Book_Template $RPM_BUILD_ROOT%{_datadir}/publican/Templates/%{brand}-Book_Template
cp -rf Set_Template $RPM_BUILD_ROOT%{_datadir}/publican/Templates/%{brand}-Set_Template
cp -rf Article_Template $RPM_BUILD_ROOT%{_datadir}/publican/Templates/%{brand}-Article_Template
install -m 644 make/Makefile.%{brand} $RPM_BUILD_ROOT%{_datadir}/publican/make/.
install -m 644 xsl/*.xsl $RPM_BUILD_ROOT%{_datadir}/publican/xsl/%{brand}/.

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc README
%doc COPYING
%{_datadir}/publican/Common_Content/%{brand}
%{_datadir}/publican/Templates/%{brand}-*_Template
%{_datadir}/publican/make/Makefile.%{brand}
%{_datadir}/publican/xsl/%{brand}

%changelog
* Wed Feb 25 2009  Jeff Fearn <jfearn@redhat.com> 0.7
- Add symlinks for langauges without country codes. BZ #487256

* Mon Jan 5 2009 Jeff Fearn <jfearn@redhat.com> 0.6
- Add LICENSE override for RPMs. BZ #477720

* Mon Dec 1 2008 Jeff Fearn <jfearn@redhat.com> 0.5
- Add override for PROD_URL

* Mon Sep 15 2008 Alan Pevec <apevec@redhat.com> 0.4-2
- Initial Fedora submission, fix rpmlint errors

* Tue Sep 9 2008 Jeff Fearn <jfearn@redhat.com> 0.4-1
- Removed corpauthor from template. BZ #461222
- Removed OPL restriction. BZ #460268

* Mon Sep 1 2008 Jeff Fearn <jfearn@redhat.com> 0.3-0
- Fix styles for publican 0.35 mods
- Removed common entity files as they break translation
- Remove ID's from common files. BZ #460770

* Mon Jun 16 2008 Jeff Fearn <jfearn@redhat.com> 0.2-0
- Added Article and Set Templates
- Added code highlighting to CSS
- Turned on STRICT mode as required to get on to redhat.com/docs

* Thu Jun 2 2008 Andy Fitzsimon <afitzsim@redhat.com> 0.1-1
- common content css and images update

* Thu May 22 2008 Jeff Fearn <jfearn@redhat.com> 0.1-0
- Initial creation
