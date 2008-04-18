%define brand JBoss

Name:		publican-jboss
Summary:	Common documentation files for %{brand}
Version:	0.12
Release:	0.t3%{?dist}
License:	Creative Commons Attribution-NonCommercial-ShareAlike
Group:		Applications/Text
Buildroot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Buildarch:	noarch
Source:		http://svn.fedorahosted.org/svn/publican/trunk/Files/%{name}-%{version}.tgz
Requires:	publican
BuildRequires:	publican
URL:		https://fedorahosted.org/publican
Obsoletes:	documentation-devel-%{brand}

%description
This package provides common files and templates needed to build documentation
for %{brand} with publican.

%prep
%setup -q 

%build
%{__make} Common_Content

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p -m755 $RPM_BUILD_ROOT%{_datadir}/publican//Templates
mkdir -p -m755 $RPM_BUILD_ROOT%{_datadir}/publican/make
cp -rf Common_Content $RPM_BUILD_ROOT%{_datadir}/publican/
cp -rf Book_Template $RPM_BUILD_ROOT%{_datadir}/publican/Templates/%{brand}-Book_Template
install -m 755 make/Makefile.%{brand} $RPM_BUILD_ROOT%{_datadir}/publican/make/.

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc README
%doc COPYING
%{_datadir}/publican/Common_Content/%{brand}
%{_datadir}/publican/Templates/%{brand}-Book_Template
%{_datadir}/publican/make/Makefile.%{brand}

%changelog
* Mon Apr 14 2008 Jeff Fearn <jfearn@redhat.com> 0.13-0
- Fix missing list image in html-single articles
- QANDA set css fix BZ #442674

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
