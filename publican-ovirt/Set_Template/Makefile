#Makefile for MYBOOK

XML_LANG	= en-US
DOCNAME		= MYBOOK
#PRODUCT	= FIX_ME!
BRAND		= oVirt
DOC_TYPE	= Set

#BOOKS		= My_Other_Book His_Book Her_Book Their_Book
#SET_REPO	= http://svn.repo.com/repos/project
SET_REPO_TYPE	= SVN

#OTHER_LANGS	= as-IN bn-IN de-DE es-ES fr-FR gu-IN hi-IN it-IT ja-JP kn-IN ko-KR ml-IN mr-IN or-IN pa-IN pt-BR ru-RU si-LK ta-IN te-IN zh-CN zh-TW

# Extra Parameters start here

# Extra Parameters stop here
COMMON_CONFIG  = /usr/share/publican
include $(COMMON_CONFIG)/make/Makefile.common

pre:: get_books set_books
clean:: clean_set_books

