%define brand JBoss
%define pub_name Publican
%define RHEL6 %([[ %{?dist}x == .el6[a-z]* ]] && echo 1 || echo 0)

Name:		publican-jboss
Summary:	Common documentation files for %{brand}
Version:	2.8
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
Source:		https://fedorahosted.org/releases/p/u/publican/%{name}-%{version}.tgz
Requires:	publican >= 2.5
BuildRequires:	publican >= 2.5
URL:		https://fedorahosted.org/publican/
Provides:	documentation-devel-%{brand} = %{version}-%{release}
Obsoletes:	documentation-devel-%{brand} < %{version}-%{release}

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
* Wed Jun 22 2011 Rüdiger Landmann <r.landmann@redhat.com> 2.8-1
- Updated translations

* Wed Jun 15 2011 Rüdiger Landmann <r.landmann@redhat.com> 2.7-1
- format simplelist for extra trademarks -- BZ#708259

* Thu Jun 9 2011 Rüdiger Landmann <r.landmann@redhat.com> 2.6-1
- fix support for extra trademarks -- BZ#708259

* Thu Jun 9 2011 Rüdiger Landmann <r.landmann@redhat.com> 2.5-1
- add "getting help" section
- update "giving feedback" section -- BZ#706302
- add support for extra trademarks -- BZ#708259

* Fri Jan 21 2011 Rüdiger Landmann <r.landmann@redhat.com> 2.4-1
- remove max_image_width

* Tue Nov 2 2010 Rüdiger Landmann <r.landmann@redhat.com> 2.3-1
- Correct URL

* Wed Oct 27 2010 Rüdiger Landmann <r.landmann@redhat.com> 2.3-0
- Change docs URL to docs.redhat.com per Mike Hideo-Smith <mhideo@redhat.com>

* Tue Oct 5 2010 Rüdiger Landmann <r.landmann@redhat.com> 2.2-0
- Extend callout graphics to 40; adjust colour and font BZ #629804 <r.landmann@redhat.com>
- Restrict CSS style for edition to title pages to avoid applying to bibliographies <r.landmann@redhat.com>
- import Russian translation from Red Hat brand

* Tue Aug 24 2010 Jeff Fearn <jfearn@redhat.com> 2.1-0
- Change space before cover logo to 1in. BZ #628754

* Tue Aug 24 2010 Rüdiger Landmann <r.landmann@redhat.com> 2.0-0
- Note ownership of MySQL trademark per Pamela Chestek <pchestek@redhat.com>

* Mon Jul 5 2010 Jeff Fearn <jfearn@redhat.com> 1.9
- Port to Publican 2

* Thu Jun 10 2010 Jeff Fearn <jfearn@redhat.com> 1.8
- Remove HTML term color. BZ #592822

* Mon May 10 2010 Rüdiger Landmann <r.landmann@redhat.com> 1.7-0
- Turn on TOCs for articles again for now, for JBoss release notes

* Thu May 6 2010 Rüdiger Landmann <r.landmann@redhat.com> 1.6-0
- fix scrollbars appearing around title logo in WebKit browsers BZ#589834

* Thu May 6 2010 Rüdiger Landmann <r.landmann@redhat.com> 1.5-0
- remove reference to OPL licence
- add max_image_width for BZ#580774
- add confidential_text for BZ#588980
- fix links BZ#589371

* Tue May 4 2010 Rüdiger Landmann <r.landmann@redhat.com> 1.4-0
- rm another Fedora reference

* Thu Apr 8 2010 Rüdiger Landmann <r.landmann@redhat.com> 1.3-1
- try building again

* Thu Apr 8 2010 Rüdiger Landmann <r.landmann@redhat.com> 1.3
- rm reference to Fedora Project

* Thu Mar 25 2010 Rüdiger Landmann <r.landmann@redhat.com> 1.2
- add trademark notices for XFS and Java per Pamela Chestek <pchestek@redhat.com>

* Fri Nov 27 2009 Jeff Fearn <jfearn@redhat.com> 1.1
- update license to CC-BY-SA

* Fri Oct 30 2009 Jeff Fearn <jfearn@redhat.com> 1.0
- port to publican 1.0.

* Mon Jun 1 2009 Ryan Lerch <rlerch@redhat.com> 0.19
- Updated the jBoss Logo files to the new version.

* Wed Feb 25 2009  Jeff Fearn <jfearn@redhat.com> 0.18
- Add symlinks for langauges without country codes. BZ #487256

* Mon Jan 5 2009 Jeff Fearn <jfearn@redhat.com> 0.17
- Add LICENSE override for RPMs. BZ #477720
- Update jboss brand license. BZ #478416

* Mon Dec 1 2008 Michael Hideo <mhideo@redhat.com> 0.16
- Removed GPG key from Legal_Notice.xml BZ#473350
- Removed corpauthor from template. BZ #461076
- Add override for PROD_URL

* Tue Sep 9 2008 Jeff Fearn <jfearn@redhat.com> 0.15
- Removed corpauthor from template. BZ #461222

* Mon Sep 1 2008 Jeff Fearn <jfearn@redhat.com> 0.14-0
- Fix styles for publican 0.35 mods
- Removed common entity files as they break translation
- Remove ID's from common files. BZ #460770

* Mon Apr 14 2008 Jeff Fearn <jfearn@redhat.com> 0.13-0
- Fix missing list image in html-single articles
- QANDA set css fix BZ #442674
- Removed entities with mandatory overrides
- Override PDF Theme
- Added package tag BZ #444908
- Added Article and Set Templates
- Added code highlighting to CSS

* Mon Apr 7 2008 Jeff Fearn <jfearn@redhat.com> 0.12-0
- Add Desktop css customisations

* Thu Apr 3 2008 Andy Fitzsimon <afitzsim@redhat.com> 0.11-0
- optimised default stylesheet colours
- author group improvements
- formatting for revision history 
- merged tocnav and documentation.css to defauly.css
- updated icons
- Fix doc URL

* Thu Feb 28 2008 Jeff Fearn <jfearn@redhat.com> 0.9-0
- Added PRODUCT entity with default msg. BZ #431171
- Added BOOKID entity with default msg. BZ #431171
- Fix keycap hard to read in admon BZ #369161

* Tue Feb 12 2008 Jeff Fearn <jfearn@redhat.com> 0.8-0
- Setup per Brand Book_Templates
- Fix soure and URL paths
- Use release in source path
- add cc-by-nc-sa text as COPYING

* Mon Feb 11 2008 Jeff Fearn <jfearn@redhat.com> 0.7-0
- Updated YEAR entity with better message.

* Fri Feb 01 2008 Jeff Fearn <jfearn@redhat.com> 0.6-0
- Switch from documentation-devil to publican

* Thu Jan 17 2008 Jeff Fearn <jfearn@redhat.com> 0.5-0
- Switch from documentation-devel to documentation-devil

* Wed Jan 02 2008 Jeff Fearn <jfearn@redhat.com> 0.4-0
- Default YEAR and HOLDER. BZ #426040

* Fri Jul 13 2007 Jeff Fearn <jfearn@redhat.com> 0.3-0
- Update

* Fri Jul 13 2007 Jeff Fearn <jfearn@redhat.com> 0.1-0
- Initial creation
