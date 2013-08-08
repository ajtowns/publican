
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
Version:        3.2.0
Release:        0%{?dist}
Summary:        Common files and scripts for publishing with DocBook XML
# For a breakdown of the licensing, refer to LICENSE
License:        (GPLv2+ or Artistic) and CC0
Group:          Applications/Publishing
URL:            https://publican.fedorahosted.org
Source0:        https://fedorahosted.org/released/publican/Publican-v%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch
Provides:	publican-common = %{version}
Provides:	publican-common-db5 = %{version}

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
BuildRequires:  perl(Archive::Tar) => 1.84
BuildRequires:  perl(Archive::Zip)
BuildRequires:  perl(Compress::Zlib) => 2.030
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
BuildRequires:  perl(Syntax::Highlight::Engine::Kate) >= 0.07-5
BuildRequires:  perl(Template)
BuildRequires:  perl(Template::Constants)
BuildRequires:  perl(Term::ANSIColor)
BuildRequires:  perl(Text::Wrap)
BuildRequires:  perl(Time::localtime)
BuildRequires:  perl(XML::LibXML) => 1.67
BuildRequires:  perl(XML::LibXSLT) => 1.67
BuildRequires:  perl(XML::Simple)
BuildRequires:  perl(XML::TreeBuilder) => 4.2
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
Requires:       perl(Syntax::Highlight::Engine::Kate) >= 0.07-5

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

%package common-db5-web
Group:          Documentation
Summary:        Website style for common brand for DocBook5 content
Requires:       publican

%description common-db5-web
Website style for common brand for DocBook5 content

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
mkdir -p -m755 $RPM_BUILD_ROOT/%{wwwdir}/common-db5
cd datadir/Common_Content/common-db5
%{__perl} -CA -I $dir/blib/lib $dir/blib/script/publican install_brand --web --path=$RPM_BUILD_ROOT/%{wwwdir}/common-db5
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

%files common-db5-web
%defattr(-,root,root,-)
%{wwwdir}/common-db5

%changelog
* Thu Aug 8 2013 Jeff Fearn <jfearn@redhat.com> 3.2.0-0
  - Add spaces to web-spec.xsl to work around newer libxml2 eating white space in spec files  BZ #982424
  - Fix typos in common content BZ #952490 #974918
  - Stop menu bouncing. BZ #953716
  - Fix ID missing from admonitions. BZ #966494
  - Support corpauthor for PDF. BZ #908666
  - Fix nested block tags breaking translation flow. BZ #909728
  - Fix multiple calls to update_po breaking packaging. BZ #891167
  - Add website labels and translations. BZ #979885
  - Add orgname to block/inline code. BZ #872955
  - Fix get_keywords not using correct info file. BZ #957956
  - Improve web print CSS. BZ #927513
  - Fix pre border in PDF. BZ #905752
  - Fix epub DOCTYPE. BZ #875129
  - Fix step first child style. BZ #971221
  - Fix long link word wrap in PDF. BZ #923481
  - Support case-insensitive "language" attribute. BZ #919474
  - Apply title style patch from Jaromir Hradilek. BZ #924518
  - Expose %book_ver_list to products/versions_index.tmpl. BZ #962643
  - Allow brands to ship web templates. Add site config toc_js. BZ #956935
  - Add pdftool option to build for pdf tool control. BZ #953728
  - Add default mapping for language to locale. BZ #844202
  - Fix ID missing from translated Revision History. BZ #911462
  - Add pub_dir option to override publish directory. BZ #830062
  - Removed show_unknown parameter and associated code. BZ #915428
  - Add img_dir parameter to override images directory. BZ #919481
  - Support all DocBook conditionals. BZ #919486
  - Flag spaces in product number as invalid. BZ #973895
  - Standardized prompts in commands. BZ #880456
  - Updated web_formats publican.cfg info BZ #839141
  - Replaced 'home page' with 'product or version page' BZ #921803
  - Replaced a broken link to CPAN with a working link BZ# 973461
  - Remove duplicate brand files from base install. BZ #966143
  - Add extras_dir parameter to override extras directory. BZ #953998
  - Fix PDF ignoring cover logo. BZ #974353
  - Add trans_drop action to freeze source language for translation. BZ #887707
  - Fix empty pot files not being deleted. BZ #961413
  - Fix long title layout on cover page in PDF. BZ #956934
  - Add Mac OS X Lion installation instructions. BZ# 979229
  - Add file handle limit workaround to FAQ BZ #952476
  - Support CDATA tags. BZ #958343
  - Fix UTF8 image names getting mangled in publish. BZ #953618
  - Add wkhtmltopdf_opts parameter to pass options to wkhtmltopdf. BZ #951290
  - Fix edition missing on PDF cover pages. BZ #956940
  - Support XML in add_revision member. BZ #862465
  - Fix duplicate footnotes in bibliography. BZ #653447
  - Fix Link from footlink to footlink-ref not working in PDF. BZ #909786
  - Fix TOC draft watermark in PDF. BZ #905271
  - Add common-db5 sub package. BZ #958495
  - Support decimals in colwidth & convert exact measures to pixels. BZ #913775
  - Tweak equation formatting. BZ #804531
  - Fix POT-Creation-Date format. BZ #985836
  - Fix site stats report swapping languages and products.
  - Fix web_dir not used for home page packages. BZ #988191
  - Updated web site instructions - BZ#979224

* Mon Mar 18 2013 Jeff Fearn <jfearn@redhat.com> 3.1.5-0
- Fix translated PDF encode issue when build from packaged books. BZ #922618

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

