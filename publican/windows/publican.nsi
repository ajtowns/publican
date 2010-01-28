; Publican installer

;--------------------------------
;Include Modern UI

  !include "MUI2.nsh"
  !include "EnvVarUpdate.nsh"
  
;--------------------------------
;General

  ;Name and file
  Name "Publican"
  OutFile "Publican-Installer-1.4.exe"
  !insertmacro MUI_DEFAULT MUI_ICON "publican.ico"

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
  file "C:\Program Files\Microsoft Visual Studio .NET 2003\SDK\v1.1\Bin\msvcr71.dll"


  ;Store installation folder
  WriteRegStr HKLM  "Software\Publican" "" $INSTDIR

  ${EnvVarUpdate} $0 "PATH" "A" "HKLM" $INSTDIR
  
  ;Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"

  WriteRegStr HKLM "${REG_UNINSTALL}" "DisplayName" "Publican"
  WriteRegStr HKLM "${REG_UNINSTALL}" "DisplayVersion" "1.4"
  WriteRegStr HKLM "${REG_UNINSTALL}" "Publisher" "Team Publican"
  WriteRegStr HKLM "${REG_UNINSTALL}" "InstallSource" "$EXEDIR\"
  WriteRegDWord HKLM "${REG_UNINSTALL}" "NoModify" 0
  WriteRegDWord HKLM "${REG_UNINSTALL}" "NoRepair" 0
  WriteRegStr HKLM "${REG_UNINSTALL}" "UninstallString" '"$INSTDIR\Uninstall.exe"'


  ; Hide first run IO error
;  Exec '"$INSTDIR\publican.exe -v"'
 
SectionEnd

SectionGroup "Brands" SecBrands
Section "RedHat" SecBrandRedHat
  SetOutPath "$INSTDIR\Common_Content"
  file /r ..\..\publican-redhat\publish\*
  SetOutPath "$INSTDIR\Common_Content\RedHat"
  file /r ..\..\publican-redhat\publican.cfg

SectionEnd

Section "fedora" SecBrandfedora

  SetOutPath "$INSTDIR\Common_Content"
  file /r ..\..\publican-fedora\publish\*
  SetOutPath "$INSTDIR\Common_Content\fedora"
  file /r ..\..\publican-fedora\publican.cfg

SectionEnd

Section "JBoss" SecBrandJBoss

  SetOutPath "$INSTDIR\Common_Content"
  file /r ..\..\publican-jboss\publish\*
  SetOutPath "$INSTDIR\Common_Content\jboss"
  file /r ..\..\publican-jboss\publican.cfg

SectionEnd

Section "JBoss Community" SecBrandJBossCom

  SetOutPath "$INSTDIR\Common_Content"
  file /r ..\..\publican-jboss-community\publish\*
  SetOutPath "$INSTDIR\Common_Content\jboss-community"
  file /r ..\..\publican-jboss-community\publican.cfg

SectionEnd

Section "JBoss Hibernate Community" SecBrandJBossHib

  SetOutPath "$INSTDIR\Common_Content"
  file /r ..\..\publican-jboss-community-hibernate\publish\*
  SetOutPath "$INSTDIR\Common_Content\jboss-community-hibernate"
  file /r ..\..\publican-jboss-community-hibernate\publican.cfg

SectionEnd

Section "GIMP" SecBrandGIMP

  SetOutPath "$INSTDIR\Common_Content"
  file /r ..\..\publican-gimp\publish\*
  SetOutPath "$INSTDIR\Common_Content\GIMP"
  file /r ..\..\publican-gimp\publican.cfg

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

SectionGroup "Tools" SecTools

Section "ImageMagick" SecImageMagick
  ; Install ImageMagick
  SetOutPath "$TEMP"
  File "D:\DownLoads\ImageMagick-6.5.8-4-Q16-windows-dll.exe"
  ExecWait '"$TEMP\ImageMagick-6.5.8-4-Q16-windows-dll.exe"'
SectionEnd
Section "Get Text" SecGetText
  ; Install GetText
  SetOutPath "$TEMP"
  File "D:\DownLoads\gettext-0.14.4.exe"
  ExecWait '"$TEMP\gettext-0.14.4.exe"'
  
  ReadRegDWORD $0 HKLM  SOFTWARE\GnuWin32\GetText InstallPath
  ${EnvVarUpdate} $1 "PATH" "A" "HKLM" "$0\bin"

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

  LangString DESC_SecTools ${LANG_ENGLISH} "Tools to expand Publican's functionality"
  LangString DESC_SecImageMagick ${LANG_ENGLISH} "Image manipulation tools"
  LangString DESC_SecGetText ${LANG_ENGLISH} "Translation tool chain"

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
    
    !insertmacro MUI_DESCRIPTION_TEXT ${SecTools} $(DESC_SecTools)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecImageMagick} $(DESC_SecImageMagick)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecGetText} $(DESC_SecGetText)
  !insertmacro MUI_FUNCTION_DESCRIPTION_END


Section /o "Start Menu Group"
	SectionIn		1
	SetOutPath		"$INSTDIR"
#	SetOutPath		"$INSTDIR\Users_Guide"
#    file /r ..\Users_Guide\tmp\html-desktop\*

	CreateDirectory "$SMPROGRAMS\Publican"

	CreateShortCut	"$SMPROGRAMS\Publican\Uninstall Publican.lnk" "$INSTDIR\uninstall.exe"
#	CreateShortCut	"$SMPROGRAMS\Publican Documentation.lnk" "$INSTDIR\Users_Guide\index.html"
SectionEnd

;--------------------------------
;Uninstaller Section

Section "Uninstall"

  Delete "$INSTDIR\Uninstall.exe"

  RMDir /r "$INSTDIR"
  RmDir /r "$SMPROGRAMS\Publican"

  DeleteRegKey HKLM  "Software\Publican"
  ${un.EnvVarUpdate} $0 "PATH" "R" "HKLM" $INSTDIR
  DeleteRegKey HKLM "${REG_UNINSTALL}"
  
  ReadRegDWORD $0 HKLM  SOFTWARE\GnuWin32\GetText InstallPath
  ${un.EnvVarUpdate} $1 "PATH" "R" "HKLM" "$0\bin"
  
SectionEnd
