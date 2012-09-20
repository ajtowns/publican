<?xml version='1.0'?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/1999/xhtml"
				xmlns:exsl="http://exslt.org/common"
				version="1.0"
				exclude-result-prefixes="exsl">

<xsl:import href="http://docbook.sourceforge.net/release/xsl/current/xhtml/docbook.xsl"/>
<xsl:import href="http://docbook.sourceforge.net/release/xsl/current/xhtml/chunk.xsl"/>

<xsl:include href="defaults.xsl"/>
<xsl:include href="xhtml-common.xsl"/>

<xsl:param name="generate.revhistory.link" select="0"/>

<xsl:param name="chunk.section.depth" select="4"/>
<xsl:param name="chunk.first.sections" select="1"/>
<xsl:param name="chunk.toc" select="''"/>
<xsl:param name="chunk.append"/>
<xsl:param name="chunker.output.quiet" select="0"/>
<xsl:param name="suppress.navigation">1</xsl:param>
<xsl:param name="refentry.separator" select="1"/>

<!--
From: xhtml/chunk-common.xsl
Reason: add TOC div for web site
Version:
-->
<xsl:template name="chunk-element-content">
  <xsl:param name="prev"/>
  <xsl:param name="next"/>
  <xsl:param name="content">
    <xsl:apply-imports/>
  </xsl:param>

     <head>
       <xsl:call-template name="html.head">
         <xsl:with-param name="prev" select="$prev"/>
         <xsl:with-param name="next" select="$next"/>
      </xsl:call-template>
    </head>

    <body>
      <xsl:call-template name="body.attributes"/>
      <xsl:if test="$embedtoc != 0">
        <div id="navigation"></div>
        <div id="floatingtoc" class="hidden"></div>
      </xsl:if>

      <xsl:call-template name="user.header.content"/>
      <xsl:copy-of select="$content"/>
    </body>

  <xsl:value-of select="$chunk.append"/>
</xsl:template>

</xsl:stylesheet>
