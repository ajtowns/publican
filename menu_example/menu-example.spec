Name:		menu-example
Version:	0
Release:	8%{?dist}.t1
Summary:	Example of how to do a documentation menu package
Group:		Development/Tools
License:	GPLv2+
URL:		http://engineering.redhat.com
Source0:	%{name}-%{version}.tgz
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch

%description
Example of how to do a documentation menu package

%prep
%setup -q

%build

%install
rm -rf %{buildroot}
mkdir -p $RPM_BUILD_ROOT%{_datadir}/desktop-directories
mkdir -p $RPM_BUILD_ROOT/etc/xdg/menus/settings-merged

install -m644 menu-example.directory $RPM_BUILD_ROOT%{_datadir}/desktop-directories/menu-example.directory
install -m644 menu-example.menu $RPM_BUILD_ROOT%{_sysconfdir}/xdg/menus/settings-merged/menu-example.menu

%{_fixperms} $RPM_BUILD_ROOT/*

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%doc README
%{_datadir}/desktop-directories/menu-example.directory
%config(noreplace) %{_sysconfdir}/xdg/menus/settings-merged/menu-example.menu

%changelog
* Tue Nov 23 2010 Jeff Fearn <jfearn@redhat.com> 0-8
- Creation

