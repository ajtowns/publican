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

Name:           <xsl:value-of select="$book-title"/>
Version:        <xsl:value-of select="/bookinfo/productnumber"/>
Release:        <xsl:value-of select="/bookinfo/pubsnumber"/>
Summary:        <xsl:value-of select="/bookinfo/subtitle"/>
Group:          Documentation
License:        OPL + Restrictions
URL:            http://www.redhat.com/docs
Source0:         %{name}-%{version}.tgz
BuildArch:      noarch
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires:	htmlview

%description
<xsl:value-of select="/bookinfo/abstract/para" /><xsl:value-of select="/setinfo/abstract/para" />

%package -n <xsl:value-of select="$book-title"/>-<xsl:value-of select="$book-lang"/>
Requires:	htmlview
Group:		Documentation
Summary:        <xsl:value-of select="/bookinfo/subtitle"/><xsl:value-of select="/setinfo/subtitle"/>

%description -n <xsl:value-of select="$book-title"/>-<xsl:value-of select="$book-lang"/>
<xsl:value-of select="/bookinfo/abstract/para" /><xsl:value-of select="/setinfo/abstract/para" />

%prep
%setup -q

%build

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT%{_datadir}/applications/

for lang in <xsl:value-of select="$lang-list"/>; do
cat > $RPM_BUILD_ROOT%{_datadir}/applications/%{name}-$lang.desktop &lt;&lt;EOF
[Desktop Entry]
Name=<xsl:value-of select="/bookinfo/subtitle"/><xsl:value-of select="/setinfo/subtitle"/> ($lang)
Comment=<xsl:value-of select="/bookinfo/title" /><xsl:value-of select="/setinfo/title" /> ($lang)
Exec=htmlview %{_docdir}/%{name}-$lang-%{version}/index.html
Icon=%{_docdir}/%{name}-$lang-%{version}/images/icon.svg
Categories=Documentation;X-Red-Hat-Base;
Type=Application
Encoding=UTF-8
Terminal=false
EOF
done

%clean
rm -rf $RPM_BUILD_ROOT

%posttrans -n <xsl:value-of select="$book-title"/>-<xsl:value-of select="$book-lang"/>
if [ -d %{_datadir}/gnome/help/%{name} ]; then
	rm -rf %{_datadir}/gnome/help/%{name};
fi

%files -n <xsl:value-of select="$book-title"/>-<xsl:value-of select="$book-lang"/>
%defattr(-,root,root,-)
%doc <xsl:value-of select="$book-lang"/>/*
%{_datadir}/applications/%{name}-<xsl:value-of select="$book-lang"/>.desktop

@@@SUBPACKAGES@@@

%changelog
<xsl:value-of select="$book-log"/>

</xsl:template>

</xsl:stylesheet>

