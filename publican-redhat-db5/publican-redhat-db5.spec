%define brand RedHat-db5
%define wwwdir /var/www/html/docs

Name:		publican-redhat-db5
Summary:	Common documentation files for %{brand}
Version:	3.1
Release:	1%{?dist}
License:	CC-BY-SA
Group:		Applications/Text
Buildroot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Buildarch:	noarch
Source:		%{name}-%{version}.tgz
BuildRequires:	publican
URL:		https://access.redhat.com/knowledge/docs

%description
This package provides common files and templates needed to build documentation
for %{brand} with publican.

%package web
Summary:        Web styles for the %{brand} brand
Group:          Documentation
Requires:	publican

%description web
Web Site common files for the %{brand} brand.

%prep
%setup -q

%build
publican build --formats=xml --langs=all --publish

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p -m755 $RPM_BUILD_ROOT%{_datadir}/publican/Common_Content
publican install_brand --path=$RPM_BUILD_ROOT%{_datadir}/publican/Common_Content
mkdir -p -m755 $RPM_BUILD_ROOT/%{wwwdir}/%{brand}
publican install_brand --web --path=$RPM_BUILD_ROOT/%{wwwdir}/%{brand}


%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc README
%doc COPYING
%{_datadir}/publican/Common_Content/%{brand}

%files web
%defattr(-,root,root,-)
%{wwwdir}/%{brand}

%changelog
* Thu Aug 08 2013 Stephen Gordon <sgordon@redhat.com> 3.1-1
- Rebased from publican-redhat, in particular:
  * Added updated Program_Listing.xml.
  * Updated overrides.css to fix several bugs.
  * Added updated Legal_Notice.xml to pick up Node.js and OpenStack marks.
* Thu Jan 10 2013 Stephen Gordon <sgordon@redhat.com> 1.2-1
- Rebased from publican-redhat.
- Added subtitle.xsl
- Added abstract.xsl
* Thu Jan 10 2013 Stephen Gordon <sgordon@redhat.com> 1.1-2
- Added the fallbacks in again - there were dragons.
* Thu Jan 10 2013 Stephen Gordon <sgordon@redhat.com> 1.1-1
- Added xsl files and stripped fallbacks on Publican's DocBook 4 XML.
* Thu Jan 10 2013 Stephen Gordon <sgordon@redhat.com> 1.0-1
- Created DocBook 5 compatible Red Hat Brand.
- Includes overrides.css tweak for div.author.
- Updated configuration values for DocBook 5.

