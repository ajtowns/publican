REAL_BRAND	= JBoss
BRAND	= jboss
SPEC	= publican-$(BRAND).spec
NAME	= publican-$(BRAND)
VERSION = $(shell grep 'Version:' $(SPEC) | sed -e 's/Version:\s*\(.*\)$$/\1/g')
RELEASE = $(shell grep 'Release:' $(SPEC) | sed -e 's/Release:\s*\(.*\)$$/\1/g' | sed -e 's/...dist.//')
PWD		= $(shell pwd)
RPMDIR	=  $(PWD)/tmp/rpm
OS_VER = $(shell uname -a | sed -e 's/^.*\.\(...\)[^\.]*\#.*$$/\1/')

TAR_NAME = $(NAME)-$(VERSION)
LANGS = as-IN bn-IN de-DE es-ES fr-FR gu-IN hi-IN it-IT ja-JP kn-IN ko-KR ml-IN mr-IN or-IN pa-IN pt-BR ru-RU si-LK ta-IN te-IN zh-CN zh-TW

FILES	= pot README Makefile $(LANGS) en-US Book_Template Article_Template Set_Template COPYING make xsl

local: srpm
	@echo "Start $@"
	@rpmbuild --define "dist .$(OS_VER)" --define "_topdir $(RPMDIR)" -bb $(RPMDIR)/SPECS/$(SPEC)
	@sudo rpm -Uvh $(RPMDIR)/RPMS/noarch/$(TAR_NAME)-$(RELEASE).$(OS_VER).noarch.rpm
	@echo "End $@"

srpm: dist
	@echo "Start $@"
	@mkdir -p $(RPMDIR)
	@cd $(RPMDIR) && mkdir -p  SPECS  SRPMS BUILD SOURCES RPMS/noarch
	@cp $(TAR_NAME).tgz $(RPMDIR)/SOURCES/.
	@cp publican-$(BRAND).spec $(RPMDIR)/SPECS/.
	@rpmbuild --define "dist .el4" --define "_topdir $(RPMDIR)" -bs $(RPMDIR)/SPECS/publican-$(BRAND).spec
	@rpmbuild --define "dist .el5" --define "_topdir $(RPMDIR)" -bs $(RPMDIR)/SPECS/publican-$(BRAND).spec
	@rpmbuild --define "dist .fc9" --define "_topdir $(RPMDIR)" -bs $(RPMDIR)/SPECS/publican-$(BRAND).spec
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

ENT2POT		= entity2pot
PO2ENTITY	= po2entity

update-pot:
	@echo "Start $@"
	@mkdir -p pot
	@if [ -f en-US/Translatable-Entities.ent ]; then \
		$(ENT2POT) en-US/Translatable-Entities.ent > pot/Translatable-Entities.pot;\
	fi
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

resync-po:: clean
	@echo "Start $@"
	@echo  "	Exporting PO files from $(SOURCE)/$(VERSION)"
	@mkdir -p tmp/SVN
	@pushd tmp/SVN  > /dev/null; \
		svn export $(SOURCE)/$(VERSION) gui_strings; \
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
	sed -i -e 's/@BRAND@/$(REAL_BRAND)/g' tmp/$(VERSION)/Makefile
	sed -i -e 's/@OTHER_LANGS@/$(LANGS)/g' tmp/$(VERSION)/Makefile
	perl -p -i -e 's|\@SOFTWARE_SOURCE\@|$(SOFTWARE_SOURCE)|g' tmp/$(VERSION)/Makefile
	make -C tmp/$(VERSION) update-po-all
	cp pot/*.pot tmp/$(VERSION)/pot/.
	find . -name *.po | sed -e 's/\.\///g' | xargs -i{} cp {} tmp/$(VERSION)/{}
	make -C tmp/$(VERSION) update-po-all
	make -C tmp/$(VERSION) clean
	rm tmp/$(VERSION)/pot/messages.mo
	cd tmp && svn import -m"initial import of $(NAME) $(VERSION)" $(VERSION) $(SOURCE)/$(VERSION)
	@echo "End $@" 

#######################################################################################
#
#	Common Content specific things
#
#######################################################################################


entities::
	@echo "Start $@"
	@mkdir -p $(PWD)/Common_Content/$(REAL_BRAND)/en-US
	@cp $(PWD)/en-US/*.ent $(PWD)/Common_Content/$(REAL_BRAND)/en-US/.
	@if [ -f en-US/Translatable-Entities.ent ]; then \
		pushd en-US > /dev/null; \
		for lang in $(LANGS); do \
			if [ ! -d $(PWD)/Common_Content/$(REAL_BRAND)/$$lang ]; then \
				mkdir -p $(PWD)/Common_Content/$(REAL_BRAND)/$$lang; \
			fi; \
			if [ ! -f ../$$lang/Translatable-Entities.po ]; then \
				echo "../$$lang/Translatable-Entities.po MISSING Using en-US file"; \
				cp Translatable-Entities.ent $(PWD)/Common_Content/common/$$lang/.; \
			else \
				$(PO2ENTITY) Translatable-Entities.ent ../$$lang/Translatable-Entities.po > $(PWD)/Common_Content/$(REAL_BRAND)/$$lang/Translatable-Entities.ent; \
			fi; \
		done; \
		popd > /dev/null; \
	fi
	@echo "End $@"

Common_Content:: entities
	@echo "Start $@"
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

