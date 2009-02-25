%define brand fedora

Name:		publican-%{brand}
Summary:	Publican documentation template files for %{brand}
Version:	0.18
Release:	0%{?dist}
License:	Open Publication 
Group:		Development/Libraries
Buildroot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Buildarch:	noarch
Source:		https://fedorahosted.org/releases/p/u/publican/%{name}-%{version}.tgz
Requires:	publican
BuildRequires:	publican
URL:		https://fedorahosted.org/publican
Obsoletes:	documentation-devel-Fedora

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
install -m 755 make/Makefile.%{brand} $RPM_BUILD_ROOT%{_datadir}/publican/make/.
install -m 755 xsl/*.xsl $RPM_BUILD_ROOT%{_datadir}/publican/xsl/%{brand}/.

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc README
%doc COPYING
%{_datadir}/publican/Common_Content/%{brand}
%{_datadir}/publican/Templates/%{brand}-*_Template
%{_datadir}/publican/make/Makefile.%{brand}
%{_datadir}/publican/xsl/%{brand}

%changelog
* Wed Feb 25 2009  Jeff Fearn <jfearn@redhat.com> 0.18
- Add symlinks for langauges without country codes. BZ #487256

* Mon Jan 5 2009 Jeff Fearn <jfearn@redhat.com> 0.17
- Add LICENSE override for RPMs. BZ #477720

* Mon Dec 1 2008 Jeff Fearn <jfearn@redhat.com> 0.16
- resave title_logo.png. BZ #474075
- Add override for PROD_URL

* Tue Sep 9 2008 Jeff Fearn <jfearn@redhat.com> 0.15
- Removed corpauthor from template. BZ #461222
- Updated Fedora legal notice. BZ #448022

* Mon Sep 1 2008 Jeff Fearn <jfearn@redhat.com> 0.14-0
- Fix styles for publican 0.35 mods
- Removed common entity files as they break translation
- Remove ID's from common files. BZ #460770

* Mon Apr 14 2008 Jeff Fearn <jfearn@redhat.com> 0.13-0
- Fix missing list image in html-single articles
- QANDA set css fix BZ #442674
- Override PDF Theme
- Added package tag BZ #444908
- Added Article and Set Templates

* Mon Apr 7 2008 Jeff Fearn <jfearn@redhat.com> 0.12-0
- Add Desktop css customisations

* Tue Mar 4 2008 Andy Fitzsimon <afitzsim@redhat.com> 0.11-0
- optimised default stylesheet colours
- author group improvements
- formatting for revision history 
- merged tocnav and documentation.css to defauly.css
- updated icons

* Thu Feb 28 2008 Jeff Fearn <jfearn@redhat.com> 0.10-0
- Added PRODUCT entity with default msg. BZ #431171
- Added BOOKID entity with default msg. BZ #431171
- Fix keycap hard to read in admon BZ #369161
- Added Brand Makefile
- Fix docs URL BZ #434733

* Thu Feb 14 2008 Jeff Fearn <jfearn@redhat.com> 0.9-0
- Changed Group
- Updated Legal Notice
- Removed Requires(post) and Requires(postun)
- Added missing logo.png
- Updated Summary

* Wed Feb 13 2008 Jeff Fearn <jfearn@redhat.com> 0.8-1
- Correct License name
- Remove release from urls and file names

* Tue Feb 12 2008 Jeff Fearn <jfearn@redhat.com> 0.8-0
- Setup per Brand Book_Templates
- Fix soure and URL paths
- Use release in source path
- add OPL text as COPYING

* Mon Feb 11 2008 Jeff Fearn <jfearn@redhat.com> 0.7-0
- Updated YEAR entity with better message.

* Fri Feb 01 2008 Jeff Fearn <jfearn@redhat.com> 0.6-0
- Switch from documentation-devil to publican

* Thu Jan 17 2008 Jeff Fearn <jfearn@redhat.com> 0.5-0
- Switch from documentation-devel to documentation-devil

* Wed Jan 02 2008 Jeff Fearn <jfearn@redhat.com> 0.4-0
- Default YEAR and HOLDER. BZ #426040

* Fri Jul 20 2007 Jeff Fearn <jfearn@redhat.com> 0.3-0
- Update

* Fri Jul 13 2007 Jeff Fearn <jfearn@redhat.com> 0.1-0
- Initial creation
