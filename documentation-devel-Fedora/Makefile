BRAND	= Fedora
SPEC	= documentation-devel-$(BRAND).spec
NAME	= documentation-devel-$(BRAND)
VERSION = $(shell grep 'Version:' $(SPEC) | sed -e 's/Version:\s*\(.*\)$$/\1/g')
RELEASE = $(shell grep 'Release:' $(SPEC) | sed -e 's/Release:\s*\(.*\)$$/\1/g' | sed -e 's/...dist.//')
PWD		= $(shell pwd)
RPMDIR	=  $(PWD)/tmp/rpm
OS_VER = $(shell uname -a | sed -e 's/^.*\.\(...\)[^\.]*\#.*$$/\1/')
REAL_RPMDIR = $(shell grep topdir ~/.rpmmacros | sed -e 's/^.*topdir[ \t]*\([^ \t]*\)$$/\1/')

TAR_NAME = $(NAME)-$(VERSION)
LANGS = as-IN bn-IN de-DE es-ES fr-FR gu-IN hi-IN it-IT ja-JP kn-IN ko-KR ml-IN mr-IN or-IN pa-IN pt-BR ru-RU si-LK ta-IN te-IN zh-CN zh-TW

FILES	= pot README Makefile $(LANGS) en-US

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
	@cp documentation-devel-$(BRAND).spec $(RPMDIR)/SPECS/.
	@rpmbuild --define "dist .el4" --define "_topdir $(RPMDIR)" -bs $(RPMDIR)/SPECS/documentation-devel-$(BRAND).spec
	@rpmbuild --define "dist .el5" --define "_topdir $(RPMDIR)" -bs $(RPMDIR)/SPECS/documentation-devel-$(BRAND).spec
	@rpmbuild --define "dist .fc9" --define "_topdir $(RPMDIR)" -bs $(RPMDIR)/SPECS/documentation-devel-$(BRAND).spec
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

clean:
	@echo "Start $@"
	@rm -rf $(NAME)-* *.tgz Common_Content tmp
	@echo "End $@"

#######################################################################################
#
#	Common Content specific things
#
#######################################################################################

ENT2POT		= entity2pot
PO2ENTITY	= po2entity

# This is seperate so we enforce only 1 translatable entity file in common content.
update-pot:
	@echo "Start $@"
	@mkdir -p pot
	@if [ -f en-US/Translatable-Entities.ent ]; then \
		$(ENT2POT) en-US/Translatable-Entities.ent > pot/Translatable-Entities.pot;\
	fi
	@pushd en-US > /dev/null; \
		for xml_file in `find . -maxdepth 1 -name "*.xml"`; do \
			pot_file=`echo $$xml_file | sed -e 's/\.xml/\.pot/'`;\
			xml2pot $$xml_file | msguniq  > ../pot/$$pot_file;\
		done; \
	popd  > /dev/null;
	@echo "End $@"

CVS_ROOT = cvs.devel.redhat.com:/cvs/ecs
CVS_REPO = GUI_Strings/documentation-devel-RHEL

resync-po:: clean
	@echo "Start $@"
	@echo  "	Exporting PO files from $(CVS_ROOT)/$(CVS_REPO)"
	@mkdir -p tmp/CVS
	@pushd tmp/CVS  > /dev/null; \
		cvs -d $(CVS_ROOT) export -r HEAD $(CVS_REPO); \
	popd > /dev/null;
	@echo "	Copying PO files"
	@pushd tmp/CVS/$(CVS_REPO)  > /dev/null; \
		find . -name Legal_Notice.po | xargs --no-run-if-empty rm;\
		find . -name *.po | sed -e 's/\.\///g' | xargs -i{} cp {} $(PWD)/{}; \
	popd > /dev/null;
	@echo "End $@"

entities::
	@echo "Start $@"
	@mkdir -p $(PWD)/Common_Content/$(BRAND)/en-US
	@cp $(PWD)/en-US/*.ent $(PWD)/Common_Content/$(BRAND)/en-US/.
	@if [ -f en-US/Translatable-Entities.ent ]; then \
		pushd en-US > /dev/null; \
		for lang in $(LANGS); do \
			if [ ! -d $(PWD)/Common_Content/$(BRAND)/$$lang ]; then \
				mkdir -p $(PWD)/Common_Content/$(BRAND)/$$lang; \
			fi; \
			if [ ! -f ../$$lang/Translatable-Entities.po ]; then \
				echo "../$$lang/Translatable-Entities.po MISSING Using en-US file"; \
				cp Translatable-Entities.ent $(PWD)/Common_Content/common/$$lang/.; \
			else \
				$(PO2ENTITY) Translatable-Entities.ent ../$$lang/Translatable-Entities.po > $(PWD)/Common_Content/$(BRAND)/$$lang/Translatable-Entities.ent; \
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
				cp $$xml_file $(PWD)/Common_Content/$(BRAND)/$$lang/$$xml_file; \
			else \
				po2xml $$xml_file ../$$lang/$$po_file > $(PWD)/Common_Content/$(BRAND)/$$lang/$$xml_file; \
			fi; \
		done; \
		cp $$xml_file $(PWD)/Common_Content/$(BRAND)/en-US/$$xml_file; \
	done; \
	cd ..; \
	for lang in $(LANGS) en-US; do \
		if [ -d $$lang/css ]; then \
			mkdir -p  $(PWD)/Common_Content/$(BRAND)/$$lang/css; \
			cp -rf $$lang/css/*.css  $(PWD)/Common_Content/$(BRAND)/$$lang/css/.; \
		fi; \
	done; \
	for lang in $(LANGS) en-US; do \
		if [ -d $$lang/images ]; then \
			mkdir -p  $(PWD)/Common_Content/$(BRAND)/$$lang/images; \
			cp -rf $$lang/images/*  $(PWD)/Common_Content/$(BRAND)/$$lang/images/.; \
		fi; \
	done; \
	cd $(PWD);
	@echo "End $@"



