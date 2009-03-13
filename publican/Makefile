
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
SPEC	= $(NAME).spec.in
VERSION = $(shell grep 'Version:' $(SPEC) | sed -e 's/Version:\s*\(.*\)$$/\1/g')
RELEASE = $(shell grep 'Release:' $(SPEC) | sed -e 's/Release:\s*\(.*\)$$/\1/g' | sed -e 's/...dist.//')
PWD	= $(shell pwd)
RPMDIR	= $(PWD)/tmp/rpm
OS_VER	?= .$(shell uname -r | perl -p -e 's/^[^a-z]*([a-z]+[0-9]+).*$$/\1/')

REAL_RPMDIR	= $(shell grep topdir ~/.rpmmacros | sed -e 's/^.*topdir[ \t]*\([^ \t]*\)$$/\1/')
XMLCLEAN = $(PWD)/bin/xmlClean

TAR_NAME = $(NAME)-$(VERSION)
VERBOSE	?= 0

FILES	= bin Book_Template Set_Template Article_Template content fop fop-fonts fop.txt make Makefile README templates xsl COPYING fdl.txt publican.desktop xsl_extras maven

local: rpm
	@echo "Start $@"
	@sudo rpm -Uvh $(RPMDIR)/RPMS/noarch/*.rpm
	@echo "End $@"

rpm: srpm
	@echo "Start $@"
	@rpmbuild --define "dist $(OS_VER)" --define "_topdir $(RPMDIR)" --rebuild $(RPMDIR)/SRPMS/$(TAR_NAME)-$(RELEASE)$(OS_VER).src.rpm
	@echo "End $@"

brew:: srpm
	@echo "Start $@"
	brew build docs-5E $(RPMDIR)/SRPMS/$(TAR_NAME)-$(RELEASE)$(OS_VER).src.rpm
	@echo "End $@"

brew-scratch:: srpm
	@echo "Start $@"
	brew build --scratch docs-5E $(RPMDIR)/SRPMS/$(TAR_NAME)-$(RELEASE)$(OS_VER).src.rpm
	@echo "End $@"

srpm: dist
	@echo "Start $@"
	@mkdir -p $(RPMDIR)
	@cd $(RPMDIR) && mkdir -p  SPECS  SRPMS BUILD SOURCES RPMS/noarch
	@cp $(TAR_NAME).tgz $(RPMDIR)/SOURCES/.
	@cp publican.spec.in $(RPMDIR)/SPECS/$(NAME).spec
	@if [ "$(OS_VER)" = ".el5" ]; then \
		sed -i -e 's/@VENDOR@/redhat/' $(RPMDIR)/SPECS/$(NAME).spec; \
		sed -i -e 's/@EMBED45@/1/' $(RPMDIR)/SPECS/$(NAME).spec; \
		sed -i -e 's/@HTMLVIEW@/1/' $(RPMDIR)/SPECS/$(NAME).spec; \
		sed -i -e 's/@PREMOLESTATION@/1/' $(RPMDIR)/SPECS/$(NAME).spec; \
		sed -i -e 's/@FC10@/0/' $(RPMDIR)/SPECS/$(NAME).spec; \
		sed -i -e 's/@FC11@/0/' $(RPMDIR)/SPECS/$(NAME).spec; \
	elif [ "$(OS_VER)" = ".fc10" ]; then \
		sed -i -e 's/@VENDOR@/fedora/' $(RPMDIR)/SPECS/$(NAME).spec; \
		sed -i -e 's/@EMBED45@/0/' $(RPMDIR)/SPECS/$(NAME).spec; \
		sed -i -e 's/@HTMLVIEW@/0/' $(RPMDIR)/SPECS/$(NAME).spec; \
		sed -i -e 's/@PREMOLESTATION@/0/' $(RPMDIR)/SPECS/$(NAME).spec; \
		sed -i -e 's/@FC10@/1/' $(RPMDIR)/SPECS/$(NAME).spec; \
		sed -i -e 's/@FC11@/0/' $(RPMDIR)/SPECS/$(NAME).spec; \
	else \
		sed -i -e 's/@VENDOR@/fedora/' $(RPMDIR)/SPECS/$(NAME).spec; \
		sed -i -e 's/@EMBED45@/0/' $(RPMDIR)/SPECS/$(NAME).spec; \
		sed -i -e 's/@HTMLVIEW@/0/' $(RPMDIR)/SPECS/$(NAME).spec; \
		sed -i -e 's/@PREMOLESTATION@/0/' $(RPMDIR)/SPECS/$(NAME).spec; \
		sed -i -e 's/@FC10@/0/' $(RPMDIR)/SPECS/$(NAME).spec; \
		sed -i -e 's/@FC11@/1/' $(RPMDIR)/SPECS/$(NAME).spec; \
	fi
	@rpmbuild --define "dist $(OS_VER)" --define "_topdir $(RPMDIR)" -bs $(RPMDIR)/SPECS/$(NAME).spec
	@echo "End $@"

dist: clean
	@echo "Start $@"
	@mkdir $(TAR_NAME)
	@for file in $(FILES); do cp -rf $$file $(TAR_NAME);done
	@find $(TAR_NAME) -name ".svn" | xargs rm -rf
	@find $(TAR_NAME) -name "*.swp" | xargs rm -rf
	@find $(TAR_NAME) -name "*.mo" | xargs rm -rf
	@find $(TAR_NAME) -name "*~" | xargs rm -rf
	@tar --atime-preserve -czf $(TAR_NAME).tgz $(TAR_NAME)
	@echo "End $@"

upload-dist: dist
	@scp $(TAR_NAME).tgz fedorahosted.org:publican

# This is required to avoid this package depending on itself to build it's docs
MYPATH = $(shell echo $$PATH)
docs: PATH=$(PWD)/bin:$(MYPATH)
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

#LANGS = ar-AR as-IN bn-IN de-DE es-ES fr-FR gu-IN hi-IN it-IT ja-JP kn-IN ko-KR ml-IN mr-IN or-IN pa-IN pt-BR ru-RU si-LK ta-IN te-IN zh-CN zh-TW

LANGS = ar-AR as-IN bn-IN da-DK de-DE el-GR es-ES fr-FR gu-IN \
	hi-IN hu-HU id-ID it-IT ja-JP kn-IN ko-KR lv-LV \
	ml-IN mr-IN ms-MY nb-NO nl-NL or-IN pa-IN pl-PL \
	pt-BR pt-PT ru-RU si-LK sr-LATN sr-RS sv-SE ta-IN \
	te-IN zh-CN zh-TW

#LANGS = $(shell find content/common -maxdepth 1 -name '*-*' | grep -v 'en-US' | sort | sed -e 's/content\/common\///g')

update-pot:
	@echo "Start $@"
	@cd content/common/en-US && for xml_file in `find . -maxdepth 1 -name "*.xml"`; do \
		pot_file=`echo $$xml_file | sed -e 's/\.xml/\.pot/'`;\
		xml2pot $$xml_file | msguniq  > ../pot/$$pot_file;\
	done;
	@rm -f content/common/pot/Legal_Notice.pot
	@make -C content/docs update-pot
	@echo "End $@"

SOURCE	= https://svn.devel.redhat.com/repos/ecs/Software/publican-common/1.0

#resync-po:: clean
#	@echo "Start $@"
#	@echo  "	Exporting PO files from $(SOURCE)"
#	@mkdir -p tmp/SVN
#	@pushd tmp/SVN  > /dev/null; \
#		svn export $(SOURCE) gui_strings; \
#	popd > /dev/null;
#	@pushd tmp/SVN/gui_strings  > /dev/null; \
#		find . -name *.po | sed -e 's/\.\///g' | xargs -i{} cp {} $(PWD)/content/common/{}; \
#	popd > /dev/null;
#	@echo "End $@"

Common_Content:: PATH=$(MYPATH):$(PWD)/bin
Common_Content::
	@echo "Start $@"
	@cd content/common/en-US; \
		for xml_file in `find . -maxdepth 1 -name "*.xml"`; do \
			echo "	Processing $$xml_file"; \
			po_file=`echo $$xml_file | sed -e 's/\.xml/\.po/'`; \
			if [ ! -d $(PWD)/Common_Content/common/en-US ]; then \
				mkdir -p $(PWD)/Common_Content/common/en-US; \
				pushd $(PWD)/Common_Content/common > /dev/null; \
				ln -s en-US en; \
				popd > /dev/null; \
			fi; \
			for lang in $(LANGS); do \
				if [ ! -d $(PWD)/Common_Content/common/$$lang ]; then \
					mkdir -p $(PWD)/Common_Content/common/$$lang; \
					foo=`echo "$$lang" | cut -f 1 -d '-'`; \
					pushd $(PWD)/Common_Content/common > /dev/null; \
					ln -s $$lang $$foo; \
					popd > /dev/null; \
				fi; \
				if [ ! -f ../$$lang/$$po_file ]; then \
					echo "../$$lang/$$po_file MISSING Using en-US file"; \
					cp $$xml_file $(PWD)/Common_Content/common/$$lang/$$xml_file; \
				else \
					echo "		Processing ../$$lang/$$po_file"; \
					if [ $(VERBOSE) -ne 0 ]; then echo "			Running: po2xml $$xml_file ../$$lang/$$po_file > tmp.xml";fi; \
					po2xml $$xml_file ../$$lang/$$po_file > tmp.xml; \
					if [ $(VERBOSE) -ne 0 ]; then echo "			Running: $(XMLCLEAN) --common -in tmp.xml -out $(PWD)/Common_Content/common/$$lang/$$xml_file -lang $$lang";fi; \
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


