%define brand RedHat
%define pub_name Publican
%define RHEL6 %(test %{?dist} == .el6 && echo 1 || echo 0)

Name:		publican-redhat
Summary:	Common documentation files for %{brand}
Version:	2.5
Release:	0%{?dist}
License:	CC-BY-SA
Group:		Applications/Text
Buildroot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
# Limited to these arches on RHEL 6 due to PDF + Java limitations
%if %{RHEL6}
ExclusiveArch:   i686 x86_64
%else
BuildArch:   noarch
%endif
Source:		https://fedorahosted.org/releases/p/u/publican/publican-redhat-%{version}.tgz
BuildRequires:	publican >= 2.0
Requires:	publican >= 2.0
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
publican install_brand --path=$RPM_BUILD_ROOT%{_datadir}/publican/Common_Content

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc README
%doc COPYING
%{_datadir}/publican/Common_Content/%{brand}

%changelog
* Fri Oct 15 2010 Jeff Fearn <jfearn@redhat.com> 2.5-0
- Remove example override.

* Tue Oct 12 2010 Rüdiger Landmann <r.landmann@redhat.com> 2.4-1
- respin to catch English string not replaced in translated languages.

* Fri Oct 8 2010 Rüdiger Landmann <r.landmann@redhat.com> 2.4-0
- Updated Italian translation Francesco Valente <fvalen@redhat.com>
- rm fuzzies caused by BZ #628266 previously

* Tue Aug 24 2010 Rüdiger Landmann <r.landmann@redhat.com> 2.3-0
- Extend callout graphics to 40; adjust colour and font BZ #629804 <r.landmann@redhat.com>
- Restrict CSS style for edition to title pages to avoid applying to bibliographies <r.landmann@redhat.com>

* Tue Aug 24 2010 Rüdiger Landmann <r.landmann@redhat.com> 2.2-0
- Note ownership of MySQL trademark per Pamela Chestek <pchestek@redhat.com>

* Fri Aug 6 2010 Rüdiger Landmann <r.landmann@redhat.com> 2.1-0
- Update Feedback section to link to customer portal

* Mon Jul 5 2010 Jeff Fearn <jfearn@redhat.com> 2.0
- Port to Publican 2

* Thu Jun 10 2010 Jeff Fearn <jfearn@redhat.com> 1.9
- Remove HTML term color. BZ #592822

* Thu May 6 2010 Rüdiger Landmann <r.landmann@redhat.com> 1.8
- remove reference to OPL licence
- add max_image_width for BZ#580774
- add confidential_text for BZ#588980

* Wed Apr 03 2010 Jeff Fearn <jfearn@redhat.com> 1.7
- fix using FO template for xhmtl O_O

* Thu Mar 25 2010 Rüdiger Landmann <r.landmann@redhat.com> 1.6
- add trademark notices for XFS and Java per Pamela Chestek <pchestek@redhat.com>

* Thu Mar 25 2010 Jeff Fearn <jfearn@redhat.com> 1.5
- Add TOC to articles
- Fix broken ml-IN translation

* Fri Feb 26 2010 Timo Trinks <ttrinks@redhat.com> 1.4
- ah the optionally empty tag O doom

* Fri Feb 26 2010 Timo Trinks <ttrinks@redhat.com> 1.3
- updated Feedback.pot based on new en-US Feedback.xml
- updated de-DE Feedback.po

* Thu Jan 21 2010 Rüdiger Landmann <r.landmann@redhat.com> 1.2
- include section on getting help from GSS and other sources. BZ #492499

* Fri Nov 27 2009 Jeff Fearn <jfearn@redhat.com> 1.1
- update license to CC-BY-SA

* Fri Oct 30 2009 Jeff Fearn <jfearn@redhat.com> 1.0
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
