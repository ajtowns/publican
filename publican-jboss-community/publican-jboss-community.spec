%define brand jboss-community

Name:		publican-jboss-community
Summary:	Common documentation files for JBoss community documents
Version:	1.4
Release:	0%{?dist}
License:	CC-BY-SA
Group:		Applications/Text
Buildroot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Buildarch:	noarch
Source:		https://fedorahosted.org/releases/publican/%{name}-%{version}.tgz
Requires:	publican >= 2.3
BuildRequires:	publican >= 2.0
URL:		https://publican.fedorahosted.org/

%description
This package provides common files and templates needed to build documentation
for JBoss community documents with Publican.

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
%defattr(-,root,root,-)
%doc README
%doc COPYING
%{_datadir}/publican/Common_Content/%{brand}

%changelog
* Tue Oct 19 2010 Rüdiger Landmann <r.landmann@redhat.com> 1.4-0
- Update CSS and pdf.xsl to accommodate changes in Publican 2.3 common brand

* Tue Sep 7 2010 Rüdiger Landmann <r.landmann@redhat.com> 1.3-0
- add trademark notice for MySQL per Pamela Chestek <pchestek@redhat.com>
- Extend callout graphics to 40 -- BZ #629804 <r.landmann@redhat.com>

* Mon Jul 5 2010 Jeff Fearn <jfearn@redhat.com> 1.2
- Port to Publican 2

* Thu Mar 25 2010 Rüdiger Landmann <r.landmann@redhat.com> 1.1
- add trademark notices for XFS and Java per Pamela Chestek <pchestek@redhat.com>
* Mon Feb 15 2010  Rüdiger Landmann <r.landmann@redhat.com> 1.0-0
- bump version number for release
* Mon Feb 15 2010  Rüdiger Landmann <r.landmann@redhat.com> 0.16
- another monospaced font fix
* Mon Feb 15 2010  Rüdiger Landmann <r.landmann@redhat.com> 0.15
- tweak some headings to match JDocBook styles that use H2 in places where Publican uses H1
* Mon Feb 15 2010  Rüdiger Landmann <r.landmann@redhat.com> 0.14
- monospaced fonts for screens and programlistings
* Thu Feb 4 2010  Rüdiger Landmann <r.landmann@redhat.com> 0.13
- resize title_logo.svg
* Thu Feb 4 2010  James Cobb <jcobb@redhat.com> 0.12
- replace title_logo.svg
* Wed Feb 3 2010  Rüdiger Landmann <r.landmann@redhat.com> 0.11
- make body text ragged right
* Tue Feb 2 2010  Rüdiger Landmann <r.landmann@redhat.com> 0.10
- Tweak pdf.xsl to match JDocBook
* Mon Feb 1 2010  James Cobb <jcobb@redhat.com> 0.9
- CSS fix for gradient in draft docs
* Tue Jan 12 2010  Rüdiger Landmann <r.landmann@redhat.com> 0.8
- Revert to original draft background, fine tune title logo
* Mon Jan 11 2010  James Cobb <jcobb@redhat.com> 0.7
- fine-tune CSS, change title logo, add more images
* Tue Dec 8 2009  Jeff Fearn <jfearn@redhat.com> 0.6
- fine-tune CSS and title SVG
* Fri Nov 27 2009  Rüdiger Landmann <r.landmann@redhat.com> 0.5
- Import more CSS from documentation.css -- not tested
* Fri Nov 27 2009  Ryan Lerch <rlerch@redhat.com> 0.4
- Tweak CSS
* Thu Nov 26 2009  Rüdiger Landmann <r.landmann@redhat.com> 0.3
- More CSS
* Thu Nov 26 2009  Rüdiger Landmann <r.landmann@redhat.com> 0.2
- Add title logo in SVG format
- Initial tweak of CSS
* Wed Nov 25 2009  Rüdiger Landmann <r.landmann@redhat.com> 0.1
- Created brand

