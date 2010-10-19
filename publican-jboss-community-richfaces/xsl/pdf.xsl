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
  	<xsl:attribute name="background-color">
	  <xsl:choose>
		<xsl:when test="local-name(.)='note'">
			<xsl:text>#B5BCBD</xsl:text>
		</xsl:when>
		<xsl:when test="local-name(.)='important'">
			<xsl:text>#4A5D75</xsl:text>
		</xsl:when>
		<xsl:when test="local-name(.)='warning'">
			<xsl:text>#7B1E1E</xsl:text>
		</xsl:when>
		<xsl:when test="local-name(.)='tip'">
			<xsl:text>#7E917F</xsl:text>
		</xsl:when>
		<xsl:when test="local-name(.)='caution'">
			<xsl:text>#E3A835</xsl:text>
		</xsl:when>
		<xsl:otherwise>
			<xsl:text>#dddddd</xsl:text>
		</xsl:otherwise>
	  </xsl:choose>
	</xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="graphical.admonition.properties">

  <xsl:attribute name="keep-together.within-column">always</xsl:attribute>
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
	<xsl:attribute name="border-left-width">0pt</xsl:attribute>
<!--
     BZ 531685 program listing in example renders badly because example is constrained to a single page
-->
	<xsl:attribute name="keep-together.within-column"></xsl:attribute>
	<xsl:attribute name="padding-left">0.8em</xsl:attribute>
	<xsl:attribute name="padding-right">0.8em</xsl:attribute>
	<xsl:attribute name="padding-top">0em</xsl:attribute>
	<xsl:attribute name="margin-top">0em</xsl:attribute>
  <xsl:attribute name="space-after.minimum">2em</xsl:attribute>
  <xsl:attribute name="space-after.optimum">2em</xsl:attribute>
  <xsl:attribute name="space-after.maximum">2em</xsl:attribute>

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

<!-- overrides for admonitions and examples for Publican>=2.3 -->

<xsl:attribute-set name="xref.properties">
  <xsl:attribute name="font-style">italic</xsl:attribute>
  <xsl:attribute name="color">
	<xsl:choose>
		<xsl:when test="ancestor::note or ancestor::important or ancestor::warning">
			<xsl:text>#aee6ff</xsl:text>
		</xsl:when>
		<xsl:otherwise>
			<xsl:text>#0066cc</xsl:text>
		</xsl:otherwise>
	</xsl:choose>
  </xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="admonition.properties">
	<xsl:attribute name="margin-right">0em</xsl:attribute>
	<xsl:attribute name="margin-left">0em</xsl:attribute>
	  <xsl:attribute name="background-color"></xsl:attribute>
	 <xsl:attribute name="border-left-width">0pt</xsl:attribute>
	<xsl:attribute name="border-right-width">0pt</xsl:attribute>
	<xsl:attribute name="border-bottom-width">0pt</xsl:attribute>
	<xsl:attribute name="padding-top">1.5em</xsl:attribute>
	<xsl:attribute name="padding-left">1em</xsl:attribute>
	<xsl:attribute name="padding-right">1em</xsl:attribute>
	<xsl:attribute name="padding-bottom">-1em</xsl:attribute>
	<xsl:attribute name="margin-top">0em</xsl:attribute>
	<xsl:attribute name="margin-bottom">0em</xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="formal.title.properties" use-attribute-sets="normal.para.spacing">
	<xsl:attribute name="color"><xsl:value-of select="$title.color"/></xsl:attribute>
	<xsl:attribute name="background-color"></xsl:attribute>
</xsl:attribute-set>

<!-- xsl:attribute-set name="above.title.properties" use-attribute-sets="formal.title.properties">
	<xsl:attribute name="font-weight">normal</xsl:attribute>
	<xsl:attribute name="font-size">
		<xsl:value-of select="$body.font.master"/>
		<xsl:text>pt</xsl:text>
	</xsl:attribute>
	<xsl:attribute name="space-before.optimum"><xsl:text>2em</xsl:text></xsl:attribute>
	<xsl:attribute name="space-before.minimum"><xsl:text>2em</xsl:text></xsl:attribute>
	<xsl:attribute name="space-before.maximum"><xsl:text>2em</xsl:text></xsl:attribute>
	<xsl:attribute name="space-after.optimum"><xsl:text>0.1pt</xsl:text></xsl:attribute>
	<xsl:attribute name="space-after.minimum"><xsl:text>0.1pt</xsl:text></xsl:attribute>
	<xsl:attribute name="space-after.maximum"><xsl:text>0.1pt</xsl:text></xsl:attribute>
</xsl:attribute-set -->


</xsl:stylesheet>

