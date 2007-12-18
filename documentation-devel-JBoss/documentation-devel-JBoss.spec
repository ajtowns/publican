%define brand JBoss

Name:		documentation-devel-%{brand}
Summary:	Common documentation files for %{brand}
Version:	0.3
Release:	0%{?dist}
License:	Creative Commons Attribution-NonCommercial-ShareAlike
Group:		Applications/Text
Buildroot:	%{_tmppath}/%{name}-%{version}-%(id -u -n)
Buildarch:	noarch
Source:		%{name}-%{version}.tgz
Requires(post): coreutils
Requires(postun): coreutils
Requires:	documentation-devel
BuildRequires:	documentation-devel
URL:		https://fedorahosted.org/documentation-devel

%description
Common files for building %{brand} documentation.

%prep
%setup -q -n %{name}-%{version} 

%build
%{__make} Common_Content

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p -m755 $RPM_BUILD_ROOT%{_usr}/share/documentation-devel/
cp -rf Common_Content $RPM_BUILD_ROOT%{_usr}/share/documentation-devel/

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc README
%{_usr}/share/documentation-devel/Common_Content/%{brand}

%changelog
* Fri Jul 13 2007 Jeff Fearn <jfearn@redhat.com> 0.3-0
- Update

* Fri Jul 13 2007 Jeff Fearn <jfearn@redhat.com> 0.1-0
- Initial creation
