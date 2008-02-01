<?xml version='1.0'?>
 
<!--
	Copyright 2007 Red Hat, Inc.
	License: GPL
	Author: Jeff Fearn <jfearn@redhat.com>
-->

<xsl:stylesheet version="1.0" xml:space="preserve" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output encoding="UTF-8" indent="no" method="text" omit-xml-declaration="no" standalone="no" version="1.0"/>
<xsl:template match="/">
%package -n %{name}-<xsl:value-of select="$trans-lang"/>
Summary:	<xsl:value-of select="/bookinfo/subtitle" /><xsl:value-of select="/setinfo/subtitle" />
Group:	Documentation
Requires:	%{name}-<xsl:value-of select="$book-lang"/> = <xsl:value-of select="/bookinfo/issuenum" /><xsl:value-of select="/setinfo/issuenum" />-<xsl:value-of select="/bookinfo/productnumber" /><xsl:value-of select="/setinfo/productnumber" />
Requires(post):	coreutils
Requires(postun):	coreutils

%description -n %{name}-<xsl:value-of select="$trans-lang"/> <xsl:value-of select="/bookinfo/abstract[1]" /><xsl:value-of select="/setinfo/abstract[1]" />

%posttrans -n %{name}-<xsl:value-of select="$trans-lang"/>
%define _locale %(echo <xsl:value-of select="$trans-lang"/> |sed 's/-/_/')
if [ -d /usr/share/gnome/help/%{name}/%{_locale} ]; then
	rm -rf /usr/share/gnome/help/%{name}/%{_locale}
fi
if [ -d %{_docdir}/%{name}-<xsl:value-of select="$trans-lang"/>-%{version} ]; then
	ln -sf %{_docdir}/%{name}-<xsl:value-of select="$trans-lang"/>-%{version} /usr/share/gnome/help/%{name}/%{_locale};
fi

%files -n %{name}-<xsl:value-of select="$trans-lang"/>
%defattr(-,root,root,-)
%doc publish/<xsl:value-of select="$trans-lang"/>/*
</xsl:template>
</xsl:stylesheet>
