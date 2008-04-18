<?xml version='1.0'?>
 
<!--
	Copyright 2007 Red Hat, Inc.
	License: GPL
	Author: Jeff Fearn <jfearn@redhat.com>
	Author: Tammy Fox <tfox@redhat.com>
	Author: Andy Fitzsimon <afitzsim@redhat.com>
-->

<!DOCTYPE xsl:stylesheet [
<!ENTITY lowercase "'abcdefghijklmnopqrstuvwxyz'">
<!ENTITY uppercase "'ABCDEFGHIJKLMNOPQRSTUVWXYZ'">
 ]>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		version='1.0'
		xmlns="http://www.w3.org/TR/xhtml1/transitional"
		xmlns:fo="http://www.w3.org/1999/XSL/Format"
		exclude-result-prefixes="#default">

<xsl:import href="http://docbook.sourceforge.net/release/xsl/current/fo/docbook.xsl"/>
<xsl:import href="http://docbook.sourceforge.net/release/xsl/current/fo/graphics.xsl"/>
<xsl:import href="../defaults.xsl"/>
<xsl:import href="../pdf.xsl"/>

<xsl:param name="title.color">#294172</xsl:param>


<xsl:attribute-set name="shade.verbatim.style">
  <xsl:attribute name="wrap-option">wrap</xsl:attribute>
  <xsl:attribute name="background-color">
	<xsl:choose>
		<xsl:when test="ancestor::note or ancestor::caution or ancestor::important or ancestor::warning or ancestor::tip">
			<xsl:text>#333333</xsl:text>
		</xsl:when>
		<xsl:otherwise>
			<xsl:text>#0093d9</xsl:text>
		</xsl:otherwise>
	</xsl:choose>
  </xsl:attribute>
  <xsl:attribute name="color">
	<xsl:choose>
		<xsl:when test="ancestor::note or ancestor::caution or ancestor::important or ancestor::warning or ancestor::tip">
			<xsl:text>white</xsl:text>
		</xsl:when>
		<xsl:otherwise>
			<xsl:text>black</xsl:text>
		</xsl:otherwise>
	</xsl:choose>
  </xsl:attribute>
	<xsl:attribute name="padding-left">12pt</xsl:attribute>
	<xsl:attribute name="padding-right">12pt</xsl:attribute>
	<xsl:attribute name="padding-top">6pt</xsl:attribute>
	<xsl:attribute name="padding-bottom">6pt</xsl:attribute>
	<xsl:attribute name="margin-left">
		<xsl:value-of select="$title.margin.left"/>
	</xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="graphical.admonition.properties">
	<xsl:attribute name="color">white</xsl:attribute>
	<xsl:attribute name="background-color">#0093d9</xsl:attribute>
	<xsl:attribute name="space-before.optimum">1em</xsl:attribute>
	<xsl:attribute name="space-before.minimum">0.8em</xsl:attribute>
	<xsl:attribute name="space-before.maximum">1.2em</xsl:attribute>
	<xsl:attribute name="space-after.optimum">1em</xsl:attribute>
	<xsl:attribute name="space-after.minimum">0.8em</xsl:attribute>
	<xsl:attribute name="space-after.maximum">1em</xsl:attribute>
	<xsl:attribute name="padding-bottom">12pt</xsl:attribute>
	<xsl:attribute name="padding-top">12pt</xsl:attribute>
	<xsl:attribute name="padding-right">12pt</xsl:attribute>
	<xsl:attribute name="padding-left">12pt</xsl:attribute>
	<xsl:attribute name="margin-left">
		<xsl:value-of select="$title.margin.left"/>
	</xsl:attribute>
</xsl:attribute-set>
</xsl:stylesheet>

