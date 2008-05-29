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
URL:            http://www.redhat.com/docs
Source:         %{name}-%{version}-%{release}.tgz
BuildArch:      noarch
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires:	publican
Requires:       perl-Publican-WebSite
Prefix:		/var/www/html/docs

%description
<xsl:value-of select="/bookinfo/abstract/para" /><xsl:value-of select="/setinfo/abstract/para" />

%prep
%setup -q

%build
%{__make} publish-web-<xsl:value-of select="$lang"/>

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/%{prefix}
cp -rf publish/<xsl:value-of select="$lang"/> $RPM_BUILD_ROOT/%{prefix}/.

%preun
%{__perl} -e 'use Publican::WebSite; my $ws = Publican::WebSite->new(); foreach my $format ("html", "pdf", "html-single") { $ws->del_entry({language => "<xsl:value-of select="$lang"/>", product => "<xsl:value-of select="$prod" />", version => "<xsl:value-of select="$ver" />", name => "<xsl:value-of select="$docname" />", format => "$format"}); } $ws->regen_all_toc();'

%post
%{__perl} -e 'use Publican::WebSite; my $ws = Publican::WebSite->new(); foreach my $format ("html", "pdf", "html-single") { $ws->add_entry({language => "<xsl:value-of select="$lang"/>", product => "<xsl:value-of select="$prod" />", version => "<xsl:value-of select="$ver" />", name => "<xsl:value-of select="$docname" />", format => "$format"}); } $ws->regen_all_toc();'

%files
%defattr(-,root,root,-)
%{prefix}/<xsl:value-of select="$lang"/>

%changelog<xsl:value-of select="$book-log"/>

</xsl:template>

</xsl:stylesheet>

