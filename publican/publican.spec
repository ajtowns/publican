
# Track font name changes
%define RHEL5 %(test %{?dist} == .el5 && echo 1 || echo 0)
%define RHEL6 %(test %{?dist} == .el6 && echo 1 || echo 0)
# Assume not rhel means FC11+ ... ugly
%define OTHER 1
%if %{RHEL6}
%define OTHER 0
%endif
%if %{RHEL5}
%define OTHER 0
%endif

# who doesn't have xdg-open?
%define HTMLVIEW %{RHEL5}

# required for desktop file install
%define my_vendor %(test %{OTHER} == 1 && echo "fedora" || echo "redhat")

%define TESTS 0

Name:           publican
Version:        2.99
Release:        0%{?dist}.t24
Summary:        Common files and scripts for publishing with DocBook XML
# For a breakdown of the licensing, refer to LICENSE
License:        (GPLv2+ or Artistic) and CC0
Group:          Applications/Publishing
URL:            https://publican.fedorahosted.org
Source0:        https://fedorahosted.org/released/publican/Publican-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
# Limited to these arches on RHEL 6 due to PDF + Java limitations
%if %{RHEL6}
BuildArch:      i386 x86_64
%else
BuildArch:      noarch
%endif

# Get rid of the old packages
Obsoletes:      perl-Publican-WebSite
Obsoletes:      publican-WebSite-obsoletes
Conflicts: perl-Publican-WebSite
Conflicts: publican-WebSite-obsoletes
# Do NOT support very old packages
#Provides:       perl-Publican-WebSite = 1.5
#Provides:       publican-WebSite-obsoletes = 1.21

BuildRequires:  perl(Devel::Cover)
BuildRequires:  perl(Module::Build)
BuildRequires:  perl(Test::Exception)
BuildRequires:  perl(Test::More)
BuildRequires:  perl(Test::Pod)
BuildRequires:  perl(Test::Pod::Coverage)
BuildRequires:  perl(Test::Perl::Critic)
BuildRequires:  perl(Archive::Tar)
BuildRequires:  perl(Archive::Zip)
BuildRequires:  perl(Carp)
BuildRequires:  perl(Config::Simple)
BuildRequires:  perl(Cwd)
BuildRequires:  perl(Data::Dumper)
BuildRequires:  perl(DateTime)
BuildRequires:  perl(DateTime::Format::DateParse)
BuildRequires:  perl(Encode)
BuildRequires:  perl(File::Copy::Recursive)
BuildRequires:  perl(File::Find)
BuildRequires:  perl(File::Find::Rule)
BuildRequires:  perl(File::HomeDir)
BuildRequires:  perl(File::Inplace)
BuildRequires:  perl(File::Path)
BuildRequires:  perl(File::pushd)
BuildRequires:  perl(HTML::FormatText)
BuildRequires:  perl(HTML::TreeBuilder)
BuildRequires:  perl(I18N::LangTags::List)
BuildRequires:  perl(Image::Magick)
BuildRequires:  perl(Image::Size)
BuildRequires:  perl(Locale::Maketext::Gettext)
BuildRequires:  perl(Locale::Language)
BuildRequires:  perl(Locale::PO)
BuildRequires:  perl(Makefile::Parser)
BuildRequires:  perl(Syntax::Highlight::Engine::Kate)
BuildRequires:  perl(Term::ANSIColor)
BuildRequires:  perl(Text::Wrap)
BuildRequires:  perl(Test::Pod)
BuildRequires:  perl(version)
BuildRequires:  perl(XML::LibXML)  >=  1.67
BuildRequires:  perl(XML::LibXSLT) >=  1.67
BuildRequires:  perl(XML::Simple)
BuildRequires:  perl(XML::TreeBuilder) >= 4.0
BuildRequires:  fop >= 0.95
BuildRequires:  batik
BuildRequires:  docbook-style-xsl >= 1.75.2-5
BuildRequires:  desktop-file-utils
BuildRequires:  perl-Template-Toolkit
BuildRequires:  perl(DBD::SQLite)

# Most of these are handled automatically
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))
Requires:       perl(Locale::Maketext::Gettext)
Requires:       fop >= 0.95
Requires:       batik rpm-build
Requires:       docbook-style-xsl >= 1.75.2-5
Requires:       perl(XML::LibXML)  >=  1.67
Requires:       perl(XML::LibXSLT) >=  1.67
Requires:       perl(XML::TreeBuilder) >= 4.0
Requires:       cvs
Requires:       perl-Template-Toolkit
Requires:       perl(DBD::SQLite)

# Lets validate some basics
Requires:       rpmlint

# Pull in the fonts for all languages, else you can't build translated PDF in brew/koji
%if %{RHEL5}
Requires:       fonts-bengali fonts-chinese fonts-chinese-zysong fonts-gujarati
Requires:       fonts-hindi fonts-japanese fonts-kannada fonts-korean
Requires:       fonts-malayalam fonts-oriya fonts-punjabi fonts-sinhala
Requires:       fonts-tamil fonts-telugu liberation-fonts
BuildRequires:  fonts-bengali fonts-chinese fonts-chinese-zysong fonts-gujarati
BuildRequires:  fonts-hindi fonts-japanese fonts-kannada fonts-korean
BuildRequires:  fonts-malayalam fonts-oriya fonts-punjabi fonts-sinhala
BuildRequires:  fonts-tamil fonts-telugu liberation-fonts
#BuildRequires:  java-1.5.0-sun java-1.5.0-sun-devel chkconfig
%endif
%if %{RHEL6}
Requires:       liberation-mono-fonts liberation-sans-fonts liberation-serif-fonts
Requires:       cjkuni-uming-fonts ipa-gothic-fonts ipa-pgothic-fonts
Requires:       lklug-fonts baekmuk-ttf-batang-fonts

BuildRequires:  liberation-mono-fonts liberation-sans-fonts liberation-serif-fonts
BuildRequires:  cjkuni-uming-fonts ipa-gothic-fonts ipa-pgothic-fonts
BuildRequires:  lklug-fonts baekmuk-ttf-batang-fonts
%endif
%if %{OTHER}
Requires:       liberation-mono-fonts liberation-sans-fonts liberation-serif-fonts
Requires:       cjkuni-uming-fonts ipa-gothic-fonts ipa-pgothic-fonts
Requires:       lklug-fonts baekmuk-ttf-batang-fonts

BuildRequires:  liberation-mono-fonts liberation-sans-fonts liberation-serif-fonts
BuildRequires:  cjkuni-uming-fonts ipa-gothic-fonts ipa-pgothic-fonts
BuildRequires:  lklug-fonts baekmuk-ttf-batang-fonts
%endif

Obsoletes:      Publican < 1.0
# Do NOT support very old packages
#Provides:       Publican = 1.0

%description
Publican is a DocBook publication system, not just a DocBook processing tool.
As well as ensuring your DocBook XML is valid, publican works to ensure
your XML is up to publishable standard.

%package doc
Group:          Documentation
Summary:        Documentation for the Publican package
%if %{HTMLVIEW}
Requires:       htmlview
%else
Requires:       xdg-utils
%endif
Obsoletes:      Publican-doc < 1.0
# Do NOT support very old packages
#Provides:       Publican-doc = 1.0

%description doc
Publican is a tool for publishing material authored in DocBook XML.
This guide explains how to  to create and build books and articles
using publican. It is not a DocBook XML tutorial and concentrates
solely on using the publican tools.

%prep
%setup -q -n Publican-%{version}

%build
%{__perl} Build.PL installdirs=vendor
./Build
dir=`pwd` && cd Users_Guide && perl -I $dir/blib/lib $dir/blib/script/publican build \
    --formats=html-desktop --publish --langs=all \
    --common_config="$dir/blib/datadir" \
    --common_content="$dir/blib/datadir/Common_Content"

%install
rm -rf $RPM_BUILD_ROOT

./Build install destdir=$RPM_BUILD_ROOT create_packlist=0
find $RPM_BUILD_ROOT -depth -type d -exec rmdir {} 2>/dev/null \;

%{_fixperms} $RPM_BUILD_ROOT/*

./fop-ttc-metric.pl --outdir $RPM_BUILD_ROOT%{_datadir}/publican/fop/font-metrics --conffile $RPM_BUILD_ROOT%{_datadir}/publican/fop/fop.xconf

sed -i -e 's|@@FILE@@|%{_docdir}/%{name}-doc-%{version}/en-US/index.html|' %{name}.desktop
sed -i -e 's|@@ICON@@|%{_docdir}/%{name}-doc-%{version}/en-US/images/icon.svg|' %{name}.desktop

%if %{HTMLVIEW}
sed -i -e 's|xdg-open|htmlview|' %{name}.desktop
%endif

desktop-file-install --vendor="%{my_vendor}" --dir=$RPM_BUILD_ROOT%{_datadir}/applications %{name}.desktop

for file in po/*.po; do
    lang=`echo "$file" | sed -e 's/po\/\(.*\)\.po/\1/'`;
    mkdir -p $RPM_BUILD_ROOT%{_datadir}/locale/$lang/LC_MESSAGES;
    msgfmt $file -o $RPM_BUILD_ROOT%{_datadir}/locale/$lang/LC_MESSAGES/%{name}.mo;
done

%find_lang %{name}

%check
%if %{TESTS}
./Build test
%endif

%clean
rm -rf $RPM_BUILD_ROOT

%files -f %{name}.lang
%defattr(-,root,root,-)
%doc Changes README COPYING Artistic
%{perl_vendorlib}/Publican.pm
%{perl_vendorlib}/Publican/*
%{_mandir}/man3/Publican*
%{_mandir}/man1/*
%{_bindir}/publican
%{_datadir}/publican
%config(noreplace) %{_datadir}/publican/default.db
%config(noreplace) %verify(not md5 size mtime) %{_sysconfdir}/publican-website.cfg
%config(noreplace) %{_sysconfdir}/bash_completion.d/_publican

%files doc
%defattr(-,root,root,-)
%doc Users_Guide/publish/desktop/*
%{_datadir}/applications/%{my_vendor}-%{name}.desktop
%doc fdl.txt

%changelog
* Thu Dec 09 2010 Jeff Fearn <jfearn@redhat.com> 3.0-1
- new upstream package.

