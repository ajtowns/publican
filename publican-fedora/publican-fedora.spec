%define brand fedora
%define real_release 1

Name:		publican-%{brand}
Summary:	Common documentation files for %{brand}
Version:	0.7
Release:	%{real_release}%{?dist}
License:	Open Publication License
Group:		Applications/Text
Buildroot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Buildarch:	noarch
Source:		http://svn.fedorahosted.org/svn/documentation-devel/trunk/Files/%{name}-%{version}-%{real_release}.tgz
Requires(post): coreutils
Requires(postun): coreutils
Requires:	publican
BuildRequires:	publican
URL:		https://fedorahosted.org/documentation-devel
Obsoletes:	documentation-devel-Fedora
Provides:	documentation-devel-Fedora

%description
Common files for building %{brand} documentation.

%prep
%setup -q

%build
%{__make} Common_Content

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p -m755 $RPM_BUILD_ROOT%{_datadir}/publican/Templates
cp -rf Common_Content $RPM_BUILD_ROOT%{_datadir}/publican/
cp -rf Book_Template $RPM_BUILD_ROOT%{_datadir}/publican/Templates/%{brand}-Book_Template

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc README
%doc opl.txt
%{_datadir}/publican/Common_Content/%{brand}
%{_datadir}/publican/Templates/%{brand}-Book_Template

%changelog
* Tue Feb 12 2008 Jeff Fearn <jfearn@redhat.com> 0.8-0
- Setup per Brand Book_Templates
- Fix soure and URL paths
- Use release in source
- add OPL text

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
