<?xml version='1.0'?>
 
<!--
	Copyright 2007 Red Hat, Inc.
	License: GPL
	Author: Jeff Fearn <jfearn@redhat.com>
	Author: Tammy Fox <tfox@redhat.com>
	Author: Andy Fitzsimon <afitzsim@redhat.com>
	Author: Ruediger Landmann <r.landmann@redhat.com>
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
<xsl:import href="../../../xsl/pdf.xsl"/>

<xsl:param name="title.color">#4a5d75</xsl:param>

<xsl:attribute-set name="admonition.title.properties">
  <xsl:attribute name="font-size">13pt</xsl:attribute>
  <xsl:attribute name="color">
  <xsl:choose>
    <xsl:when test="self::note">#4C5253</xsl:when>
    <xsl:when test="self::caution">#533500</xsl:when>
    <xsl:when test="self::important">white</xsl:when>
    <xsl:when test="self::warning">white</xsl:when>
    <xsl:when test="self::tip">white</xsl:when>
    <xsl:otherwise>white</xsl:otherwise>
  </xsl:choose>
        </xsl:attribute>

  <xsl:attribute name="font-weight">bold</xsl:attribute>
  <xsl:attribute name="hyphenate">false</xsl:attribute>
  <xsl:attribute name="keep-with-next.within-column">always</xsl:attribute>

</xsl:attribute-set>

<xsl:attribute-set name="graphical.admonition.properties">

  <xsl:attribute name="color">
  <xsl:choose>
    <xsl:when test="self::note">#4C5253</xsl:when>
    <xsl:when test="self::caution">#533500</xsl:when>
    <xsl:when test="self::important">white</xsl:when>
    <xsl:when test="self::warning">white</xsl:when>
    <xsl:when test="self::tip">white</xsl:when>
    <xsl:otherwise>white</xsl:otherwise>
  </xsl:choose>
        </xsl:attribute>
  <xsl:attribute name="background-color">
      <xsl:choose>
    <xsl:when test="self::note">#B5BCBD</xsl:when>
    <xsl:when test="self::caution">#E3A835</xsl:when>
    <xsl:when test="self::important">#4A5D75</xsl:when>
    <xsl:when test="self::warning">#7B1E1E</xsl:when>
    <xsl:when test="self::tip">#7E917F</xsl:when>
    <xsl:otherwise>#404040</xsl:otherwise>
      </xsl:choose>
        </xsl:attribute>

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

<xsl:attribute-set name="example.properties" use-attribute-sets="formal.object.properties">
	<xsl:attribute name="background-color">#dad6b9</xsl:attribute> 
<!--
     BZ 531685 program listing in example renders badly because example is constrained to a single page
-->
	<xsl:attribute name="keep-together.within-column"></xsl:attribute>
</xsl:attribute-set>

<xsl:param name="shade.verbatim" select="1"/>
<xsl:attribute-set name="shade.verbatim.style">
  <xsl:attribute name="wrap-option">wrap</xsl:attribute>
  <xsl:attribute name="hyphenation-character">\</xsl:attribute>
  <xsl:attribute name="background-color">
	<xsl:choose>
		<xsl:when test="local-name(.)='screen'">
			<xsl:text>#ede7c8</xsl:text>
		</xsl:when>
		<xsl:otherwise>
			<xsl:text>#f5f5f5</xsl:text> <!-- different from html -->
		</xsl:otherwise>
	</xsl:choose>
  </xsl:attribute>

  <xsl:attribute name="border-color">
	<xsl:choose>
		<xsl:when test="local-name(.)='screen'">
			<xsl:text></xsl:text>
		</xsl:when>
		<xsl:otherwise>
			<xsl:text>#cccccc</xsl:text> <!-- different from html -->
		</xsl:otherwise>
	</xsl:choose>
  </xsl:attribute>

  <xsl:attribute name="border-style">
	<xsl:choose>
		<xsl:when test="local-name(.)='screen'">
			<xsl:text></xsl:text>
		</xsl:when>
		<xsl:otherwise>
			<xsl:text>solid</xsl:text> <!-- different from html -->
		</xsl:otherwise>
	</xsl:choose>
  </xsl:attribute>

  <xsl:attribute name="border-width">
	<xsl:choose>
		<xsl:when test="local-name(.)='screen'">
			<xsl:text></xsl:text>
		</xsl:when>
		<xsl:otherwise>
			<xsl:text>.3mm</xsl:text> <!-- different from html -->
		</xsl:otherwise>
	</xsl:choose>
  </xsl:attribute>

  <xsl:attribute name="color">black</xsl:attribute>

  <!--xsl:attribute name="padding-left">12pt</xsl:attribute>
  <xsl:attribute name="padding-right">12pt</xsl:attribute-->
  <xsl:attribute name="padding-top">6pt</xsl:attribute>
  <xsl:attribute name="padding-bottom">6pt</xsl:attribute>
  <xsl:attribute name="margin-left">
    <xsl:value-of select="$title.margin.left"/>
  </xsl:attribute>
  <xsl:attribute name="font-size">
    <xsl:value-of select="$body.font.master * 0.8"/>
    <xsl:text>pt</xsl:text>
  </xsl:attribute>
</xsl:attribute-set>

<xsl:param name="table.cell.border.color">#5c5c4f</xsl:param>
<xsl:param name="table.frame.border.color">#5c5c4f</xsl:param>

</xsl:stylesheet>

