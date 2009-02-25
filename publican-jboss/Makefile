REAL_BRAND	= JBoss
BRAND	= jboss
SPEC	= publican-$(BRAND).spec
NAME	= publican-$(BRAND)
VERSION = $(shell grep 'Version:' $(SPEC) | sed -e 's/Version:\s*\(.*\)$$/\1/g')
RELEASE = $(shell grep 'Release:' $(SPEC) | sed -e 's/Release:\s*\(.*\)$$/\1/g' | sed -e 's/...dist.//')
PWD		= $(shell pwd)
RPMDIR	=  $(PWD)/tmp/rpm
OS_VER	?= .$(shell uname -r | perl -p -e 's/^[^a-z]*([a-z]+[0-9]+).*$$/\1/')
VERBOSE	?= 0

TAR_NAME = $(NAME)-$(VERSION)
LANGS = as-IN bn-IN de-DE es-ES fr-FR gu-IN hi-IN it-IT ja-JP kn-IN ko-KR ml-IN mr-IN or-IN pa-IN pt-BR ru-RU si-LK ta-IN te-IN zh-CN zh-TW

FILES	= pot README Makefile $(LANGS) en-US Book_Template Article_Template Set_Template COPYING make xsl

local: srpm
	@echo "Start $@"
	@rpmbuild --define "dist $(OS_VER)" --define "_topdir $(RPMDIR)" -bb $(RPMDIR)/SPECS/$(SPEC)
	@sudo rpm -Uvh $(RPMDIR)/RPMS/noarch/$(TAR_NAME)-$(RELEASE)$(OS_VER).noarch.rpm
	@echo "End $@"

srpm: dist
	@echo "Start $@"
	@mkdir -p $(RPMDIR)
	@cd $(RPMDIR) && mkdir -p  SPECS  SRPMS BUILD SOURCES RPMS/noarch
	@cp $(TAR_NAME).tgz $(RPMDIR)/SOURCES/.
	@cp publican-$(BRAND).spec $(RPMDIR)/SPECS/.
	@rpmbuild --define "dist $(OS_VER)" --define "_topdir $(RPMDIR)" -bs $(RPMDIR)/SPECS/publican-$(BRAND).spec
	@echo "End $@"

dist: clean
	@echo "Start $@"
	@mkdir $(TAR_NAME)
	@for file in $(FILES); do cp -rf $$file $(TAR_NAME);done
	@find $(TAR_NAME) -name ".svn" | xargs rm -rf
	@find $(TAR_NAME) -name ".swp" | xargs rm -rf
	@find $(TAR_NAME) -name "*.mo" | xargs rm -rf
	@find $(TAR_NAME) -name "*~" | xargs rm -rf
	@tar czf $(TAR_NAME).tgz $(TAR_NAME)
	@echo "End $@"

upload-dist: dist
	@scp $(TAR_NAME).tgz fedorahosted.org:publican

clean:
	@echo "Start $@"
	@rm -rf $(NAME)-* *.tgz Common_Content tmp
	@echo "End $@"

#######################################################################################
#
#	Translation specific things
#
#######################################################################################

update-pot:
	@echo "Start $@"
	@mkdir -p pot
	@pushd en-US > /dev/null; \
		for xml_file in `find . -maxdepth 1 -name "*.xml" | grep -v Legal_Notice`; do \
			pot_file=`echo $$xml_file | sed -e 's/\.xml/\.pot/'`;\
			xml2pot $$xml_file | msguniq  > ../pot/$$pot_file;\
		done; \
	popd  > /dev/null;
	@echo "End $@"

# TODO: Get this in to SVN
SOURCE	= https://svn.devel.redhat.com/repos/ecs/Software/$(NAME)
SOFTWARE_SOURCE = http://svn.fedorahosted.org/svn/publican/trunk/$(NAME)/pot
TRANS_VERSION = 0.12
PROD_VERSION = 1.0

resync-po:: clean
	@echo "Start $@"
	@echo  "	Exporting PO files from $(SOURCE)/$(TRANS_VERSION)"
	@mkdir -p tmp/SVN
	@pushd tmp/SVN  > /dev/null; \
		svn export $(SOURCE)/$(TRANS_VERSION) gui_strings; \
	popd > /dev/null;
	@pushd tmp/SVN/gui_strings  > /dev/null; \
		find . -name *.po | sed -e 's/\.\///g' | xargs -i{} cp {} $(PWD)/{}; \
	popd > /dev/null;
	@echo "End $@"

create_l10n:: clean
	@echo "Start $@"
	mkdir -p tmp/$(VERSION)/pot
	cp ../publican/make/Makefile.l10n tmp/$(VERSION)/Makefile
	sed -i -e 's/@PROGNAME@/$(NAME)/g' tmp/$(VERSION)/Makefile
	sed -i -e 's/@PRODUCT@/$(NAME)/g' tmp/$(VERSION)/Makefile
	sed -i -e 's/@PROD_VERSION@/$(PROD_VERSION)/g' tmp/$(VERSION)/Makefile
	sed -i -e 's/@BRAND@/$(REAL_BRAND)/g' tmp/$(VERSION)/Makefile
	sed -i -e 's/@OTHER_LANGS@/$(LANGS)/g' tmp/$(VERSION)/Makefile
	perl -p -i -e 's|\@SOFTWARE_SOURCE\@|$(SOFTWARE_SOURCE)|g' tmp/$(VERSION)/Makefile
	make -C tmp/$(VERSION) update-po-all
	cp pot/*.pot tmp/$(VERSION)/pot/.
	find . -name *.po | sed -e 's/\.\///g' | xargs -i{} cp {} tmp/$(VERSION)/{}
	make -C tmp/$(VERSION) update-po-all
	make -C tmp/$(VERSION) clean
	rm tmp/$(VERSION)/pot/messages.mo
#	cd tmp && svn import -m"initial import of $(NAME) $(VERSION)" $(VERSION) $(SOURCE)/$(VERSION)
	@echo "End $@" 

commit_l10n:
	cd tmp && svn import -m"initial import of $(NAME) $(VERSION)" $(VERSION) $(SOURCE)/$(VERSION)

#######################################################################################
#
#	Common Content specific things
#
#######################################################################################

Common_Content::
	@echo "Start $@"
	@for lang in $(LANGS) en-US; do \
		mkdir -p $(PWD)/Common_Content/$(REAL_BRAND)/$$lang; \
		foo=`echo "$$lang" | cut -f 1 -d '-'`; \
		pushd $(PWD)/Common_Content/$(REAL_BRAND) > /dev/null; \
		ln -s $$lang $$foo; \
		popd > /dev/null; \
	done
	@cd en-US; \
	for xml_file in `find . -maxdepth 1 -name "*.xml"`; do \
		po_file=`echo $$xml_file | sed -e 's/\.xml/\.po/'`; \
		for lang in $(LANGS); do \
			if [ ! -f ../$$lang/$$po_file ]; then \
				echo "../$$lang/$$po_file MISSING Using en-US file"; \
				cp $$xml_file $(PWD)/Common_Content/$(REAL_BRAND)/$$lang/$$xml_file; \
			else \
				po2xml $$xml_file ../$$lang/$$po_file > $(PWD)/Common_Content/$(REAL_BRAND)/$$lang/$$xml_file; \
			fi; \
		done; \
		cp $$xml_file $(PWD)/Common_Content/$(REAL_BRAND)/en-US/$$xml_file; \
	done; \
	cd ..; \
	for lang in $(LANGS) en-US; do \
		if [ -d $$lang/css ]; then \
			mkdir -p  $(PWD)/Common_Content/$(REAL_BRAND)/$$lang/css; \
			cp -rf $$lang/css/*.css  $(PWD)/Common_Content/$(REAL_BRAND)/$$lang/css/.; \
		fi; \
	done; \
	for lang in $(LANGS) en-US; do \
		if [ -d $$lang/images ]; then \
			mkdir -p  $(PWD)/Common_Content/$(REAL_BRAND)/$$lang/images; \
			cp -rf $$lang/images/*  $(PWD)/Common_Content/$(REAL_BRAND)/$$lang/images/.; \
		fi; \
	done; \
	cd $(PWD);
	@echo "End $@"

clean_ids:
	@echo "START: $@ `date`"
	@cd en-US && \
	for file in `find . -name "*.xml" | sed -e 's/^\.\///' | sort`; do \
		echo "	$$file"; \
		xmlClean -strict 1 -U -in $$file -out $$file -book $(REAL_BRAND) -cleanids ; \
	done && cd ..;
	@echo "END: $@ `date`"

