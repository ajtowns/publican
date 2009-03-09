XML_LANG        = en-US
PROGNAME        = publican-common
PRODUCT         = publican
#OTHER_LANGS     = as-IN bn-IN de-DE es-ES fr-FR gu-IN hi-IN it-IT ja-JP kn-IN ko-KR ml-IN mr-IN or-IN pa-IN pt-BR ru-RU si-LK ta-IN te-IN zh-CN zh-TW
OTHER_LANGS = $(shell find . -maxdepth 1 -name '*-*' | grep -v 'en-US' | sort | sed -e 's/\.\///g')

TRANSLATIONS    = $(XML_LANG) $(OTHER_LANGS)

COMMON_CONFIG  = /usr/share/publican
include $(COMMON_CONFIG)/make/Makefile.GUI

