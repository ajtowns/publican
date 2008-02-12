
#    Copyright (C) 2008 Red Hat, Inc.
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#

NAME	= publican
SPEC	= $(NAME).spec
VERSION = $(shell grep 'Version:' $(SPEC) | sed -e 's/Version:\s*\(.*\)$$/\1/g')
RELEASE = $(shell grep 'define\s*real_release' $(SPEC) | sed -e 's/^.*real_release\s*\(.*\)$$/\1/g')
PWD	= $(shell pwd)
RPMDIR	=  $(PWD)/tmp/rpm
OS_VER	= $(shell uname -a | sed -e 's/^.*\.\(...\)[^\.]*\#.*$$/\1/')
REAL_RPMDIR	= $(shell grep topdir ~/.rpmmacros | sed -e 's/^.*topdir[ \t]*\([^ \t]*\)$$/\1/')
XMLCLEAN = $(PWD)/bin/xmlClean

TAR_NAME = $(NAME)-$(VERSION)

FILES	= bin Book_Template content fop fop.txt make Makefile README templates xsl COPYING fdl.txt publican.desktop

local: rpm
	@echo "Start $@"
	@sudo rpm -Uvh $(RPMDIR)/RPMS/noarch/$(TAR_NAME)-$(RELEASE).$(OS_VER).noarch.rpm
	@echo "End $@"

rpm: srpm
	@echo "Start $@"
	@rpmbuild --define "dist .$(OS_VER)" --define "_topdir $(RPMDIR)" -bb $(RPMDIR)/SPECS/$(NAME).spec
	@echo "End $@"

srpm: dist
	@echo "Start $@"
	@mkdir -p $(RPMDIR)
	@cd $(RPMDIR) && mkdir -p  SPECS  SRPMS BUILD SOURCES RPMS/noarch
	@cp $(TAR_NAME)-$(RELEASE).tgz $(RPMDIR)/SOURCES/.
	@cp $(NAME).spec $(RPMDIR)/SPECS/.
	@rpmbuild --define "dist .el4" --define "_topdir $(RPMDIR)" -bs $(RPMDIR)/SPECS/$(NAME).spec
	@rpmbuild --define "dist .el5" --define "_topdir $(RPMDIR)" -bs $(RPMDIR)/SPECS/$(NAME).spec
	@rpmbuild --define "dist .fc9" --define "_topdir $(RPMDIR)" -bs $(RPMDIR)/SPECS/$(NAME).spec
	@echo "End $@"

dist: clean
	@echo "Start $@"
	@mkdir $(TAR_NAME)
	@for file in $(FILES); do cp -rf $$file $(TAR_NAME);done
	@find $(TAR_NAME) -name ".svn" | xargs rm -rf
	@find $(TAR_NAME) -name "*.swp" | xargs rm -rf
	@find $(TAR_NAME) -name "*.mo" | xargs rm -rf
	@find $(TAR_NAME) -name "*~" | xargs rm -rf
	@tar --atime-preserve -czf $(TAR_NAME)-$(RELEASE).tgz $(TAR_NAME)
	@echo "End $@"


# This is required to avoid this package depending on itself to build it's docs
MYPATH = $(shell echo $$PATH)
docs: PATH=$(MYPATH):$(PWD)/bin
docs: Common_Content
	@echo "Start $@"
	@make -C content/docs STANDALONE=1 publish-dist
	@mv content/docs/publish docs
	@echo "End $@"

clean:
	@echo "Start $@"
	@rm -rf $(NAME)-* *.tgz Common_Content tmp docs
	@make -C content/docs STANDALONE=1 clean
	@echo "End $@"

#######################################################################################
#
#	Common Content specific things
#
#######################################################################################

LANGS = as-IN bn-IN de-DE es-ES fr-FR gu-IN hi-IN it-IT ja-JP kn-IN ko-KR ml-IN mr-IN or-IN pa-IN pt-BR ru-RU si-LK ta-IN te-IN zh-CN zh-TW
ENT2POT		= $(PWD)/bin/entity2pot

update-pot:
	@echo "Start $@"
	@cd content/common && $(ENT2POT) en-US/Translatable-Entities.ent > pot/Translatable-Entities.pot
	@cd content/common/en-US && for xml_file in `find . -maxdepth 1 -name "*.xml"`; do \
		pot_file=`echo $$xml_file | sed -e 's/\.xml/\.pot/'`;\
		xml2pot $$xml_file | msguniq  > ../pot/$$pot_file;\
	done;
	@rm -f content/common/pot/Legal_Notice.pot
	@make -C content/docs update-pot
	@echo "End $@"

SOURCE	= https://svn.devel.redhat.com/repos/ecs/Software/$(NAME)/1.0/GUI_Strings

resync-po:: clean
	@echo "Start $@"
	@echo  "	Exporting PO files from $(SOURCE)"
	@mkdir -p tmp/SVN
	@pushd tmp/SVN  > /dev/null; \
		svn export $(SOURCE) gui_strings; \
	popd > /dev/null;
	@pushd tmp/SVN/gui_strings  > /dev/null; \
		find . -name *.po | sed -e 's/\.\///g' | xargs -i{} cp {} $(PWD)/content/common/{}; \
	popd > /dev/null;
	@echo "End $@"

entities::
	@echo "Start $@"
	@mkdir -p $(PWD)/Common_Content/common/en-US
	@cp content/common/en-US/Entities.ent Common_Content/common/en-US/.
	@cp content/common/en-US/Translatable-Entities.ent Common_Content/common/en-US/.
	@cd content/common/en-US && for lang in $(LANGS); do \
		if [ ! -d $(PWD)/Common_Content/common/$$lang ]; then \
			mkdir -p $(PWD)/Common_Content/common/$$lang; \
		fi; \
		if [ ! -f ../$$lang/Translatable-Entities.po ]; then \
			echo "../$$lang/Translatable-Entities.po MISSING Using en-US file"; \
			cp Translatable-Entities.ent $(PWD)/Common_Content/common/$$lang/.; \
		else \
			$(PWD)/bin/po2entity Translatable-Entities.ent ../$$lang/Translatable-Entities.po > $(PWD)/Common_Content/common/$$lang/Translatable-Entities.ent; \
		fi; \
	done;
	@echo "End $@"

Common_Content:: PATH=$(MYPATH):$(PWD)/bin
Common_Content:: entities
	@echo "Start $@"
	@cd content/common/en-US; \
		for xml_file in `find . -maxdepth 1 -name "*.xml"`; do \
			echo "	Processing $$xml_file"; \
			po_file=`echo $$xml_file | sed -e 's/\.xml/\.po/'`; \
			if [ ! -d $(PWD)/Common_Content/common/en-US ]; then \
				mkdir -p $(PWD)/Common_Content/common/en-US; \
			fi; \
			for lang in $(LANGS); do \
				if [ ! -d $(PWD)/Common_Content/common/$$lang ]; then \
					mkdir -p $(PWD)/Common_Content/common/$$lang; \
				fi; \
				if [ ! -f ../$$lang/$$po_file ]; then \
					echo "../$$lang/$$po_file MISSING Using en-US file"; \
					cp $$xml_file $(PWD)/Common_Content/common/$$lang/$$xml_file; \
				else \
					echo "		Processing ../$$lang/$$po_file"; \
					po2xml $$xml_file ../$$lang/$$po_file > tmp.xml; \
					$(XMLCLEAN) --common -in tmp.xml -out $(PWD)/Common_Content/common/$$lang/$$xml_file -lang $$lang; \
					rm tmp.xml; \
				fi; \
			done; \
			$(XMLCLEAN) --common -in $$xml_file -out $(PWD)/Common_Content/common/en-US/$$xml_file -lang en-US; \
		done; \
		cd ..; \
		for lang in $(LANGS) en-US; do \
			if [ -d en-US/css ]; then \
				mkdir -p  $(PWD)/Common_Content/common/$$lang/css; \
				cp -rf en-US/css/*.css  $(PWD)/Common_Content/common/$$lang/css/.; \
				if [ -d $$lang/css ]; then \
					cp -rf $$lang/css/*.css  $(PWD)/Common_Content/common/$$lang/css/.; \
				fi; \
			fi; \
		done; \
		for lang in $(LANGS) en-US; do \
			if [ -d en-US/images ]; then \
				mkdir -p  $(PWD)/Common_Content/common/$$lang/images; \
				cp -rf en-US/images/*  $(PWD)/Common_Content/common/$$lang/images/.; \
				if [ -d $$lang/images ]; then \
					if [ `find $$lang/images/ -type f | grep -v '.svn' | wc -l` -gt "0" ]; then \
						cp -rf $$lang/images/*  $(PWD)/Common_Content/common/$$lang/images/.; \
					fi; \
				fi; \
			fi; \
		done; \
		cd $(PWD);
	@echo "End $@"


