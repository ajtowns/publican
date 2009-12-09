%define brand jboss-community-hibernate

Name:		publican-jboss-community-hibernate
Summary:	Common documentation files for Hibernate community documents
Version:	0.4
Release:	0%{?dist}
License:	SETUP: Set This
Group:		Applications/Text
Buildroot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Buildarch:	noarch
Source:		https://fedorahosted.org/releases/publican/%{name}-%{version}.tgz
Requires:	publican >= 1.0
BuildRequires:	publican >= 1.0
URL:		https://publican.fedorahosted.org/

%description
This package provides common files and templates needed to build documentation
for Hibernate community documents with Publican.

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
* Tue Dec 8 2009  Jeff Fearn <r.landmann@redhat.com> 0.4
- fine-tune title SVG
* Tue Dec 8 2009  Jeff Fearn <jfearn@redhat.com> 0.3
- fine-tune CSS
* Mon Nov 30 2009  Rüdiger Landmann <r.landmann@redhat.com> 0.2
- Tweak CSS
* Mon Nov 30 2009  Rüdiger Landmann <r.landmann@redhat.com> 0.1
- Created brand

