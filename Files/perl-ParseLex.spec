#
%define pkgname ParseLex
%define filelist %{pkgname}-%{version}-filelist
%define NVR %{pkgname}-%{version}-%{release}
%define maketest 0
name:	perl-ParseLex
summary:	ParseLex - Perl module
version:	2.15
release:	5%{?dist}
vendor:    Timo Trinks <ttrinks@redhat.com>
packager:  Red Hat Engineering Services <https://engineering.redhat.com/rt3>
license:	GPL
group:	Applications/CPAN
url:	http://www.cpan.org
buildroot:	%{_tmppath}/%{name}-%{version}-%(id -u -n)
buildarch:	noarch
source: http://www.cpan.org/authors/id/P/PV/PVERD/ParseLex-2.15.tar.gz
Patch0: ParseLex-2.15-syntax.patch

%description
None.
#
#
%prep
%setup -q -n %{pkgname}-%{version} 
chmod -R u+w %{_builddir}/%{pkgname}-%{version}
%patch0 -p1

%build
CFLAGS="$RPM_OPT_FLAGS"
%{__perl} Makefile.PL `%{__perl} -MExtUtils::MakeMaker -e ' print qq|PREFIX=%{buildroot}%{_prefix}| if \$ExtUtils::MakeMaker::VERSION =~ /5\.9[1-6]|6\.0[0-5]/ '`
%{__make} 
%if %maketest
%{__make} test
%endif
%install
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}
%{makeinstall} `%{__perl} -MExtUtils::MakeMaker -e ' print \$ExtUtils::MakeMaker::VERSION <= 6.05 ? qq|PREFIX=%{buildroot}%{_prefix}| : qq|DESTDIR=%{buildroot}| '`
[ -x /usr/lib/rpm/brp-compress ] && /usr/lib/rpm/brp-compress
# SuSE Linux
if [ -e /etc/SuSE-release ]; then
%{__mkdir_p} %{buildroot}/var/adm/perl-modules
%{__cat} `find %{buildroot} -name "perllocal.pod"`  \
| %{__sed} -e s+%{buildroot}++g                 \
> %{buildroot}/var/adm/perl-modules/%{name}
fi
# remove special files
find %{buildroot} -name "perllocal.pod" \
-o -name ".packlist"                \
-o -name "*.bs"                     \
|xargs -i rm -f {}
# no empty directories
find %{buildroot}%{_prefix}             \
-type d -depth                      \
-exec rmdir {} \; 2>/dev/null
%{__perl} -MFile::Find -le '
find({ wanted => \&wanted, no_chdir => 1}, "%{buildroot}");
print "%defattr(-,root,root)";
print "%doc  doc Changes examples README";
for my $x (sort @dirs, @files) {
push @ret, $x unless indirs($x);
}
print join "\n", sort @ret;
sub wanted {
return if /auto$/;
local $_ = $File::Find::name;
my $f = $_; s|^%{buildroot}||;
return unless length;
return $files[@files] = $_ if -f $f;
$d = $_;
/\Q$d\E/ && return for reverse sort @INC;
$d =~ /\Q$_\E/ && return
for qw|/etc %_prefix/man %_prefix/bin %_prefix/share|;
$dirs[@dirs] = $_;
}
sub indirs {
my $x = shift;
$x =~ /^\Q$_\E\// && $x ne $_ && return 1 for @dirs;
}
' > %filelist
[ -z %filelist ] && {
echo "ERROR: empty %files listing"
exit -1
}
grep -rsl '^#!.*perl'  doc Changes examples README |
grep -v '.bak$' |xargs --no-run-if-empty \
%__perl -MExtUtils::MakeMaker -e 'MY->fixin(@ARGV)'
%clean
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}
%files -f %filelist
%changelog
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
