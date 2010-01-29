%define brand freeipa

Name:		publican-freeipa
Summary:	Common documentation files for %{brand}
Version:	1.3
Release:	0%{?dist}
License:	CC-BY-SA
Group:		Applications/Text
Buildroot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Buildarch:	noarch
Source:		https://fedorahosted.org/releases/p/u/publican/publican-freeipa-%{version}.tgz
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
%defattr(-,root,root,-)
%doc README
%doc COPYING
%{_datadir}/publican/Common_Content/%{brand}

%changelog
* Thu Jan 29 2010 Máirín Duffy <duffy@redhat.com>  1.3
 - replace SVG of title logo
* Thu Jan 21 2010 Rüdiger Landmann <r.landmann@redhat.com> 1.2
 - rm placeholder images
* Thu Jan 21 2010 Rüdiger Landmann <r.landmann@redhat.com> 1.1
 - rebuild spec file
 - update license to CC-BY-SA
 - add placeholder SVG of title logo
 - add pdf.xsl for green headings
* Wed Jan 20 2010 David O'Brien <davido@redhat.com> 1.0
 - port to publican 1.0
* Tue Jun 02 2009 David O'Brien <davido@redhat.com> 0.7
 - fixed typos in Document Conventions
 - removed some condition tags
* Wed May 13 2009 David O'Brien <davido@redhat.com> 0.6
 - fixed errors in condition tags
* Wed May 13 2009 David O'Brien <davido@redhat.com> 0.5
 - added conditions and updated Bugzilla links in Feedback.xml
* Tue May 12 2009 David O'Brien <davido@redhat.com> 0.4
 - updated link to Bugzilla in Feedback.xml to point directly to freeipa product
* Tue Apr 28 2009 David O'Brien <davido@redhat.com> 0.3
 - added local and updated Conventions.xml
* Fri Apr 23 2009 David O'Brien <davido@redhat.com> 0.2
 - updated freeIPA logo on title page to avoid perception of being off-centre
* Mon Apr 13 2009  David O'Brien <davido@redhat.com> 0.1
- Created using oVirt 0.7 as a template
