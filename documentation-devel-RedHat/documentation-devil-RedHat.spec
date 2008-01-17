%define brand RedHat

Name:		documentation-devil-%{brand}
Summary:	Common documentation files for %{brand}
Version:	0.5
Release:	0%{?dist}
License:	Open Publication License + Restrictions
Group:		Applications/Text
Buildroot:	%{_tmppath}/%{name}-%{version}-%(id -u -n)
Buildarch:	noarch
Source:		%{name}-%{version}.tgz
Requires(post): coreutils
Requires(postun): coreutils
Requires:	documentation-devil
BuildRequires:	documentation-devil
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
mkdir -p -m755 $RPM_BUILD_ROOT%{_datadir}/documentation-devil/
cp -rf Common_Content $RPM_BUILD_ROOT%{_datadir}/documentation-devil/

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc README
%{_datadir}/documentation-devil/Common_Content/%{brand}

%changelog
* Thu Jan 17 2008 Jeff Fearn <jfearn@redhat.com> 0.5-0
- Switch from documentation-devel to documentation-devil

* Wed Jan 02 2008 Jeff Fearn <jfearn@redhat.com> 0.4-0
- Default YEAR and HOLDER. BZ #426040

* Fri Jul 20 2007 Jeff Fearn <jfearn@redhat.com> 0.3-0
- Update

* Fri Jul 13 2007 Jeff Fearn <jfearn@redhat.com> 0.1-0
- Initial creation
