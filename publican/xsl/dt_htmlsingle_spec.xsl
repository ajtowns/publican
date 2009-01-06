<?xml version='1.0'?>
 
<!--
	Copyright 2007 Red Hat, Inc.
	License: GPL
	Author: Jeff Fearn <jfearn@redhat.com>
-->
<!-- Transform bookinfo.xml into a SPEC File -->
<xsl:stylesheet version="1.0" xml:space="preserve" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output encoding="UTF-8" indent="no" method="text" omit-xml-declaration="no" standalone="no" version="1.0"/>
<!-- Note: do not indent this file!  Any whitespace here
     will be reproduced in the output -->
<xsl:template match="/"># Documentation Specfile
%define HTMLVIEW %(eval 'if [ "%{?dist}" = ".el5" ]; then echo "1"; else echo "0"; fi')

Name:	<xsl:value-of select="$book-title"/>-<xsl:value-of select="$book-lang"/>
Version:	<xsl:value-of select="$rpmver"/>
Release:	<xsl:value-of select="$rpmrel"/>%{?dist}
Summary:	<xsl:value-of select="/bookinfo/subtitle"/><xsl:value-of select="/setinfo/subtitle"/><xsl:value-of select="/articleinfo/subtitle"/>
Group:		Documentation
License:	<xsl:value-of select="$license"/>
URL:		<xsl:value-of select="$url"/>
Source0:	%{name}-%{version}.tgz
BuildArch:	noarch
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires:	publican
<xsl:if test="$brand != 'publican-common'">
BuildRequires:	<xsl:value-of select="$brand"/>
</xsl:if>
%if %{HTMLVIEW}
Requires:	htmlview
%else
Requires:	xdg-utils
%endif

%description
<xsl:value-of select="/bookinfo/abstract/para" /><xsl:value-of select="/setinfo/abstract/para" /><xsl:value-of select="/articleinfo/abstract/para" />

%prep
%setup -q

%build
%{__make} html-desktop-<xsl:value-of select="$book-lang"/>

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT%{_datadir}/applications

cat > $RPM_BUILD_ROOT%{_datadir}/applications/%{name}.desktop &lt;&lt;'EOF'
[Desktop Entry]
Name=<xsl:value-of select="/bookinfo/productname" /><xsl:value-of select="/setinfo/productname" /><xsl:value-of select="/articleinfo/productname"/> <xsl:value-of select="/bookinfo/productnumber" /><xsl:value-of select="/setinfo/productnumber" /><xsl:value-of select="/articleinfo/productnumber"/>: <xsl:value-of select="/bookinfo/title" /><xsl:value-of select="/setinfo/title" /><xsl:value-of select="/articleinfo/title"/>
Comment=<xsl:value-of select="/bookinfo/subtitle"/><xsl:value-of select="/setinfo/subtitle"/><xsl:value-of select="/articleinfo/subtitle"/>
Exec=htmlview %{_docdir}/%{name}-%{version}/index.html
Icon=%{_docdir}/%{name}-%{version}/images/icon.svg
Categories=Documentation;X-Red-Hat-Base;
Type=Application
Encoding=UTF-8
Terminal=false
EOF

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc tmp/<xsl:value-of select="$book-lang"/>/html-desktop/*
%{_datadir}/applications/%{name}.desktop

%changelog<xsl:value-of select="$log"/>

</xsl:template>

</xsl:stylesheet>

