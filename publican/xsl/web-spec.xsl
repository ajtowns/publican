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
<xsl:template match="/">#Documentation Specfile
%define HTMLVIEW %(eval 'if [ "%{?dist}" = ".el5" ]; then echo "1"; else echo "0"; fi')

Name:		<xsl:value-of select="$book-title"/>-web-<xsl:value-of select="$lang"/>
Version:	<xsl:value-of select="$rpmver"/>
Release:	<xsl:value-of select="$rpmrel"/>%{?dist}
Summary:	<xsl:value-of select="/bookinfo/subtitle"/><xsl:value-of select="/setinfo/subtitle"/><xsl:value-of select="/articleinfo/subtitle"/>
Group:		Documentation
License:	<xsl:value-of select="$license"/>
URL:		<xsl:value-of select="$url"/>
Source:		<xsl:value-of select="$src_url"/>%{name}-%{version}-<xsl:value-of select="$rpmrel"/>.tgz
BuildArch:	noarch
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires:	publican
<xsl:if test="$brand != 'publican-common'">
BuildRequires:	<xsl:value-of select="$brand"/>
</xsl:if>
Requires:	perl-Publican-WebSite
Prefix:		/var/www/html/docs

%description
<xsl:value-of select="/bookinfo/abstract/para" /><xsl:value-of select="/setinfo/abstract/para" /><xsl:value-of select="/articleinfo/abstract/para" />

%package -n <xsl:value-of select="$book-title"/>-<xsl:value-of select="$lang"/>
Summary:	<xsl:value-of select="/bookinfo/subtitle"/><xsl:value-of select="/setinfo/subtitle"/><xsl:value-of select="/articleinfo/subtitle"/>
Group:		Documentation
%if %{HTMLVIEW}
Requires:	htmlview
%else
Requires:	xdg-utils
%endif

%description  -n <xsl:value-of select="$book-title"/>-<xsl:value-of select="$lang"/>
<xsl:value-of select="/bookinfo/abstract/para" /><xsl:value-of select="/setinfo/abstract/para" /><xsl:value-of select="/articleinfo/abstract/para" />

%prep
%setup -q

%build
export CLASSPATH=$CLASSPATH:%{_javadir}/ant/ant-trax-1.7.0.jar:%{_javadir}/xmlgraphics-commons.jar:%{_javadir}/batik-all.jar:%{_javadir}/xml-commons-apis.jar:%{_javadir}/xml-commons-apis-ext.jar
%{__make} publish-web-<xsl:value-of select="$lang"/>

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/%{prefix}
mkdir -p $RPM_BUILD_ROOT%{_datadir}/applications
cp -rf publish/<xsl:value-of select="$lang"/> $RPM_BUILD_ROOT/%{prefix}/.

cat > $RPM_BUILD_ROOT%{_datadir}/applications/<xsl:value-of select="$book-title"/>-<xsl:value-of select="$lang"/>-<xsl:value-of select="$rpmver"/>.desktop &lt;&lt;'EOF'
[Desktop Entry]
Name=<xsl:value-of select="/bookinfo/productname" /><xsl:value-of select="/setinfo/productname" /><xsl:value-of select="/articleinfo/productname"/> <xsl:value-of select="/bookinfo/productnumber" /><xsl:value-of select="/setinfo/productnumber" /><xsl:value-of select="/articleinfo/productnumber"/>: <xsl:value-of select="/bookinfo/title" /><xsl:value-of select="/setinfo/title" /><xsl:value-of select="/articleinfo/title"/>
Comment=<xsl:value-of select="/bookinfo/subtitle"/><xsl:value-of select="/setinfo/subtitle"/><xsl:value-of select="/articleinfo/subtitle"/>
Exec=htmlview %{_docdir}/<xsl:value-of select="$book-title"/>-<xsl:value-of select="$lang"/>-%{version}/index.html
Icon=%{_docdir}/<xsl:value-of select="$book-title"/>-<xsl:value-of select="$lang"/>-%{version}/images/icon.svg
Categories=Documentation;X-Red-Hat-Base;
Type=Application
Encoding=UTF-8
Terminal=false
EOF

%preun -n <xsl:value-of select="$book-title"/>-web-<xsl:value-of select="$lang"/>
if [ "$1" = "0" ] ; then # last uninstall
%{__perl} -e 'if (eval {require Publican::WebSite}) { my @formats = ("html", "pdf", "html-single"); my $ws = Publican::WebSite->new(); foreach my $format (@formats) { $ws->del_entry({ language => "<xsl:value-of select="$lang"/>", product => "<xsl:value-of select="$prod" />", version => "<xsl:value-of select="$prodver" />", name => "<xsl:value-of select="$docname" />", format => "$format"} ); } $ws->regen_all_toc();}';
fi

%post -n <xsl:value-of select="$book-title"/>-web-<xsl:value-of select="$lang"/>
%{__perl} -e 'use Publican::WebSite; my @formats = ("html", "pdf", "html-single"); my $ws = Publican::WebSite->new(); foreach my $format (@formats) { $ws->add_entry( { language => "<xsl:value-of select="$lang"/>", product => "<xsl:value-of select="$prod" />", version => "<xsl:value-of select="$prodver" />", name => "<xsl:value-of select="$docname" />", format => "$format" }); } $ws->regen_all_toc();'

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%{prefix}/<xsl:value-of select="$lang"/>

%files -n <xsl:value-of select="$book-title"/>-<xsl:value-of select="$lang"/>
%defattr(-,root,root,-)
%doc tmp/<xsl:value-of select="$lang"/>/html-desktop/*
%{_datadir}/applications/<xsl:value-of select="$book-title"/>-<xsl:value-of select="$lang"/>-<xsl:value-of select="$rpmver"/>.desktop

%changelog<xsl:value-of select="$log"/>

</xsl:template>

</xsl:stylesheet>

