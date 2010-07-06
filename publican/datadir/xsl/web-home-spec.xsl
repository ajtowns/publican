<?xml version='1.0'?>
<xsl:stylesheet version="1.0" xml:space="preserve" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output encoding="UTF-8" indent="no" method="text" omit-xml-declaration="no" standalone="no" version="1.0"/>
<!-- Note: do not indent this file!  Any whitespace here will be reproduced in the output -->
<xsl:template match="/">
%define wwwdir %{_localstatedir}/www/html/docs
Name:          <xsl:value-of select="$book-title"/>-web-home
Version:       <xsl:value-of select="$rpmver"/>
Release:       <xsl:value-of select="$rpmrel"/>%{?dist}
Summary:       <xsl:value-of select="/bookinfo/subtitle"/><xsl:value-of select="/setinfo/subtitle"/><xsl:value-of select="/articleinfo/subtitle"/>
Group:         Documentation
License:       <xsl:value-of select="$license"/>
URL:           <xsl:value-of select="$url"/>
Source:        <xsl:value-of select="$src_url"/>%{name}-%{version}-<xsl:value-of select="$rpmrel"/>.tgz
BuildArch:     noarch
BuildRoot:     %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires: publican >= 2.0
Requires:      publican >= 2.0
<xsl:if test="$brand != 'publican-common'">BuildRequires: <xsl:value-of select="$brand"/></xsl:if>

%description
This is Publican Website home page using the brand: <xsl:value-of select="$brand"/>

%prep
%setup -q

%build
publican build --embedtoc --formats="html-single" --langs=all --publish

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/%{wwwdir}
cp -rf publish/home/* $RPM_BUILD_ROOT/%{wwwdir}/.

%clean
rm -rf $RPM_BUILD_ROOT

<xsl:if test="$web_search != '' or $web_host != ''">%post 
if [ "$1" -ge "1" ]; then
%{__perl} -e 'if (eval {require Publican::WebSite}) { my $ws = Publican::WebSite->new(); $ws->update_settings({<xsl:if test="$web_search != ''"> search => q|<xsl:value-of select="$web_search"/>|, </xsl:if> <xsl:if test="$web_host != ''"> host => q|<xsl:value-of select="$web_host"/>|</xsl:if>});}';
fi</xsl:if>

%files
%defattr(-,root,root,-)
%{wwwdir}

%changelog
<xsl:value-of select="$log"/>

</xsl:template>

</xsl:stylesheet>

