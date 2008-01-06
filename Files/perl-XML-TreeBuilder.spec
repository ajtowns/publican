# $Id$
# Authority: dag
# Upstream: Sean M. Burke <sburke$cpan,org>

%define perl_vendorlib %(eval "`%{__perl} -V:installvendorlib`"; echo $installvendorlib)
%define perl_vendorarch %(eval "`%{__perl} -V:installvendorarch`"; echo $installvendorarch)

%define real_name XML-TreeBuilder

Summary: Perl module that implements a parser that builds a tree of XML::Element objects
Name: perl-XML-TreeBuilder
Version: 3.10
Release: 2%{?dist}
License: GPL+ or Artistic
Group: Development/Languages
URL: http://search.cpan.org/dist/XML-TreeBuilder/

Source: http://www.cpan.org/modules/by-module/XML/XML-TreeBuilder-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root

BuildArch: noarch
BuildRequires: perl
BuildRequires: perl(ExtUtils::MakeMaker)

%description
perl-XML-TreeBuilder is a Perl module that implements a parser
that builds a tree of XML::Element objects.

%prep
%setup -q -n %{real_name}-%{version}

%build
%{__perl} Makefile.PL INSTALLDIRS="vendor" OPTIMIZE="$RPM_OPT_FLAGS"
%{__make} %{?_smp_mflags}

%install
%{__rm} -rf %{buildroot}
%{__make} pure_install

### Clean up buildroot
find %{buildroot} -name .packlist -exec %{__rm} {} \;

%clean
%{__rm} -rf %{buildroot}

%files
%defattr(-, root, root, 0755)
%doc Changes README
%doc %{_mandir}/man3/XML::Element.3pm*
%doc %{_mandir}/man3/XML::TreeBuilder.3pm*
%dir %{perl_vendorlib}/XML/
%{perl_vendorlib}/XML/Element.pm
%{perl_vendorlib}/XML/TreeBuilder.pm

%changelog
* Mon Jan 07 2008 Jeff Fearn <jfearn@redhat.com> - 3.10-2
- Tidy spec file

* Wed Dec 12 2007 Jeff Fearn <jfearn@redhat.com> - 3.10-0
- Add dist param
- Add NoExpand to allow entities to pass thru un-expanded

* Fri May 04 2007 Dag Wieers <dag@wieers.com> - 3.09-1
- Initial package. (using DAR)
