#Makefile for Red Hat Documentation
#Created by Jeff Fearn <jfearn@redhat.com>
#Copyright Red Hat Inc. 2006

XML_LANG	= en-US
DOCNAME		= Publican
PRODUCT		= Software

OTHER_LANGS	= as-IN bn-IN de-DE es-ES fr-FR gu-IN hi-IN it-IT ja-JP kn-IN ko-KR ml-IN mr-IN or-IN pa-IN pt-BR ru-RU si-LK ta-IN te-IN zh-CN zh-TW
TRANSLATIONS	= $(XML_LANG) $(OTHER_LANGS)

CHUNK_FIRST	= 0

STANDALONE	?= 0
PWD		= $(shell pwd)

ifeq "$(STANDALONE)" "0" 
COMMON_CONFIG  = /usr/share/publican
else
COMMON_CONFIG	= $(PWD)/../..
CATALOGS	= XML_CATALOG_FILES="$(PWD)/../../xsl_extras/docbook/dtd-4.5/catalog.xml $(PWD)/../../xsl_extras/docbook/1.72.0/catalog.xml"
XMLCLEAN	= $(PWD)/../../bin/xmlClean
endif


include $(COMMON_CONFIG)/make/Makefile.common

