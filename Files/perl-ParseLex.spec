%define pkgname ParseLex
%define filelist %{pkgname}-%{version}-filelist

Name:	perl-ParseLex
Summary:	ParseLex - Perl module
Version:	2.15
Release:	6%{?dist}
License:	GPL
Group:	Applications/CPAN
URL:	http://search.cpan.org/dist/ParseLex
BuildRoot:	%{_tmppath}/%{name}-%{version}-%(id -u -n)
BuildArch:	noarch
Source: http://www.cpan.org/authors/id/P/PV/PVERD/ParseLex-2.15.tar.gz
Patch0: ParseLex-2.15-syntax.patch

%description
The classes "Parse::Lex" and "Parse::CLex" create lexical analyzers.

%prep
%setup -q -n %{pkgname}-%{version} 
chmod -R u+w %{_builddir}/%{pkgname}-%{version}
%patch0 -p1

%build
%{__perl} Makefile.PL INSTALLDIRS="vendor" PREFIX="%{buildroot}%{_prefix}"
%{__make} %{?_smp_mflags}

#%check
#%{__make} test

%install
%{__rm} -rf %{buildroot}
%{__make} pure_install

### Clean up buildroot
find %{buildroot} -name .packlist -exec %{__rm} {} \;

%clean
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

%files
%defattr(-, root, root, 0755)
%doc Changes README examples
%dir %{perl_vendorlib}/Parse
%{perl_vendorlib}/Parse/*.pm
%doc %{_mandir}/man3/Parse::CLex.3pm.gz
%doc %{_mandir}/man3/Parse::Lex.3pm.gz
%doc %{_mandir}/man3/Parse::LexEvent.3pm.gz
%doc %{_mandir}/man3/Parse::Template.3pm.gz
%doc %{_mandir}/man3/Parse::Token.3pm.gz
%doc %{_mandir}/man3/Parse::YYLex.3pm.gz

%changelog
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
