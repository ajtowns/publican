; Publican installer

;--------------------------------
;Include Modern UI

  !include "MUI2.nsh"
  !include "EnvVarUpdate.nsh"
  
;--------------------------------
;General

  ;Name and file
  Name "Publican"
  OutFile "Publican-Installer-1.3.exe"

  ;Default installation folder
  InstallDir "$PROGRAMFILES\Publican"
  
  ;Get installation folder from registry if available
  InstallDirRegKey HKLM  "Software\Publican" ""

  ;Request application privileges for Windows Vista
  RequestExecutionLevel admin

  AutoCloseWindow true

;--------------------------------
;Interface Configuration

  !define MUI_HEADERIMAGE
  !define MUI_HEADERIMAGE_BITMAP_NOSTRETCH
  !define MUI_HEADERIMAGE_BITMAP "publican.bmp"
  !define MUI_ABORTWARNING

;--------------------------------
;Pages

  !insertmacro MUI_PAGE_LICENSE "..\COPYING" # GPL
  !insertmacro MUI_PAGE_LICENSE "..\CC0"
  !insertmacro MUI_PAGE_LICENSE "..\fdl.txt"
  !insertmacro MUI_PAGE_LICENSE "..\..\publican-redhat\COPYING" # CC-BY-SA 3.0
  !insertmacro MUI_PAGE_COMPONENTS
  !insertmacro MUI_PAGE_DIRECTORY
  !insertmacro MUI_PAGE_INSTFILES
  
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES
  
;--------------------------------
;Languages
 
  !insertmacro MUI_LANGUAGE "English"

;--------------------------------

  !define REG_UNINSTALL "Software\Microsoft\Windows\CurrentVersion\Uninstall\Publican"

;--------------------------------
;Installer Sections

Section "Publican" SecMain
  SectionIn RO
  SetOutPath "$INSTDIR"
  
  file /r ..\blib\datadir\*
  file publican.exe
  
  ;Store installation folder
  WriteRegStr HKLM  "Software\Publican" "" $INSTDIR
  ; TODO confirm this works on Vista
  ${EnvVarUpdate} $0 "PATH" "A" "HKLM" $INSTDIR
  
  ;Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"

  WriteRegStr HKLM "${REG_UNINSTALL}" "DisplayName" "Publican"
  WriteRegStr HKLM "${REG_UNINSTALL}" "DisplayVersion" "1.3"
  WriteRegStr HKLM "${REG_UNINSTALL}" "Publisher" "Team Publican"
  WriteRegStr HKLM "${REG_UNINSTALL}" "InstallSource" "$EXEDIR\"
  WriteRegDWord HKLM "${REG_UNINSTALL}" "NoModify" 0
  WriteRegDWord HKLM "${REG_UNINSTALL}" "NoRepair" 0
  WriteRegStr HKLM "${REG_UNINSTALL}" "UninstallString" '"$INSTDIR\Uninstall.exe"'

  ; Hide first run IO error
  ; TODO doesn't work :(
  nsExec::Exec "$INSTDIR\publican.exe -v"
SectionEnd

SectionGroup "Brands" SecBrands
Section "RedHat" SecBrandRedHat
  SetOutPath "$INSTDIR\Common_Content"
  file /r ..\..\publican-redhat\publish\*
  
SectionEnd

Section "fedora" SecBrandfedora

  SetOutPath "$INSTDIR\Common_Content"
  file /r ..\..\publican-fedora\publish\*

SectionEnd

Section "JBoss" SecBrandJBoss

  SetOutPath "$INSTDIR\Common_Content"
  file /r ..\..\publican-jboss\publish\*

SectionEnd

Section "JBoss Community" SecBrandJBossCom

  SetOutPath "$INSTDIR\Common_Content"
  file /r ..\..\publican-jboss-community\publish\*

SectionEnd

Section "JBoss Hibernate Community" SecBrandJBossHib

  SetOutPath "$INSTDIR\Common_Content"
  file /r ..\..\publican-jboss-community-hibernate\publish\*

SectionEnd

Section "GIMP" SecBrandGIMP

  SetOutPath "$INSTDIR\Common_Content"
  file /r ..\..\publican-gimp\publish\*

SectionEnd
Section "" SecBrand

  SetOutPath "$INSTDIR\Common_Content\fedora"
  file /r ..\..\publican-fedora\publish\*

SectionEnd


SectionGroupEnd

SectionGroup "DocBook" SecDocBook
Section "DTD" SecDocBookDTD

  SetOutPath "$INSTDIR\DocBook_DTD"
  
  file /r ..\..\..\..\DTD\*
  WriteRegStr HKLM  "Software\Publican" "dtd_path" "$INSTDIR\DocBook_DTD"

SectionEnd
Section "XSL" SecDocBookXSL

  SetOutPath "$INSTDIR\DocBook_XSL"
  
  file /r ..\..\..\..\docbook-xsl-1.75.2\*
  WriteRegStr HKLM  "Software\Publican" "xsl_path" "$INSTDIR\DocBook_XSL"
SectionEnd
SectionGroupEnd

;--------------------------------
;Descriptions

  ;Language strings
  LangString DESC_SecMain ${LANG_ENGLISH} "The Publican program"
  LangString DESC_SecDocBook ${LANG_ENGLISH} "Speed things up by including local DTD and XSL"
  LangString DESC_SecDocBookDTD ${LANG_ENGLISH} "DocBook XML DTD V4.5"
  LangString DESC_SecDocBookXSL ${LANG_ENGLISH} "DocBook XSL Stylesheets V1.75.2"
  LangString DESC_SecBrands ${LANG_ENGLISH} "Some Publican Brands"
  LangString DESC_SecBrandRedHat ${LANG_ENGLISH} "The Red Hat Brand"
  LangString DESC_SecBrandJBoss ${LANG_ENGLISH} "The JBoss Brand"
  LangString DESC_SecBrandfedora ${LANG_ENGLISH} "The fedora Brand"
  LangString DESC_SecBrandJBossCom ${LANG_ENGLISH} "The JBoss.org Brand"
  LangString DESC_SecBrandJBossHib ${LANG_ENGLISH} "The JBoss.org Hibernate Brand"
  LangString DESC_SecBrandGIMP ${LANG_ENGLISH} "The GIMP Brand"

  ;Assign language strings to sections
  !insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SecMain} $(DESC_SecMain)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecDocBook} $(DESC_SecDocBook)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecDocBookDTD} $(DESC_SecDocBookDTD)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecDocBookXSL} $(DESC_SecDocBookXSL)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecBrands} $(DESC_SecBrands)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecBrandRedHat} $(DESC_SecBrandRedHat)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecBrandJBoss} $(DESC_SecBrandJBoss)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecBrandfedora} $(DESC_SecBrandfedora)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecBrandJBossCom} $(DESC_SecBrandJBossCom)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecBrandJBossHib} $(DESC_SecBrandJBossHib)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecBrandGIMP} $(DESC_SecBrandGIMP)
  !insertmacro MUI_FUNCTION_DESCRIPTION_END
 
;--------------------------------
;Uninstaller Section

Section "Uninstall"

  Delete "$INSTDIR\Uninstall.exe"

  RMDir /r "$INSTDIR"

  DeleteRegKey HKLM  "Software\Publican"
  ${un.EnvVarUpdate} $0 "PATH" "R" "HKLM" $INSTDIR
  DeleteRegKey HKLM "${REG_UNINSTALL}"
SectionEnd
