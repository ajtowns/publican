; Publican installer

;--------------------------------
;Include Modern UI

	!include "MUI2.nsh"
	!include "EnvVarUpdate.nsh"
	
;--------------------------------
;General

	;Name and file
	Name "Publican"
	OutFile "Publican-Installer-3.0-beta.exe"
	!insertmacro MUI_DEFAULT MUI_ICON "publican.ico"

	;Default installation folder
	InstallDir "$PROGRAMFILES\Publican"
	
	;Get installation folder from registry if available
	InstallDirRegKey HKLM	"Software\Publican" ""

	;Request application privileges for Windows Vista
	RequestExecutionLevel admin

;	AutoCloseWindow true

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
	!insertmacro MUI_PAGE_LICENSE "C:\publican\publican\publican-redhat\COPYING" # CC-BY-SA 3.0
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

Function .onInit
	
	ReadRegStr $0 HKLM	SOFTWARE\Publican ""
	StrCmp $0 "" newinstall
		MessageBox MB_OKCANCEL|MB_ICONQUESTION "Publican installation detected, this must be uninstalled before this version can be installed. Do wish to uninstall the current version of Publican?" IDOK uninstall IDCANCEL abort

uninstall:
	ExecWait '"$INSTDIR\Uninstall.exe" _?=$INSTDIR'
	Goto newinstall

abort:
		Quit

newinstall:

FunctionEnd

Function .onInstSuccess
	; Hide first run IO error
	ExecWait '"$INSTDIR\publican.exe -v"'
	
FunctionEnd


Section "Publican" SecMain
	SectionIn RO

	SetOutPath "$INSTDIR"
	
	file /r ..\blib\datadir\*
	file publican.exe
#	file "C:\Program Files\Microsoft Visual Studio .NET 2003\SDK\v1.1\Bin\msvcr71.dll"

	;Store installation folder
	WriteRegStr HKLM	"Software\Publican" "" $INSTDIR

	${EnvVarUpdate} $0 "PATH" "A" "HKLM" $INSTDIR
	
	;Create uninstaller
	WriteUninstaller "$INSTDIR\Uninstall.exe"

	WriteRegStr HKLM "${REG_UNINSTALL}" "DisplayName" "Publican"
	WriteRegStr HKLM "${REG_UNINSTALL}" "DisplayVersion" "3.0-beta"
	WriteRegStr HKLM "${REG_UNINSTALL}" "Publisher" "Team Publican"
	WriteRegStr HKLM "${REG_UNINSTALL}" "InstallSource" "$EXEDIR\"
	WriteRegDWord HKLM "${REG_UNINSTALL}" "NoModify" 0
	WriteRegDWord HKLM "${REG_UNINSTALL}" "NoRepair" 0
	WriteRegStr HKLM "${REG_UNINSTALL}" "UninstallString" '"$INSTDIR\Uninstall.exe"'

SectionEnd

SectionGroup "Brands" SecBrands
Section "RedHat" SecBrandRedHat
	SetOutPath "$INSTDIR\Common_Content"
	file /r C:\publican\publican\publican-redhat\publish\*
	SetOutPath "$INSTDIR\Common_Content\RedHat"
	file /r C:\publican\publican\publican-redhat\publican.cfg

SectionEnd

Section "fedora" SecBrandfedora

	SetOutPath "$INSTDIR\Common_Content"
	file /r C:\publican\publican\publican-fedora\publish\*
	SetOutPath "$INSTDIR\Common_Content\fedora"
	file /r C:\publican\publican\publican-fedora\publican.cfg

SectionEnd

Section "JBoss" SecBrandJBoss

	SetOutPath "$INSTDIR\Common_Content"
	file /r C:\publican\publican\publican-jboss\publish\*
	SetOutPath "$INSTDIR\Common_Content\jboss"
	file /r C:\publican\publican\publican-jboss\publican.cfg

SectionEnd

Section "JBoss Community" SecBrandJBossCom

	SetOutPath "$INSTDIR\Common_Content"
	file /r C:\publican\publican\publican-jboss-community\publish\*
	SetOutPath "$INSTDIR\Common_Content\jboss-community"
	file /r C:\publican\publican\publican-jboss-community\publican.cfg

SectionEnd

Section "JBoss Hibernate Community" SecBrandJBossHib

	SetOutPath "$INSTDIR\Common_Content"
	file /r C:\publican\publican\publican-jboss-community-hibernate\publish\*
	SetOutPath "$INSTDIR\Common_Content\jboss-community-hibernate"
	file /r C:\publican\publican\publican-jboss-community-hibernate\publican.cfg

SectionEnd

Section "JBoss Richfaces Community" SecBrandJBossRF

	SetOutPath "$INSTDIR\Common_Content"
	file /r C:\publican\publican\publican-jboss-community-richfaces\publish\*
	SetOutPath "$INSTDIR\Common_Content\jboss-community-richfaces"
	file /r C:\publican\publican\publican-jboss-community-richfaces\publican.cfg

SectionEnd

Section "GIMP" SecBrandGIMP

	SetOutPath "$INSTDIR\Common_Content"
	file /r C:\publican\publican\publican-gimp\publish\*
	SetOutPath "$INSTDIR\Common_Content\GIMP"
	file /r C:\publican\publican\publican-gimp\publican.cfg

SectionEnd

SectionGroupEnd

SectionGroup "DocBook" SecDocBook

Section "DTD" SecDocBookDTD

	SetOutPath "$INSTDIR\DocBook_DTD"

	NSISdl::download http://www.docbook.org/xml/4.5/docbook-xml-4.5.zip docbook-xml-4.5.zip
	Pop $R0 ;Get the return value
	StrCmp $R0 "success" downloaded
	MessageBox MB_OK "Download failed: $R0"
	Quit

downloaded:

	nsUnzip::Extract "docbook-xml-4.5.zip" /END
	Pop $0
	StrCmp $0 "0" unzipped
	MessageBox MB_OK "Extract failed: $0"
 
unzipped:

	Delete "docbook-xml-4.5.zip"

	WriteRegStr HKLM "Software\Publican" "dtd_path" "$INSTDIR\DocBook_DTD"

SectionEnd

Section "XSL" SecDocBookXSL

	SetOutPath "$INSTDIR"
	NSISdl::download http://downloads.sourceforge.net/project/docbook/docbook-xsl/1.76.1/docbook-xsl-1.76.1.zip docbook-xsl-1.76.1.zip
	Pop $R0 ;Get the return value
	StrCmp $R0 "success" downloaded
	MessageBox MB_OK "Download failed: $R0"
	Quit

downloaded:

	nsUnzip::Extract "docbook-xsl-1.76.1.zip" /END
	Pop $0
	StrCmp $0 "0" unzipped
	MessageBox MB_OK "Extract failed: $0"
 
unzipped:

	Delete "docbook-xsl-1.76.1.zip"
	WriteRegStr HKLM "Software\Publican" "xsl_path" "$INSTDIR\docbook-xsl-1.76.1"

SectionEnd

SectionGroupEnd

SectionGroup "Tools" SecTools

Section "wkhtmltopdf" Secwkhtmltopdf
	; Install wkhtmltopdf
	SetOutPath "$INSTDIR"
	NSISdl::download http://wkhtmltopdf.googlecode.com/files/wkhtmltox-0.11.0_rc1-installer.exe $TEMP\wkhtmltox-0.11.0_rc1-installer.exe 

	Pop $R0 ;Get the return value
	StrCmp $R0 "success" downloaded
	MessageBox MB_OK "Download failed: $R0"
	Quit

downloaded:

	ExecWait '"$TEMP\wkhtmltox-0.11.0_rc1-installer.exe"'
 
SectionEnd

SectionGroupEnd


;--------------------------------
;Descriptions

	;Language strings
	LangString DESC_SecMain ${LANG_ENGLISH} "The Publican program"
	
	LangString DESC_SecDocBook ${LANG_ENGLISH} "Speed things up by including local DTD and XSL.$\r$\n$\r$\nThese files will be downloaded from the Internet and installed."
	LangString DESC_SecDocBookDTD ${LANG_ENGLISH} "DocBook XML DTD V4.5"
	LangString DESC_SecDocBookXSL ${LANG_ENGLISH} "DocBook XSL Stylesheets V1.76.1"
	
	LangString DESC_SecBrands ${LANG_ENGLISH} "Some Publican Brands"
	LangString DESC_SecBrandRedHat ${LANG_ENGLISH} "The Red Hat Brand"
	LangString DESC_SecBrandJBoss ${LANG_ENGLISH} "The JBoss Brand"
	LangString DESC_SecBrandfedora ${LANG_ENGLISH} "The fedora Brand"
	LangString DESC_SecBrandJBossCom ${LANG_ENGLISH} "The JBoss.org Brand"
	LangString DESC_SecBrandJBossHib ${LANG_ENGLISH} "The JBoss.org Hibernate Brand"
	LangString DESC_SecBrandJBossRF ${LANG_ENGLISH} "The JBoss.org Richfaces Brand"
	LangString DESC_SecBrandGIMP ${LANG_ENGLISH} "The GIMP Brand"

	LangString DESC_SecTools ${LANG_ENGLISH} "Tools to expand Publican's functionality.$\r$\n$\r$\nThe installers for these tools will be downloaded from the Internet."
	LangString DESC_Secwkhtmltopdf ${LANG_ENGLISH} "PDF tool chain. This is required for Publican to produce PFDs."

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
		!insertmacro MUI_DESCRIPTION_TEXT ${SecBrandJBossRF} $(DESC_SecBrandJBossRF)
		!insertmacro MUI_DESCRIPTION_TEXT ${SecBrandGIMP} $(DESC_SecBrandGIMP)
		
		!insertmacro MUI_DESCRIPTION_TEXT ${SecTools} $(DESC_SecTools)
		!insertmacro MUI_DESCRIPTION_TEXT ${Secwkhtmltopdf} $(DESC_Secwkhtmltopdf)
	!insertmacro MUI_FUNCTION_DESCRIPTION_END


Section "Start Menu Group"
	SectionIn		1
	SetOutPath		"$INSTDIR"
	SetOutPath		"$INSTDIR\Users_Guide"
	file /r ..\Users_Guide\publish\desktop\en-US\*

	SetShellVarContext all
	CreateDirectory "$SMPROGRAMS\Publican"

	CreateShortCut	"$SMPROGRAMS\Publican\Uninstall Publican.lnk" "$INSTDIR\uninstall.exe"
	CreateShortCut	"$SMPROGRAMS\Publican\Users Guide.lnk" "$INSTDIR\Users_Guide\index.html"
SectionEnd

;--------------------------------
;Uninstaller Section

Section "Uninstall"
	
	SetShellVarContext all
	Delete "$INSTDIR\Uninstall.exe"
	
	RMDir /r "$INSTDIR"
	RmDir /r "$SMPROGRAMS\Publican"

	DeleteRegKey HKLM	"Software\Publican"
	IfErrors nopubpath 0
	${un.EnvVarUpdate} $0 "PATH" "R" "HKLM" $INSTDIR

nopubpath:

	DeleteRegKey HKLM "${REG_UNINSTALL}"

SectionEnd
