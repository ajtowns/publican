%define brand OpenShift
%define pub_name Publican
%define RHEL6 %([[ %{?dist}x == .el6[a-z]* ]] && echo 1 || echo 0)

Name:		publican-openshift
Summary:	Common documentation files for %{brand}
Version:	0.8
Release:	3%{?dist}
License:	CC-BY-SA
Group:		Applications/Text
Buildroot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
# Limited to these arches on RHEL 6 due to PDF + Java limitations
%if %{RHEL6}
ExclusiveArch:	i686 x86_64
%else
BuildArch:	noarch
%endif
Source:		https://fedorahosted.org/releases/p/u/publican/publican-openshift-%{version}.tgz
BuildRequires:	publican >= 2.5
Requires:	publican >= 2.5
URL:		https://fedorahosted.org/publican

%description
This package provides common files and templates needed to build documentation
for %{brand} with publican.

%prep
%setup -q 

%build
publican build --formats=xml --langs=en-US --publish

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

