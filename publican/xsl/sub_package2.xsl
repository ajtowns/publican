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
Summary: <xsl:value-of select="/bookinfo/subtitle" /><xsl:value-of select="/setinfo/subtitle" />
Group: Documentation
Requires: %{name}-<xsl:value-of select="$book-lang"/> = <xsl:value-of select="/bookinfo/issuenum" /><xsl:value-of select="/setinfo/issuenum" />-<xsl:value-of select="/bookinfo/productnumber" /><xsl:value-of select="/setinfo/productnumber" />
Requires(post,postun): coreutils

%description -n %{name}-<xsl:value-of select="$trans-lang"/>
<xsl:value-of select="/bookinfo/abstract/para" /><xsl:value-of select="/setinfo/abstract/para" />

%files -n %{name}-<xsl:value-of select="$trans-lang"/>
%defattr(-,root,root,-)
%doc <xsl:value-of select="$trans-lang"/>
<xsl:value-of select="$extra-files"/>
</xsl:template>
</xsl:stylesheet>
