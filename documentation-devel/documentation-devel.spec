Name:		documentation-devel
Summary:	Common files and scripts for building Documentation
Version:	0.25
Release:	0.t4%{?dist}
License:	GPL
Group:		Applications/Text
Buildroot:	%{_tmppath}/%{name}-%{version}-%(id -u -n)
Buildarch:	noarch
Source:		%{name}-%{version}.tgz
Requires(post): coreutils
Requires(postun): coreutils
Requires:	gettext libxslt kdesdk dejavu-lgc-fonts
BuildRequires:	gettext libxslt kdesdk perl(XML::TreeBuilder)
URL:		https://fedorahosted.org/documentation-devel

# postuff docbook-style-xsl

# These are the font Req's for PDF creation in FOP ... not sure when we should enable these
# WARNING: We will also need to have a seperate fop.conf file for RHEL5 due to different font paths :(
# RHEL 4 | 5 fonts

# RHEL 4 fonts
# /usr/share/fonts/ja/TrueType/kochi-mincho-subst.ttf RHEL5 fonts-japanese
#Requires:	ttfonts-ja
# /usr/share/fonts/ko/TrueType/batang.ttf
#Requires:	ttfonts-ko
# /usr/share/fonts/zh_CN/TrueType/zysong.ttf
#Requires:	ttfonts-zh_CN
# /usr/share/fonts/bn/lohit_bn.ttf
#Requires:	ttfonts-bn
# /usr/share/fonts/ta/lohit_ta.ttf
#Requires:	ttfonts-ta
# /usr/share/fonts/pa/lohit_pa.ttf
#Requires:	ttfonts-pa
# /usr/share/fonts/hi/lohit_hi.ttf
#Requires:	ttfonts-hi
# /usr/share/fonts/gu/lohit_gu.ttf
#Requires:	ttfonts-gu
# /usr/share/fonts/zh_TW/TrueType/bsmi00lp.ttf
#Requires:	ttfonts-zh_TW

# RHEL 5 fonts
# /usr/share/fonts/ja/TrueType/kochi-mincho-subst.ttf
#Requires:	fonts-japanese
# /usr/share/fonts/ko/TrueType/batang.ttf  RHEL5 /usr/share/fonts/korean/TrueType/batang.ttf
#Requires:	fonts-korean
# /usr/share/fonts/zh_CN/TrueType/zysong.ttf
#Requires:	fonts-chinese
# /usr/share/onts/bn/lohit_bn.ttf RHEL5 /usr/share/fonts/bengali/lohit_bn.ttf
#Requires:	fonts-bengali
# /usr/share/fonts/ta/lohit_ta.ttf RHEL5 /usr/share/fonts/tamil/lohit_ta.ttf
#Requires:	fonts-tamil
# /usr/share/fonts/pa/lohit_pa.ttf RHEl5 /usr/share/fonts/punjabi/lohit_pa.ttf
#Requires:	fonts-punjabi
# /usr/share/fonts/hi/lohit_hi.ttf RHEl5 /usr/share/fonts/hindi/lohit_hi.ttf
#Requires:	fonts-hindi
# /usr/share/fonts/gu/lohit_gu.ttf RHEL5 /usr/share/fonts/gujarati/lohit_gu.ttf
#Requires:	fonts-gujarati
# /usr/share/fonts/zh_TW/TrueType/bsmi00lp.ttf RHEL5 /usr/share/fonts/zh_TW/TrueType/bsmi00lp.ttf
#Requires:	fonts-chinese

# When we get fop packaged properly
# BUG BUG fop 0.20.5 isn't packaged for RHEL5 yet :(
# BUG BUG Fedora is using 0.94 which is broken in different ways than 0.20.5
#	which will require major reworking of the custom xsl
#Requires:	fop = 0.20.5 

%description
Common files and scripts for building Red Hat documentation.

%prep
%setup -q -n %{name}-%{version} 

%build
%{__make} docs

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p -m755 $RPM_BUILD_ROOT%{_usr}/share/%{name}
mkdir -p -m755 $RPM_BUILD_ROOT/usr/share/applications
mkdir -p -m755 $RPM_BUILD_ROOT/%{_prefix}/bin
#cp -rf bin $RPM_BUILD_ROOT%{_usr}/share/%{name}/bin
install -m 755 bin/create_book $RPM_BUILD_ROOT/%{_prefix}/bin/create_book
install -m 755 bin/entity2pot $RPM_BUILD_ROOT/%{_prefix}/bin/entity2pot
install -m 755 bin/mkxpot $RPM_BUILD_ROOT/%{_prefix}/bin/mkxpot
install -m 755 bin/msgxmerge $RPM_BUILD_ROOT/%{_prefix}/bin/msgxmerge
install -m 755 bin/po2entity $RPM_BUILD_ROOT/%{_prefix}/bin/po2entity
install -m 755 bin/po2xlf $RPM_BUILD_ROOT/%{_prefix}/bin/po2xlf
install -m 755 bin/po2sgml $RPM_BUILD_ROOT/%{_prefix}/bin/po2sgml
install -m 755 bin/potmerge $RPM_BUILD_ROOT/%{_prefix}/bin/potmerge
install -m 755 bin/poxmerge $RPM_BUILD_ROOT/%{_prefix}/bin/poxmerge
install -m 755 bin/rmImages $RPM_BUILD_ROOT/%{_prefix}/bin/rmImages
install -m 755 bin/StSe_Reports $RPM_BUILD_ROOT/%{_prefix}/bin/StSe_Reports
install -m 755 bin/xlf2pot $RPM_BUILD_ROOT/%{_prefix}/bin/xlf2pot
install -m 755 bin/xmlClean $RPM_BUILD_ROOT/%{_prefix}/bin/xmlClean
cp -rf fop $RPM_BUILD_ROOT%{_usr}/share/%{name}/fop
cp -rf make $RPM_BUILD_ROOT%{_usr}/share/%{name}/make
cp -rf xsl $RPM_BUILD_ROOT%{_usr}/share/%{name}/xsl
cp -rf Common_Content $RPM_BUILD_ROOT%{_usr}/share/%{name}/Common_Content
cp -rf templates $RPM_BUILD_ROOT%{_usr}/share/%{name}/templates
cp -rf Book_Template $RPM_BUILD_ROOT%{_usr}/share/%{name}/Book_Template

# TODO This should be automated
cat > $RPM_BUILD_ROOT/%{_usr}/share/applications/%{name}.desktop <<'EOF'
[Desktop Entry]
Name=Documentation Devel
Comment=How to use Documentation Devel
Exec=yelp %{_docdir}/%{name}-%{version}/en-US/index.html
Icon=%{_docdir}/%{name}-%{version}/en-US/images/icon.svg
Categories=Documentation;X-Red-Hat-Base;
Type=Application
Encoding=UTF-8
Terminal=false
EOF

%clean
rm -rf $RPM_BUILD_ROOT

%post

%postun

%preun

%files
%defattr(-,root,root)
%doc README
%doc docs/*
%{_usr}/share/%{name}
%{_prefix}/bin/create_book
%{_prefix}/bin/entity2pot
%{_prefix}/bin/mkxpot
%{_prefix}/bin/msgxmerge
%{_prefix}/bin/po2entity
%{_prefix}/bin/po2xlf
%{_prefix}/bin/po2sgml
%{_prefix}/bin/potmerge
%{_prefix}/bin/poxmerge
%{_prefix}/bin/rmImages
%{_prefix}/bin/StSe_Reports
%{_prefix}/bin/xlf2pot
%{_prefix}/bin/xmlClean
%{_usr}/share/applications/%{name}.desktop

%changelog
* Wed Jan 02 2008 Jeff Fearn <jfearn@redhat.com> 0.26
- Added CHUNK_SECTION_DEPTH param to allow chunk.section.depth override. BZ #427172
- Fixed EXTRA_DIRS to ignore .svn dirs, Added svn_add_po target BZ #427178
- Fixed "uninitialized value" error when product not set BZ #426038
- Fixed Brand not updating. BZ #426043

* Tue Dec 11 2007 Jeff Fearn <jfearn@redhat.com> 0.25
- Add html.longdesc.embed xsl param to allow long descriptions of images to be embedded in html output
- Remove Boilerplate files as ther are dupes of Legal_Notice
- Added BRAND Makefile param to allow branding books.
- renamed redhat.xsl to defaults.xsl
- Fixed product not being updated in Makefile when using create_book BZ #391491
- Removed embedded font from English PDFs as it Breaks searching
- Added user documentation
- create_book: fixed version and revision not working
- Added dist target to create tar & spec files for desktop rpms
- Made desktop rpms use html-single BZ #351731
- Removed gnome-doc-utils dep
- Removed docbook-style-xsl dep
- Removed perl-SGML-Translate dep
- Removed unused Config::Simple module
- Switch from Template to HTML::Template as it's already in Fedora
- Switched xlf2pot from XML::SimpleObject to XML::TreeBuilder
- Added error messages for invalid VERSION or RELEASE
- Changed Default PRODUCT to Documentation
- Added warning for default PRODUCT
- Differentiated brands
- rename rhlogo.png title_logo.png
- removed unused images
- cleaned build process

* Tue Nov 6 2007 Jeff Fearn <jfearn@redhat.com> 0.24
- Fix bug with calling translation report script.

* Mon Nov 5 2007 Jeff Fearn <jfearn@redhat.com> 0.23
- Add postuff to validate po files
- Add test-po-<LANG> targets to use po-validateXML from postuff
- Fixed error msgs in poxmerge
- Fix bug with directory creation for deeply nested po files
- Fixed bug where Common files could not access <bookname>.ent file BZ #322721
- Add entity for root using <systemitem class='username'>
- Added create_book command and files to allow local creation of new books
- Added SHOW_REMARKS make param to control display of remark tags
- Added OASIS dtd in xml for Kate users
- Sort image list for bin/rmImages to aid readability
- Modified padding and margins between figures and their titles
- Added DejaVuLGCSansMono font metrics
- Added DejaVuLGCSans Oblique metrics
- Added missing dejavu-lgc-fonts dep
- Added build message when copying Product Specific common files
- Move local entity to first position so it overrides common entity files
- Added missing DocBook tags to xmlClean:
- 	accel blockquote classname code colophon envar example footnote
- 	guisubmenu interface keycap keycombo literal literallayout option
- 	parameter prompt property see seealso substeps systemitem wordasword
- 	glossary glossdiv glosssee glossseealso
- Moved executables in to bin directory.
- Fixed layout of formal para titles in PDF
- Removed trunctaion and elipses from title used for page headers

* Wed Oct 3 2007 Jeff Fearn <jfearn@redhat.com> 0.22
- Add handling of extras directory
- Fix Russian PDF font problem

* Tue Sep 25 2007 Jeff Fearn <jfearn@redhat.com> 0.21
- Modified screen and programlisting to force closing tag to be on it's own.
- Added cmdsynopsis, arg, articleinfo, article, informaltable, group to xmlClean.
- Added CHUNK_FIRST to allow per book control of first section chunking.
-  Defaults to 1, first sections will be on their own page.
- Fix warning message on po files with no entries
- added role as class to orderedlist, itemizedlist, ulink, article
- Fixed po files in sub directories not being merged correctly
- Add website specific css

* Tue Aug 28 2007 Jeff Fearn <jfearn@redhat.com> 0.20
- Added IGNORED_TRANSLATIONS to allow users to replace the chosen languages with
-  the default langauge text when building
- fix bug where build would fail if $(XML_LANG)/images did not exist
- Fix bug with rpm downgrade
- fixed CSS bug for preformatted text when rendered inside inside an example.

* Tue Aug 28 2007 Jeff Fearn <jfearn@redhat.com> 0.19
- Add missing targets to help output
- Add missing variables to help_params output
- Improve help and help_params text
- Changed entity RHCRTSVER to 8.0 from 7.3
- Add DejaVuLGCSans back as Liberation is broken and Russian requires DejaVuLGCSans
- Modify Makefile to pull PO files from translation CVS
- Ensure Legal_Notice.po[t] is never used
- Add a warning message for GUI_String update-pot
- Fix Bug in GUI String publish targets
- Converted reports from hard coded HTML to Templates
- Publish GUI_String translation reports to same location as documentation reports.

* Thu Aug 16 2007 Jeff Fearn <jfearn@redhat.com> 0.18
- Use ghelp to enable localised menus (BZ #249829)
- Fix broken if in subpackage.xsl
- Fix Icon missing from menu

* Mon Aug 13 2007 Jeff Fearn <jfearn@redhat.com> 0.17
- Remove unused PUB_DIR make variable
- Remove 'redhat-' from FOP common paths
- Improve help text.
- Add error message for trying to build language without po files
- Added error message for trying to report on a language with no PO files
- Added error message for trying to build reports without POT files

* Fri Jun 29 2007 Jeff Fearn <jfearn@redhat.com> 0.16
- Added img.src.path to admon.graphics.path
- Moved header.navigation and footer.navigation from xhtml-common to main-html
- Removed 'redhat' from name
- Remove NOCHUNK param, Added html-single targets
- Added eclipse support
- removed xmlto Requires
- added Legal_Notice.xml for future books. Boilerplate.xml remains for back compatibility.
- Fix rpm link creation
- Added creation of format specific rpms
- Added rmImages script to remove unused images from build directory
- Removed per Product content directories
- default version to 0

* Wed Jun 27 2007 Jeff Fearn <jfearn@redhat.com> 0.15
- remove id from list-labels in questions & answers (duplicate id bug) 
- Fixed bogus publish path for Reports

* Wed Jun 27 2007 Jeff Fearn <jfearn@redhat.com> 0.14
- Added test-all target
- Disabled Hyphenation in FOP, zh PDFs hanging service

* Tue Jun 26 2007 Joshua Wulf <jwulf@redhat.com> 0.13
- Added JBEAP and JBEAPVER entities
- Optimised spec file creation

* Mon Jun 25 2007 Jeff Fearn <jfearn@redhat.com> 0.12
- Fix css rule that broke links

* Tue May 08 2007 Jeff Fearn <jfearn@redhat.com> 0.11
- add DocBook 4.5 DTD to package
- add DocBook 1.72.0 xsl to package
- modify makefiles to use new DocBook catalogs
- xmlClean:
- 	Changed DTD from 4.3 to 4.5
- 	Added bookname to node id's to help avoid id clashes in sets
- 	Fixed line wrap issue in PDF generation for zh-CN and zh-TW
- 	Enforced validation of xml on all build targets
- 	Add legalnotice tag 
- 	Add address tag 
- 	Add street tag 
- 	Add city tag 
- 	Add state tag 
- 	Add postcode tag 
- 	Add country tag 
- 	Add phone tag 
- 	Add fax tag 
- 	Add pob tag 
- 	Add preface tag 
- 	Add bibliograpy related tags 
- 	Add qandaset related tags 
- Removed Confidential image and restyle confidential html text
- Added po2xlf script
- Added xlf2po script
- Added perl-XML-SimpleObject to Requires, used in xliff code
- Fixed Makefile.GUI updating po file for source lang
- Updated custom xml to match 1.72 docbook xsl
- Removed MuktiNarrow fonts - using lohit-bn
- Removed ZYSong18030 & ARPLSungtiLGB fonts - unused
- Modified Publish output line in logfile to be a URL
- Fixed creation of translated srpm
- Added Liberation fonts for PDF
- Removed DejaVuLGCSans fonts
- Turned on Line Wrap for monospace verbatim elements
- Moved entity SELinux from Translatable to Entities.ent, updated po files
- Added Legal_Notice to common
- Moved balance of non-translatable entities out of Translatable-entities.ent, updated po files
- Added missing Req perl-SGML-Translate, used for translation reports

* Tue May 01 2007 Jeff Fearn <jfearn@redhat.com> 0.10
- fix image dimensions on content/common/en-US/images/redhat-logo.svg
- remove leading space from rpm spec desription
- Made abstract wrap at 72 characters and be left aligned.
-	it's used for the spec description
- Move legal notice link param from xhtml.xsl to main-html so nochunks
-	target will have legal notice embedded in page

* Tue Apr 24 2007 Jeff Fearn <jfearn@redhat.com> 0.9.1
- fix path to xsl <blush>

* Tue Apr 24 2007 Jeff Fearn <jfearn@redhat.com> 0.9
- Fix "Use of uninitialized value in string eq at xmlClean line 272."
- Add facility to prune xml tree based on condition attribute.
- Made COMMON_CONTENT static 

* Tue Apr 17 2007 Jeff Fearn <jfearn@redhat.com> 0.8
- fix non RHEL books not having the PRODUCT name attached to the
-  rpm and specfile to avoid duplicate name problems.
-  e.g. everyone has a Deployment_Guide so non RHEL books must be Fortitude-Deployment_Guide etc.

* Tue Apr 17 2007 Jeff Fearn <jfearn@redhat.com> 0.7
- format temporary fo file as the lines where to long and confused FOP ... grrr
- fixed po files not having links updated when clean_ids is run

* Tue Apr 17 2007 Jeff Fearn <jfearn@redhat.com> 0.6
- fix Book entity file being ignored
- add white space to TOC

* Tue Apr 17 2007 Jeff Fearn <jfearn@redhat.com> 0.5
- Revert to kdesdk (xml2pot) to fix RHEL4 bug where entities would be dropped from pot file.
- Switching to gnome-docs-util creates ~1500 hours of translation work in the
- Deployment Guide alone making the switch impossible at this time :(
- This means inline xml comments will break translation due to a bug in the sdk.
- Added the 4 scripts from doc-tools to bin/* to avoid adding deps.
- Added missing PRODUCT en-US & pot dirs

* Mon Apr 16 2007 Jeff Fearn <jfearn@redhat.com> 0.4
- Fix fop config file
- Roll back font metrics file to fop 0.2 format

* Mon Apr 16 2007 Jeff Fearn <jfearn@redhat.com> 0.3
- Fix xmlClean, clean_ids was note validating xref ids correctly

* Thu Apr 12 2007 Jeff Fearn <jfearn@redhat.com> 0.2
- Fix SYSTEM not being copied to PRODUCT properly
- Fix GUI Strings reports
- Fix GUI Strings css path
- Fix Set targets as per timp@redhat.com fix.

* Wed Apr 11 2007 Jeff Fearn <jfearn@redhat.com> 0.1.19
- Change SYSTEM to PRODUCT as it more clearly defines what it's used for.
- Add content to README
- Fix 'make help' output for Books

* Tue Apr 10 2007 Jeff Fearn <jfearn@redhat.com> 0.1.18
- Fix missing Entity file
- Remove graphic from boilerplate
- Fix fop metric path to meet new package path
- PDF Appendix, URL and title fixes

* Mon Apr 02 2007 Jeff Fearn <jfearn@redhat.com> 0.1.15
- add 'a' to start of ID's that begin with numbers.
- stop DTD entity strings being written in clean_id mode
- fix pdf formatting issues
- Merge Common_Config
- add missing Requirements
- add DejaVuLGCSans for Russian books

* Tue Mar 27 2007 Jeff Fearn <jfearn@redhat.com> 0.1.13
- add appendix and appendix info to xmlClean
- convert all configuration files from fop 0.20.5 to 0.93.0 format.
- remove copying of common configuration directory

* Mon Mar 26 2007 Jeff Fearn <jfearn@redhat.com> 0.1.12
- bump rev for brew build

* Fri Mar 23 2007 Jeff Fearn <jfearn@redhat.com> 0.1.11
- fixed use of dist

* Thu Mar 22 2007 Jeff Fearn <jfearn@redhat.com> 0.1.10
- Switch to using gnome-doc-utils for po manipulation

* Wed Mar 21 2007 Jeff Fearn <jfearn@redhat.com> 0.1.9
- Remove trailing space from text nodes in xmlClean
- add feed back for user

* Tue Mar 20 2007 Jeff Fearn <jfearn@redhat.com> 0.1.8
- Fix re-creation of $cmd variable
- Add support for per arch build

* Mon Mar 19 2007 Jeff Fearn <jfearn@redhat.com> 0.1.6
- Fix path for reports script

* Wed Feb 07 2007 Jeff Fearn <jfearn@redhat.com> 0.0
- Initial creation
