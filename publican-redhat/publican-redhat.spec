%define brand RedHat

Name:		publican-redhat
Summary:	Common documentation files for %{brand}
Version:	0.7
Release:	0%{?dist}
License:	Open Publication License + Restrictions
Group:		Applications/Text
Buildroot:	%{_tmppath}/%{name}-%{version}-%(id -u -n)
Buildarch:	noarch
Source:		%{name}-%{version}.tgz
Requires(post): coreutils
Requires(postun): coreutils
Requires:	publican
BuildRequires:	publican
URL:		https://fedorahosted.org/documentation-devel
Obsoletes:	documentation-devel-%{brand}

%description
Common files for building %{brand} documentation.

%prep
%setup -q -n %{name}-%{version} 

%build
%{__make} Common_Content


%install
rm -rf $RPM_BUILD_ROOT
mkdir -p -m755 $RPM_BUILD_ROOT%{_datadir}/publican/
cp -rf Common_Content $RPM_BUILD_ROOT%{_datadir}/publican/

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc README
%{_datadir}/publican/Common_Content/%{brand}

%changelog
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
