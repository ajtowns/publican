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
<xsl:template match="/"># Red Hat Documentation Specfile
Name:	<xsl:value-of select="$book-title"/>-<xsl:value-of select="$book-lang"/>
Version:	<xsl:value-of select="/bookinfo/issuenum"/><xsl:value-of select="/setinfo/issuenum"/>
Release:	<xsl:value-of select="/bookinfo/productnumber"/><xsl:value-of select="/setinfo/productnumber"/>
Summary:	<xsl:value-of select="/bookinfo/subtitle"/><xsl:value-of select="/setinfo/subtitle"/>
Group:		Documentation
License:	Open Publication License
URL:		http://www.redhat.com/docs
Source0:	%{name}-%{version}-%{release}.tgz
BuildArch:	noarch
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires:	publican
Requires: 	htmlview

%description
<xsl:value-of select="/bookinfo/abstract/para" /><xsl:value-of select="/setinfo/abstract/para" />

%prep
%setup -q

%build
%{__make} DESKTOP=1 html-single-<xsl:value-of select="$book-lang"/>

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT%{_datadir}/applications

cat > $RPM_BUILD_ROOT%{_datadir}/applications/%{name}.desktop &lt;&lt;'EOF'
[Desktop Entry]
Name=<xsl:value-of select="/bookinfo/subtitle"/><xsl:value-of select="/setinfo/subtitle"/>
Comment=<xsl:value-of select="/bookinfo/title" /><xsl:value-of select="/setinfo/title" />
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
%doc tmp/<xsl:value-of select="$book-lang"/>/html-single/*
%{_datadir}/applications/%{name}.desktop

%changelog<xsl:value-of select="$book-log"/>

</xsl:template>

</xsl:stylesheet>

