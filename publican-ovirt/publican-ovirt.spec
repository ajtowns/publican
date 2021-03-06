%define brand oVirt

Name:		publican-ovirt
Summary:	Common documentation files for %{brand}
Version:	1.5
Release:	0%{?dist}
License:	Open Publication
Group:		Applications/Text
Buildroot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Buildarch:	noarch
Source:		https://fedorahosted.org/releases/p/u/publican/%{name}-%{version}.tgz
Requires:	publican >= 2.0
BuildRequires:	publican >= 2.0
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
publican install_brand --path=$RPM_BUILD_ROOT%{_datadir}/publican/Common_Content

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc README
%doc COPYING
%{_datadir}/publican/Common_Content/%{brand}

%changelog
* Wed Nov 9 2011 Stephen Gordon <sgordon@redhat.com> 1.5-0
- Updated Feedback.xml to match new oVirt workflow.
- Removed links to docs.redhat.com, replaced with ovirt.org.
- Added updated oVirt logo image.
- Added updated oVirt header bar for html, html-single formats (doesn't appear in PDF)
- Replaced 'Red Hat Documentation' image.
- Updated Legal Notice to specify ASL 2.0 using notice cleared by legal (<rfontana@redhat.com>).
- Added ASL 2.0 full text as an appendix.

* Tue Oct 5 2010 Rüdiger Landmann <r.landmann@redhat.com> 1.4-0
- Restrict CSS style for edition to title pages to avoid applying to bibliographies <r.landmann@redhat.com>

* Mon Jul 5 2010 Jeff Fearn <jfearn@redhat.com> 1.3
- Port to Publican 2

* Thu Jun 10 2010 Jeff Fearn <jfearn@redhat.com> 1.2
- Remove HTML term color. BZ #592822

* Thu Mar 25 2010 Rüdiger Landmann <r.landmann@redhat.com> 1.1
- add trademark notices for XFS and Java per Pamela Chestek <pchestek@redhat.com>

* Fri Oct 30 2009 Jeff Fearn <jfearn@redhat.com> 1.0
- port to publican 1.0.

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
