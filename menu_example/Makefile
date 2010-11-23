NAME	= menu-example
SPEC	= menu-example.spec
OS_VER	= ".el5"
VERSION = $(shell grep 'Version:' $(SPEC) | sed -e 's/Version:\s*\(.*\)$$/\1/g')
RELEASE = $(shell grep 'Release:' $(SPEC) | sed -e 's/Release:\s*\(.*\).{?dist}/\1$(OS_VER)/g')
TAR_NAME = $(NAME)-$(VERSION)
PWD	= $(shell pwd)
RPMDIR	=  $(PWD)/tmp/rpm

FILES = menu-example.directory  menu-example.menu README

brew: srpm
	@echo "Start $@"
	@brew build dist-5E-eso $(RPMDIR)/SRPMS/*.rpm
	@echo "End $@"

rpm: srpm
	@echo "Start $@"
	@rpmbuild  --define "dist $(OS_VER)" --define "_topdir $(RPMDIR)" --rebuild $(RPMDIR)/SRPMS/$(NAME)-$(VERSION)-$(RELEASE).src.rpm
	@echo "End $@"

srpm: dist
	@echo "Start $@"
	@mkdir -p $(RPMDIR)
	@cd $(RPMDIR) && mkdir -p  SPECS  SRPMS BUILD SOURCES RPMS/noarch
	@cp $(TAR_NAME).tgz $(RPMDIR)/SOURCES/.
	@rpmbuild --define "dist $(OS_VER)" --define "_topdir $(RPMDIR)" -bs $(SPEC)
	@echo "End $@"

dist: clean
	@echo "Start $@"
	@mkdir -p tmp/$(TAR_NAME)
	@for file in $(FILES); do cp -rf $$file tmp/$(TAR_NAME);done
	@find tmp/$(TAR_NAME) -name ".svn" | xargs rm -rf
	@find tmp/$(TAR_NAME) -name ".swp" | xargs rm -rf
	@find tmp/$(TAR_NAME) -name "*.mo" | xargs rm -rf
	@find tmp/$(TAR_NAME) -name "*~" | xargs rm -rf
	@tar -C tmp -czf $(TAR_NAME).tgz $(TAR_NAME)
	@echo "End $@"

clean:
	@echo "Start $@"
	@rm -rf $(NAME)-* *.tgz tmp
	@echo "End $@"

