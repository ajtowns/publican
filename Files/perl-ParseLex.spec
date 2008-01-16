Name:		perl-ParseLex
Summary:	ParseLex - Perl module
Version:	2.15
Release:	8%{?dist}
License:	GPL+ or Artistic
Group:		Development/Libraries
URL:		http://search.cpan.org/dist/ParseLex
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-root%(%{__id_u} -n)
BuildArch:	noarch
Source:		http://www.cpan.org/authors/id/P/PV/PVERD/ParseLex-2.15.tar.gz
# TODO Push patches upstream
Patch0:		ParseLex-2.15-syntax.patch

%description
The classes "Parse::Lex" and "Parse::CLex" create lexical analyzers.

%prep
%setup -q -n ParseLex-%{version} 
%patch0 -p1

# Filter unwanted Provides:
cat << \EOF > ParseLex-prov
#!/bin/sh
%{__perl_provides} $* |\
  sed -e '/perl(unwanted_provide)/d'
EOF

%define __perl_provides %{_builddir}/ParseLex-%{version}/ParseLex-prov
chmod +x %{__perl_provides}

# remove all execute bits from the doc stuff and fix interpreter
# so that dependency generator doesn't try to fulfill deps
find examples -type f -exec chmod -x {} 2>/dev/null ';'
find examples -type f -exec sed -i 's#/usr/local/bin/perl#/usr/bin/perl#' {} 2>/dev/null ';'

%build
%{__perl} Makefile.PL INSTALLDIRS="vendor"
%{__make} %{?_smp_mflags}

%check
%{__make} test

%install
%{__rm} -rf $RPM_BUILD_ROOT
%{__make} pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT create_packlist=0

### Clean up buildroot
find $RPM_BUILD_ROOT -name .packlist -exec %{__rm} {} \;

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-, root, root, -)
%doc Changes README examples
%{perl_vendorlib}/Parse/
%{_mandir}/man3/*.3pm*

%changelog
* Tue Jan 08 2008 Jeff Fearn <jfearn@redhat.com> 2.15-8
- Changed Development/Languages to Development/Libraries
- Fixed test
- Removed useless-explicit-provides
- Converted Changes to utf-8

* Tue Jan 08 2008 Jeff Fearn <jfearn@redhat.com> 2.15-7
- Remove %%doc from man files, used glob
- Simplify Parse in filelist
- Simplify %%clean
- Remove OPTIMIZE setting from make call
- Change buildroot to fedora style
- Remove unused defines

* Mon Jan 07 2008 Jeff Fearn <jfearn@redhat.com> 2.15-6
- Tidy up spec

* Mon Dec 10 2007 Jeff Fearn <jfearn@redhat.com> 2.15-5
- noarch FTW
- add dist to release

* Tue Apr 10 2007 ttrinks@redhat.com
- Rebuilt for RHEL5
- Changed arch from noarch to i386

* Mon Jul 31 2006 mschick@redhat.com
- Tagged for e-s-o repo
- Rebuilt for RHEL4 

* Thu Sep 25 2003 pgampe@redhat.com
- Patch broken syntax in upstream Template.pm
