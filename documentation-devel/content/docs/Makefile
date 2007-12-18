#Makefile for Red Hat Documentation
#Created by Jeff Fearn <jfearn@redhat.com>
#Copyright Red Hat Inc. 2006

XML_LANG	= en-US
DOCNAME		= Documentation_Devel
PRODUCT		= Software

#OTHER_LANGS	= as-IN bn-IN de-DE es-ES fr-FR gu-IN hi-IN it-IT ja-JP kn-IN ko-KR ml-IN mr-IN or-IN pa-IN pt-BR ru-RU si-LK ta-IN te-IN zh-CN zh-TW
TRANSLATIONS	= $(XML_LANG) $(OTHER_LANGS)

CHUNK_FIRST	= 0

STANDALONE	?= 0
PWD			= $(shell pwd)

ifeq "$(STANDALONE)" "0" 
COMMON_CONFIG  = /usr/share/documentation-devel
else
COMMON_CONFIG	= $(PWD)/../..
endif

include $(COMMON_CONFIG)/make/Makefile.common

