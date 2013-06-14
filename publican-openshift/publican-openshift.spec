%define brand OpenShift
%define wwwdir /var/www/html/docs

Name:		publican-openshift
Summary:	Common documentation files for %{brand}
Version:	0.18
Release:	1%{?dist}
License:	CC-BY-SA
Group:		Applications/Text
Buildroot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:   noarch
Source:		https://fedorahosted.org/releases/p/u/publican/publican-openshift-%{version}.tgz
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
publican build --formats=xml --langs=en-US --publish

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
* Fri Jun 14 2013 Rüdiger Landmann <r.landmann@redhat.com> 0.18-1
- SVG fixes

* Thu Jun 13 2013 Bilhar Aulakh <baulakh@redhat.com> 0.17-2
- Added separate logo images for Online and Enterprise in SVG format for PDF builds

* Tue Jun 11 2013 Bilhar Aulakh <baulakh@redhat.com> 0.16-1
- Added separate logo images for Online and Enterprise

* Tue Jun 11 2013 Bilhar Aulakh <baulakh@redhat.com> 0.15-1
- Updated Feedback to remove broken kbase link
- Updated OpenShift logos

* Mon Jun 3 2013 Rüdiger Landmann <r.landmann@redhat.com> 0.14-1
- revise legal notice per rfontana

* Tue Nov 20 2012 Bilhar Aulakh <baulakh@redhat.com> 0.13-1
- updated Legal Notice to include OpenShift trademark

* Mon Jul 2 2012 David O'Brien <davido@redhat.com> 0.12-1
- updated logos

* Tue Jun 26 2012 David O'Brien <davido@redhat.com> 0.11-1
- Update text of Feedback.xml

* Thu Mar 8 2012 Rüdiger Landmann <rlandman@redhat.com> 0.10-1
- Correct colours in web styles

* Wed Mar 7 2012 Rüdiger Landmann <rlandman@redhat.com> 0.9-1
- Convert brand to Publican 3.0

* Wed Feb 15 2012 David O'Brien <davido@redhat.com> 0.8-3
- Updated links to OpenShift public website.

* Wed Feb 15 2012 David O'Brien <davido@redhat.com> 0.7-3
- Fix docbook tags in Feedback.xml.

* Wed Feb 15 2012 David O'Brien <davido@redhat.com> 0.6-1
- Reformat table col widths.
- Add link to doc component in Bugzilla for bug reporting.

* Fri Dec 16 2011 David O'Brien <davido@redhat.com> 0.5-1
- Change "Express" and "Flex" table headings to include "OpenShift" prefix.

* Thu Jun 2 2011 David O'Brien <davido@redhat.com> 0.4-3
- Replace spaces with tabs as field label separators.

* Wed Jun 1 2011 David O'Brien <davido@redhat.com> 0.4-1
- Update OpenShift terminology.
- Adjust Overview structure.

* Thu May 26 2011  Rüdiger Landmann <r.landmann@redhat.com> 0.3-1
- Adjust styles and graphics.

* Wed May 25 2011  David O'Brien <davido@redhat.com> 0.2-1
- Updated bug reporting options.

* Fri May 20 2011 David O'Brien <davido@redhat.com> 0.1-1
- Created Brand.
- Added common files for express and flex.
- Updated support options.

