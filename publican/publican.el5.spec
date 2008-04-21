%define	my_vendor redhat

Name:		publican	
Summary:	Common files and scripts for publishing Documentation
Version:	0.33
Release:	0.t52%{?dist}
License:	GPLv2+ and GFDL
# The following directories are licensed under the GFDL:
#	content
#	Book_Template
Group:		Applications/Text
Buildroot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Buildarch:	noarch
Source:		http://svn.fedorahosted.org/svn/publican/trunk/Files/%{name}-%{version}.tgz
# need kdesdk for po2xml & xml2pot
Requires:	gettext libxslt perl(XML::TreeBuilder) dejavu-lgc-fonts elinks
Requires:	%{_bindir}/xml2pot %{_bindir}/po2xml
BuildRequires:	gettext libxslt perl(XML::TreeBuilder)
BuildRequires:	%{_bindir}/xml2pot %{_bindir}/po2xml
BuildRequires:	desktop-file-utils
URL:		https://fedorahosted.org/publican
Obsoletes:	documentation-devel  < 0.26-3
Obsoletes:	perl-SGML-Translate <= 0.37-3

%description
Common files and scripts for publishing documentation.

%package doc
Group:		Documentation
Summary:	Documentation for the Publican package
Requires:	htmlview

%description doc
Documentation for the Publican publishing tool chain.

%prep
%setup -q

%build
%{__make} docs

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p -m755 $RPM_BUILD_ROOT%{_datadir}/%{name}/Templates
mkdir -p -m755 $RPM_BUILD_ROOT%{_datadir}/applications
mkdir -p -m755 $RPM_BUILD_ROOT%{_bindir}
install -m 755 bin/* $RPM_BUILD_ROOT%{_bindir}
%{__perl} -p -i -e 's|^#CATALOGS_OVERRIDE$|CATALOGS\t= XML_CATALOG_FILES="%{_datadir}/%{name}/xsl/docbook/dtd-4.5/catalog.xml %{_datadir}/%{name}/xsl/docbook/1.72.0/catalog.xml"|g' make/Makefile.templates

for i in fop make xsl Common_Content templates; do
	cp -rf $i $RPM_BUILD_ROOT%{_datadir}/%{name}/$i
done
cp -rf Book_Template $RPM_BUILD_ROOT%{_datadir}/%{name}/Templates/common-Book_Template
cp -rf xsl_extras/docbook $RPM_BUILD_ROOT%{_datadir}/publican/xsl/.

sed -i -e 's|@@FILE@@|%{_docdir}/%{name}-doc-%{version}/en-US/index.html|' %{name}.desktop
sed -i -e 's|@@ICON@@|%{_docdir}/%{name}-doc-%{version}/en-US/images/icon.svg|' %{name}.desktop
sed -i -e 's|@@ICON@@|%{_docdir}/%{name}-doc-%{version}/en-US/images/icon.svg|' %{name}.desktop
sed -i -e 's|xdg-open|htmlview|' %{name}.desktop
desktop-file-install --vendor="%{my_vendor}" --dir=$RPM_BUILD_ROOT%{_datadir}/applications %{name}.desktop

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc README
%doc COPYING
%doc fdl.txt
%{_datadir}/%{name}
%{_bindir}/create_book
%{_bindir}/entity2pot
%{_bindir}/mkxpot
%{_bindir}/msgxmerge
%{_bindir}/po2entity
%{_bindir}/po2xlf
%{_bindir}/po2sgml
%{_bindir}/potmerge
%{_bindir}/poxmerge
%{_bindir}/rmImages
%{_bindir}/StSe_Reports
%{_bindir}/xlf2pot
%{_bindir}/xmlClean


%files doc
%doc docs/*
%{_datadir}/applications/%{my_vendor}-%{name}.desktop
%doc fdl.txt

%changelog
* Fri Apr 11 2008 Jeff Fearn <jfearn@redhat.com> 0.34-0
- Fix PO file name missing from translation status report
- Modify xmlClean to output dummy content for empty files
- Default SHOW_UNKNOWN tags off
- Make unset entity warnings more obvious
- Make docs use DESKTOP styles
- Fix missing list image in html-single articles
- Commented out debug output in chunking xsl
- QANDA set html and css fix BZ #442674
- Fix kde requires. BZ #443024

* Mon Apr 7 2008 Jeff Fearn <jfearn@redhat.com> 0.33-0
- Remove release from package name in html desktop spec file
- Removed --nonet from xsltproc call BZ #436342
- Add Desktop css customisations

* Thu Apr 3 2008 Jeff Fearn <jfearn@redhat.com> 0.32-0
- Bump version

* Tue Mar 18 2008 Jeff Fearn <jfearn@redhat.com> 0.31-0
- Fixed Project-Id-Version not being set on PO creation BZ #435401
- Fixed java slowing down every make run BZ #435407
- cleanIds now sets format for imagedata
- Fixed Desktop RPM build errors
- Added param DOC_URL BZ #437705
- Changed Default DOC_URL to publican web site
- Fixed perl-SGML-Translate file conflict
- Removed --nonet from xsltproc call BZ #436342
- Removed extra files logic from spec and xsl files.

* Thu Feb 24 2008 Jeff Fearn <jfearn@redhat.com> 0.30-0
- Added missing Requires perl(XML::TreeBuilder)
- Fix xref to listitem breaking BZ #432574
- Die with a decent warning when an invalid Brand is chosen. BZ #429236
- Modified title page of PDF. BZ #429977
- Fix PDF list white space issue BZ #429237
- Fix PDF ulinks too big for tables BZ #430623
- Allowed rev history to be in any file BZ #297411
- Fix keycap hard to read in admon BZ #369161
- Added per Brand Makefile
- Add per Brand xsl files
- Added Requires elinks (used for formatted text output)
- Handle different FOP versions
- Fix PDF issue with nested images
- Added id_node to clean_ids to use none title nodes for id's BZ #434726
- Fix footnotes being duplicated in wrong chunks BZ #431388
- fixed bold text CSS bug for BZ #430617

* Wed Feb 13 2008 Jeff Fearn <jfearn@redhat.com> 0.29-2
- replace tab in changelog with spaces

* Tue Feb 12 2008 Jeff Fearn <jfearn@redhat.com> 0.29-1
- removed %%post and %%postun as update-desktop-database is
-   for desktop files with mime types
- removed release for source path and tar name
- fixed package name in desktop file to include -doc
- switched from htmlview to xdg-open
- Added xdg-utils requires for doc package

* Tue Feb 12 2008 Jeff Fearn <jfearn@redhat.com> 0.29-0
- Setup per Brand Book_Templates
- Fix soure and URL paths
- Use release in source path
- correct GPL version text and changed file name to COPYING
- dropped Provides
- reordered spec file
- added fdl.txt to tar ball.
- added fdl.txt to doc package

* Mon Feb 11 2008 Jeff Fearn <jfearn@redhat.com> 0.28-0
- Added gpl.txt
- Fix GPL identifier as GPLv2+
- Fixed Build root
- Fix desktop file
- Added Provides for documentation-devel
- Fix dist build target
- Add dist-srpm target
- fix dist failing on missing pot dir
- Put docs in sub package
- Added GFDL to License to cover content and Book_Template directories.
- Included GFDL txt file
- set full path to source

* Thu Feb 07 2008 Jeff Fearn <jfearn@redhat.com> 0.27-0
- Use docbook-style-xsl: this will break formatting.
- Update custom xsl to use docbook-xsl-1.73.2: this will break formatting.
- Remove CATALOGS override
- Remove Red Hat specific clause from Makefile.common
- Fixed invalid xhtml BZ 428931
- Update License to GPL2
- Add GPL2 Header to numerous files

* Fri Feb 01 2008 Jeff Fearn <jfearn@redhat.com> 0.26-5
- renamed from documentation-devil to publican

* Thu Jan 17 2008 Jeff Fearn <jfearn@redhat.com> 0.26-4
- Tidy up %%files, %%build, %%prep and remove comments from spec file.
- Added --atime-preserve to tar command

* Mon Jan 07 2008 Jeff Fearn <jfearn@redhat.com> 0.26-3
- Rename from documentation-devel to documentation-devil

* Mon Jan 07 2008 Jeff Fearn <jfearn@redhat.com> 0.26-2
- tidy spec file

* Wed Jan 02 2008 Jeff Fearn <jfearn@redhat.com> 0.26
- Added CHUNK_SECTION_DEPTH param to allow chunk.section.depth override. BZ #427172
- Fixed EXTRA_DIRS to ignore .svn dirs, Added svn_add_po target. BZ #427178
- Fixed "uninitialized value" error when product not set. BZ #426038
- Fixed Brand not updating. BZ #426043
- Replaced FORMAL-RHI with HOLDER in Book_Template. BZ #426041
- Remove reference to non-existant svg file. BZ #426063
- Override formal.title.properties for PDF. BZ #425894
- Override formal.object.heading for HTML. Fix H5 & H6 css. BZ #425894
- Prepended first 4 characters of tag to IDs to aid Translation. BZ #427312

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
