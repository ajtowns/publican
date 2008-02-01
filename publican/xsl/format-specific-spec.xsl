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
Version:        <xsl:value-of select="/bookinfo/productnumber"/><xsl:value-of select="/setinfo/productnumber"/>
Release:        0
Summary:        <xsl:value-of select="/bookinfo/subtitle"/><xsl:value-of select="/setinfo/subtitle"/>
Group:          Documentation
License:        OPL + Restrictions
URL:            http://documentation.redhat.com/
Source0:         %{name}-%{version}-%{release}.tgz
BuildArch:      noarch
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires(post,postun): coreutils
Requires:       perl-Documentation-WebSite

%description
<xsl:value-of select="/bookinfo/abstract[1]" /><xsl:value-of select="/setinfo/abstract[1]" />

%prep

%setup -c -q -n %{name}-%{version}-%{release}

%build

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/var/www/html/<xsl:value-of select="$lang"/>/<xsl:value-of select="$prod"/>/<xsl:value-of select="$ver"/>/<xsl:value-of select="$format"/>
cp -rf <xsl:value-of select="$lang"/>/<xsl:value-of select="$prod"/>/<xsl:value-of select="$ver"/>/<xsl:value-of select="$format"/>/<xsl:value-of select="$docname"/> $RPM_BUILD_ROOT/var/www/html/<xsl:value-of select="$lang"/>/<xsl:value-of select="$prod"/>/<xsl:value-of select="$ver"/>/<xsl:value-of select="$format"/>/.

%files
%defattr(-,root,root,-)
/var/www/html/<xsl:value-of select="$lang"/>/<xsl:value-of select="$prod"/>/<xsl:value-of select="$ver"/>/<xsl:value-of select="$format"/>/<xsl:value-of select="$docname"/>

%preun
%{__perl} -e 'use Documentation::WebSite; my $ws = Documentation::WebSite->new(); $ws->del_entry({language => "<xsl:value-of select="$lang"/>", product => "<xsl:value-of select="$prod" />", version => "<xsl:value-of select="$ver" />", name => "<xsl:value-of select="$docname" />", format => "<xsl:value-of select="$format" />"}); $ws->regen_all_toc();'

%post
%{__perl} -e 'use Documentation::WebSite; my $ws = Documentation::WebSite->new(); $ws->add_entry({language => "<xsl:value-of select="$lang"/>", product => "<xsl:value-of select="$prod" />", version => "<xsl:value-of select="$ver" />", name => "<xsl:value-of select="$docname" />", format => "<xsl:value-of select="$format" />"}); $ws->regen_all_toc();'

%changelog
<xsl:apply-templates select="//revision"/>

</xsl:template>

<xsl:template match="revision">
<xsl:text>* </xsl:text><xsl:value-of select="./date"/><xsl:text> </xsl:text><xsl:value-of select="./author/firstname"/><xsl:text> </xsl:text><xsl:value-of select="./author/surname"/><xsl:text> </xsl:text><xsl:value-of select="./author/email"/><xsl:text> </xsl:text><xsl:value-of select="./revnumber"/>
<xsl:apply-templates select="revdescription/simplelist/member"/>
</xsl:template>

<xsl:template match="member"><xsl:text>- </xsl:text><xsl:value-of select="."/>
</xsl:template>

</xsl:stylesheet>

