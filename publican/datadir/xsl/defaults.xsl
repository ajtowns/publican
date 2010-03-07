<?xml version='1.0'?>
 
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:exsl="http://exslt.org/common"
		xmlns:perl="urn:perl"
		version="1.0"
		exclude-result-prefixes="exsl perl">

<!-- titles after all elements -->
<xsl:param name="formal.title.placement">
figure after
example after
equation after
table after
procedure before 
</xsl:param>

<xsl:param name="prod.url" select="'http://www.redhat.com/docs'"/>
<xsl:param name="doc.url" select="'http://fedorahosted.org/publican'"/>

<xsl:param name="generate.section.toc.level" select="0"/>
<xsl:param name="qanda.defaultlabel">qanda</xsl:param>
<xsl:param name="glossary.sort" select="1"/>

<xsl:template name="user.preroot">
  <!-- Pre-root output, can be used to output comments and PIs. -->
  <!-- This must not output any element content! -->
</xsl:template>
<!--
Copied from fo/params.xsl
-->
<xsl:param name="l10n.gentext.default.language" select="'en'"/>

<xsl:param name="show.comments">0</xsl:param>
<xsl:param name="confidential" select="0"/>

<!-- This sets the filename based on the ID.								-->
<xsl:param name="use.id.as.filename" select="'1'"/>

<xsl:param name="embedtoc" select="'0'"/>
<xsl:param name="tocpath" select="''"/>

<xsl:param name="desktop" select="0"/>

<xsl:param name="funcsynopsis.style">ansi</xsl:param>
<xsl:param name="refentry.pagebreak">0</xsl:param>

<xsl:template match="command">
	<xsl:call-template name="inline.monoseq"/>
</xsl:template>

<xsl:template match="application">
	<xsl:call-template name="inline.boldseq"/>
</xsl:template>

<xsl:template match="guibutton">
	<xsl:call-template name="inline.boldseq"/>
</xsl:template>

<xsl:template match="guiicon">
	<xsl:call-template name="inline.boldseq"/>
</xsl:template>

<xsl:template match="guilabel">
	<xsl:call-template name="inline.boldseq"/>
</xsl:template>

<xsl:template match="guimenu">
	<xsl:call-template name="inline.boldseq"/>
</xsl:template>

<xsl:template match="guimenuitem">
	<xsl:call-template name="inline.boldseq"/>
</xsl:template>

<xsl:template match="guisubmenu">
	<xsl:call-template name="inline.boldseq"/>
</xsl:template>

<xsl:template match="filename">
	<xsl:call-template name="inline.monoseq"/>
</xsl:template>

<xsl:template name="language.to.xslthl">
  <xsl:param name="context"/>

  <xsl:choose>
    <xsl:when test="$context/@language != ''">
      <xsl:value-of select="$context/@language"/>
    </xsl:when>
    <xsl:when test="$highlight.default.language != ''">
      <xsl:value-of select="$highlight.default.language"/>
    </xsl:when>
  </xsl:choose>
</xsl:template>

<xsl:template name="apply-highlighting">
  <xsl:choose>
    <!-- Do we want syntax highlighting -->
    <xsl:when test="$highlight.source != 0 and function-available('perl:highlight')">
      <xsl:variable name="language">
	<xsl:call-template name="language.to.xslthl">
	  <xsl:with-param name="context" select="."/>
	</xsl:call-template>
      </xsl:variable>
      <xsl:choose>
	<xsl:when test="$language != ''">
	  <xsl:variable name="content">
	    <xsl:apply-templates/>
	  </xsl:variable>
	  <xsl:apply-templates select="perl:highlight($language, exsl:node-set($content))"/>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:apply-templates/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <!-- No syntax highlighting -->
    <xsl:otherwise>
      <xsl:apply-templates/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

</xsl:stylesheet>


