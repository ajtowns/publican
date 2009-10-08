%define brand RedHat
%define pub_name Publican

Name:		publican-redhat
Summary:	Common documentation files for %{brand}
Version:	0.20
Release:	0%{?dist}.t1
License:	Open Publication
Group:		Applications/Text
Buildroot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Buildarch:	noarch
Source:		https://fedorahosted.org/releases/p/u/publican/publican-redhat-%{version}.tgz
Requires:	publican >= %(eval "`publican -v`"; echo $version)
BuildRequires:	publican >= 0.99
URL:		https://fedorahosted.org/publican
Obsoletes:	documentation-devel-%{brand}

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
* Tue Jul 21 2009 Jeff Fearn <jfearn@redhat.com> 0.20
- port to publican 1.0.

* Wed Feb 25 2009  Jeff Fearn <jfearn@redhat.com> 0.19
- Add symlinks for langauges without country codes. BZ #487256

* Fri Jan 16 2009 Jeff Fearn <jfearn@redhat.com> 0.18
- Updated redhat brand license. BZ #478405
- Add LICENSE override for RPMs. BZ #477720
- Fix layout issue in Legal Notice. BZ #477573

* Tue Dec 2 2008 Jeff Fearn <jfearn@redhat.com> 0.17
- Fix remark colour

* Mon Dec 1 2008 Mike Hideo <mhideo@redhat.com> 0.16
- Removed GPG key from Legal_Notice.xml BZ#473350
- Add override for PROD_URL

* Tue Sep 9 2008 Jeff Fearn <jfearn@redhat.com> 0.15
- Removed corpauthor from template. BZ #461222

* Mon Sep 1 2008 Jeff Fearn <jfearn@redhat.com> 0.14-0
- Fix styles for publican 0.35 mods
- Switch from html-single to html-desktop. BZ #458743
- Removed common entity files as they break translation
- Remove ID's from common files. BZ #460770

* Mon Apr 14 2008 Jeff Fearn <jfearn@redhat.com> 0.13-0
- Fix missing list image in html-single articles
- QANDA set css fix BZ #442674
- Removed entities requiring mandatory override
- Override PDF Theme
- Added package tag BZ #444908
- Added Article and Set Templates
- Added code highlighting to CSS
- Modify CSS to use new easier maintenance system.

* Mon Apr 7 2008 Jeff Fearn <jfearn@redhat.com> 0.12-0
- Add Desktop css customisations

* Thu Apr 3 2008 Andy Fitzsimon <afitzsim@redhat.com> 0.11-0
- optimised default stylesheet colours
- author group improvements
- formatting for revision history 
- merged tocnav and documentation.css to defauly.css
- updated icons
- Fix doc URL

* Tue Mar 18 2008 Jeff Fearn <jfearn@redhat.com> 0.10-0
- Fix doc URL
- Fix Desktop build

* Thu Feb 28 2008 Jeff Fearn <jfearn@redhat.com> 0.9-0
- Added PRODUCT entity with default msg. BZ #431171
- Added BOOKID entity with default msg. BZ #431171
- Fix keycap hard to read in admon BZ #369161
- Added Brand Makefile
- Added DocBook 4.5 DTD and 1.72.0 xsl

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
