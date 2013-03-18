
# Track font name changes
%define RHEL6 %([[ %{?dist}x == .el6[a-z]* ]] && echo 1 || echo 0)

%define OTHER 1
%if %{RHEL6}
%define OTHER 0
%endif

# required for desktop file install
%define my_vendor %(test %{OTHER} == 1 && echo "fedora" || echo "redhat")

%define TESTS 1
%define brand common
%define wwwdir /var/www/html/docs

Name:           publican
Version:        3.1.5
Release:        0%{?dist}
Summary:        Common files and scripts for publishing with DocBook XML
# For a breakdown of the licensing, refer to LICENSE
License:        (GPLv2+ or Artistic) and CC0
Group:          Applications/Publishing
URL:            https://publican.fedorahosted.org
Source0:        https://fedorahosted.org/released/publican/Publican-v%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch

# Get rid of the old packages
Obsoletes:      perl-Publican-WebSite
Obsoletes:      publican-WebSite-obsoletes
Conflicts:      perl-Publican-WebSite
Conflicts:      publican-WebSite-obsoletes

## work around arch -> noarch bug in yum
Obsoletes:      publican < 3

BuildRequires:  perl(Devel::Cover)
BuildRequires:  perl(Module::Build)
BuildRequires:  perl(Test::More)
BuildRequires:  perl(Test::Pod) => 1.14
BuildRequires:  perl(Test::Pod::Coverage) => 1.04
BuildRequires:  perl(Archive::Tar)
BuildRequires:  perl(Archive::Zip)
BuildRequires:  perl(Locale::Maketext::Gettext) >= 1.27-1.2
BuildRequires:  perl(Carp)
BuildRequires:  perl(Config::Simple)
BuildRequires:  perl(Cwd)
BuildRequires:  perl(DateTime)
BuildRequires:  perl(DateTime::Format::DateParse)
BuildRequires:  perl(DBI)
BuildRequires:  perl(Encode)
BuildRequires:  perl(File::Basename)
BuildRequires:  perl(File::Copy::Recursive) => 0.38
BuildRequires:  perl(File::Find)
BuildRequires:  perl(File::Find::Rule)
BuildRequires:  perl(File::HomeDir)
BuildRequires:  perl(File::Inplace)
BuildRequires:  perl(File::Path)
BuildRequires:  perl(File::pushd)
BuildRequires:  perl(File::Spec)
BuildRequires:  perl(File::Which)
BuildRequires:  perl(Getopt::Long)
BuildRequires:  perl(HTML::FormatText)
BuildRequires:  perl(HTML::FormatText::WithLinks)
BuildRequires:  perl(HTML::FormatText::WithLinks::AndTables) >= 0.02
BuildRequires:  perl(HTML::TreeBuilder)
BuildRequires:  perl(I18N::LangTags::List)
BuildRequires:  perl(IO::String)
BuildRequires:  perl(List::MoreUtils)
BuildRequires:  perl(List::Util)
BuildRequires:  perl(Locale::Language)
BuildRequires:  perl(Locale::PO)
BuildRequires:  perl(Module::Build)
BuildRequires:  perl(Pod::Usage)
BuildRequires:  perl(String::Similarity)
BuildRequires:  perl(Syntax::Highlight::Engine::Kate)
BuildRequires:  perl(Template)
BuildRequires:  perl(Template::Constants)
BuildRequires:  perl(Term::ANSIColor)
BuildRequires:  perl(Text::Wrap)
BuildRequires:  perl(Time::localtime)
BuildRequires:  perl(XML::LibXML) => 1.67
BuildRequires:  perl(XML::LibXSLT) => 1.67
BuildRequires:  perl(XML::Simple)
BuildRequires:  perl(XML::TreeBuilder) => 4.0
BuildRequires:  wkhtmltopdf >= 0.10.0_rc2-5
BuildRequires:  docbook-style-xsl >= 1.77.1
BuildRequires:  desktop-file-utils
BuildRequires:  gettext
BuildRequires:  perl(Text::CSV_XS)
BuildRequires:  perl(Sort::Versions)
BuildRequires:  perl(DBD::SQLite)

# Most of these are handled automatically
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))
Requires:       perl(Locale::Maketext::Gettext)  >= 1.27-1.2
Requires:       wkhtmltopdf >= 0.10.0_rc2-5
Requires:       rpm-build
Requires:       docbook-style-xsl >= 1.77.1
Requires:       perl(XML::LibXML)  >=  1.67
Requires:       perl(XML::LibXSLT) >=  1.67
Requires:       perl(XML::TreeBuilder) >= 4.0
Requires:       perl-Template-Toolkit
Requires:       perl(DBD::SQLite)
Requires:       perl(Text::CSV_XS)

# Lets validate some basics
Requires:       rpmlint

# Pull in the fonts for all languages, else you can't build translated PDF in brew/koji
%if %{RHEL6}
Requires:       liberation-mono-fonts liberation-sans-fonts liberation-serif-fonts
Requires:       cjkuni-uming-fonts ipa-gothic-fonts ipa-pgothic-fonts
Requires:       lklug-fonts baekmuk-ttf-batang-fonts
Requires:       lohit-assamese-fonts lohit-bengali-fonts lohit-devanagari-fonts
Requires:       lohit-gujarati-fonts lohit-hindi-fonts lohit-kannada-fonts
Requires:       lohit-kashmiri-fonts lohit-konkani-fonts lohit-maithili-fonts
Requires:       lohit-malayalam-fonts lohit-marathi-fonts lohit-nepali-fonts
Requires:       lohit-oriya-fonts lohit-punjabi-fonts lohit-sindhi-fonts
Requires:       lohit-tamil-fonts lohit-telugu-fonts dejavu-lgc-sans-mono-fonts
Requires:       dejavu-fonts-common dejavu-serif-fonts dejavu-sans-fonts
Requires:       dejavu-sans-mono-fonts overpass-fonts

BuildRequires:  liberation-mono-fonts liberation-sans-fonts liberation-serif-fonts
BuildRequires:  cjkuni-uming-fonts ipa-gothic-fonts ipa-pgothic-fonts
BuildRequires:  lklug-fonts baekmuk-ttf-batang-fonts
%endif
%if %{OTHER}
Requires:       liberation-mono-fonts liberation-sans-fonts liberation-serif-fonts
Requires:       cjkuni-uming-fonts ipa-gothic-fonts ipa-pgothic-fonts
Requires:       lklug-fonts baekmuk-ttf-batang-fonts overpass-fonts

BuildRequires:  liberation-mono-fonts liberation-sans-fonts liberation-serif-fonts
BuildRequires:  cjkuni-uming-fonts ipa-gothic-fonts ipa-pgothic-fonts
BuildRequires:  lklug-fonts baekmuk-ttf-batang-fonts
%endif

%description
Publican is a DocBook publication system, not just a DocBook processing tool.
As well as ensuring your DocBook XML is valid, publican works to ensure
your XML is up to publishable standard.

%package doc
Group:          Documentation
Summary:        Documentation for the Publican package
Requires:       xdg-utils
Obsoletes:      publican-doc < 3

%description doc
Publican is a tool for publishing material authored in DocBook XML.
This guide explains how to  to create and build books and articles
using publican. It is not a DocBook XML tutorial and concentrates
solely on using the publican tools.

%package common-web
Group:          Documentation
Summary:        Website style for common brand
Requires:       publican

%description common-web
Website style for common brand.

%prep
%setup -q -n Publican-v%{version}

%build
%{__perl} Build.PL installdirs=vendor --nocolours=1
./Build --nocolours=1
dir=`pwd` && cd Users_Guide && %{__perl} -CA -I $dir/blib/lib $dir/blib/script/publican build \
    --formats=html-desktop --publish --langs=all \
    --common_config="$dir/blib/datadir" \
    --common_content="$dir/blib/datadir/Common_Content" --nocolours

%install
rm -rf $RPM_BUILD_ROOT

./Build install destdir=$RPM_BUILD_ROOT create_packlist=0
find $RPM_BUILD_ROOT -depth -type d -exec rmdir {} 2>/dev/null \;

%{_fixperms} $RPM_BUILD_ROOT/*

sed -i -e 's|@@FILE@@|%{_docdir}/%{name}-doc-%{version}/en-US/index.html|' %{name}.desktop
sed -i -e 's|@@ICON@@|%{_docdir}/%{name}-doc-%{version}/en-US/images/icon.svg|' %{name}.desktop

desktop-file-install --vendor="%{my_vendor}" --dir=$RPM_BUILD_ROOT%{_datadir}/applications %{name}.desktop

for file in po/*.po; do
    lang=`echo "$file" | sed -e 's/po\/\(.*\)\.po/\1/'`;
    mkdir -p $RPM_BUILD_ROOT%{_datadir}/locale/$lang/LC_MESSAGES;
    msgfmt $file -o $RPM_BUILD_ROOT%{_datadir}/locale/$lang/LC_MESSAGES/%{name}.mo;
done

%find_lang %{name}

# Package web common files
mkdir -p -m755 $RPM_BUILD_ROOT/%{wwwdir}/%{brand}
dir=`pwd`
cd datadir/Common_Content/common
%{__perl} -CA -I $dir/blib/lib $dir/blib/script/publican install_brand --web --path=$RPM_BUILD_ROOT/%{wwwdir}/%{brand}
cd -

%check
%if %{TESTS}
./Build --nocolours=1 test
%endif

%post
# hack to allow branch directory BZ #800252
CATALOG=%{_sysconfdir}/xml/catalog
%{_bindir}/xmlcatalog --noout --add "rewriteURI" \
 "https://fedorahosted.org/released/publican/xsl/docbook4/" \
 "file://%{_datadir}/publican/xsl/"  $CATALOG

%postun
if [ "$1" = 0 ]; then
  CATALOG=%{_sysconfdir}/xml/catalog
  %{_bindir}/xmlcatalog --noout --del \
   "file://%{_datadir}/publican/xsl/docbook4/" $CATALOG
fi

%clean
rm -rf $RPM_BUILD_ROOT

%files -f %{name}.lang
%defattr(-,root,root,-)
%doc Changes README COPYING Artistic pod1/publican
%{perl_vendorlib}/Publican.pm
%{perl_vendorlib}/Publican
%{_mandir}/man3/Publican*
%{_mandir}/man1/*
%{_bindir}/publican
%{_bindir}/db5-valid
%{_bindir}/db4-2-db5
%{_datadir}/publican
%config(noreplace) %{_datadir}/publican/default.db
%config(noreplace) %verify(not md5 size mtime) %{_sysconfdir}/publican-website.cfg
%config(noreplace) %{_sysconfdir}/bash_completion.d/_publican

%files doc
%defattr(-,root,root,-)
%doc Users_Guide/publish/desktop/*
%{_datadir}/applications/%{my_vendor}-%{name}.desktop
%doc fdl.txt

%files common-web
%defattr(-,root,root,-)
%{wwwdir}/%{brand}


%changelog
* Mon Mar 18 2013 Jeff Fearn <jfearn@redhat.com> 3.1.5-0
- Fix translated PDS encode issue when build from packaged books.

* Tue Mar 12 2013 Jeff Fearn <jfearn@redhat.com> 3.1.4-0
- Fix entities in Book_Info braking build. BZ #917898
- add translations of "Revision History". BZ #918365
- Fix TOC title not translated in PDF. BZ #918365
- Fix translated strings with parameters. BZ #891166
- update translations
- add it-IT translation of PUG via <fedora@marionline.it> BZ #797515

* Fri Feb 22 2013 Jeff Fearn <jfearn@redhat.com> 3.1.3-1
- Fix add_revision breaking XML parser. BZ #912985
- Stronger fix for cover pages causing page number overrun. BZ #912967
- Fix CSS for article front page subtile. BZ #913016

* Mon Feb 18 2013 Jeff Fearn <jfearn@redhat.com> 3.1.2-0
- Fix tests failing when publican not installed. BZ #908956
- Fix broken mr-IN/Conventions.po. BZ #908956
- Fix footnote link unclickable. BZ #909006
- Fix missing translations for common files. BZ #908976
- Fix using edition for version on cover pages. BZ #912180
- Fix nested entities causing XML::TreeBuilder to fail. BZ #912187

* Thu Feb 7 2013 Jeff Fearn <jfearn@redhat.com> 3.1.1-0
-  Fix web site CSS for admonitions. BZ #908539

* Mon Feb 4 2013 Jeff Fearn <jfearn@redhat.com> 3.1.0-2
- Fix translated text

* Mon Feb 4 2013 Jeff Fearn <jfearn@redhat.com> 3.1.0-1
- Warn of failure to chmod/chown.

* Fri Jan 25 2013 Jeff Fearn <jfearn@redhat.com> 3.1.0-0
- new upstream package.

* Wed Oct 31 2012 Jeff Fearn <jfearn@redhat.com> 3.0.0-0
- new upstream package.

