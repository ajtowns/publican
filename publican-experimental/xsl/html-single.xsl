<?xml version='1.0'?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/1999/xhtml"
				xmlns:exsl="http://exslt.org/common"
				version="1.0"
				exclude-result-prefixes="exsl">

<xsl:import href="http://docbook.sourceforge.net/release/xsl/current/xhtml/docbook.xsl"/>
<xsl:import href="http://docbook.sourceforge.net/release/xsl/current/xhtml/titlepage.xsl"/>
<xsl:import href="../../../xsl/html-single.xsl"/>

<xsl:output method="xml" encoding="UTF-8" indent="no" doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN" doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd" omit-xml-declaration="no" />

<xsl:param name="html.append"/>
<xsl:param name="abstract.notitle.enabled" select="'1'"/>
<xsl:param name="contrib.inline.enabled">0</xsl:param>

<xsl:param name="generate.toc">
set nop
book nop
article nop
chapter nop
qandadiv nop
qandaset nop
sect1 nop
sect2 nop
sect3 nop
sect4 nop
sect5 nop
section nop
part nop
</xsl:param>

<!--
From: xhtml/docbook.xsl
Reason: add TOC div for web site
Version:
-->

<xsl:template match="*" mode="process.root">
  <xsl:variable name="doc" select="self::*"/>

  <xsl:call-template name="user.preroot"/>
  <xsl:call-template name="root.messages"/>

  <html>
    <head>
      <xsl:call-template name="system.head.content">
        <xsl:with-param name="node" select="$doc"/>
      </xsl:call-template>
      <xsl:call-template name="head.content">
        <xsl:with-param name="node" select="$doc"/>
      </xsl:call-template>
      <xsl:call-template name="user.head.content">
        <xsl:with-param name="node" select="$doc"/>
      </xsl:call-template>
    </head>
    <body>
      <xsl:call-template name="body.attributes"/>
     <xsl:call-template name="user.header.content">
        <xsl:with-param name="node" select="$doc"/>
      </xsl:call-template>
      <xsl:if test="$embedtoc != 0">
      <div id="tocdiv" class="toc">
        <iframe><xsl:attribute name="id">tocframe</xsl:attribute><xsl:attribute name="class">toc</xsl:attribute><xsl:attribute name="src">/docs/<xsl:value-of select="$l10n.gentext.language"/>/toc.html</xsl:attribute>This is an iframe, to view it upgrade your browser or enable iframe display.</iframe>
      </div>
      </xsl:if>
      <xsl:apply-templates select="."/>
    </body>
  </html>
  <xsl:value-of select="$html.append"/>
</xsl:template>

<xsl:template name="credits.div">
  <span class="shortemail">
      <a>
        <xsl:apply-templates select="." mode="common.html.attributes"/>
        <xsl:attribute name="href">
          <xsl:text>mailto:</xsl:text>
          <xsl:value-of select="email"/>
        </xsl:attribute>
        <xsl:value-of select="firstname"/><xsl:text> </xsl:text><xsl:value-of select="surname"/>
      </a>
  </span>
  <xsl:if test="position() &lt; last()">
    <xsl:text>, </xsl:text>
  </xsl:if>
</xsl:template>

<xsl:template match="legalnotice" mode="titlepage.mode">
      <div>
        <xsl:apply-templates select="." mode="common.html.attributes"/>
        <xsl:apply-templates mode="titlepage.mode"/>
      </div>
</xsl:template>

<xsl:template name="article.titlepage.recto">
	<div class="tighttitle" xsl:use-attribute-sets="book.titlepage.recto.style">
	  <xsl:value-of select="articleinfo/productname"/>
	  <xsl:text> </xsl:text>
	  <xsl:value-of mode="book.titlepage.recto.auto.mode" select="articleinfo/productnumber"/>
	  <xsl:text>: </xsl:text>
  <xsl:choose>
    <xsl:when test="articleinfo/title">
      <xsl:value-of select="articleinfo/title"/>
    </xsl:when>
    <xsl:when test="artheader/title">
      <xsl:value-of select="artheader/title"/>
    </xsl:when>
    <xsl:when test="info/title">
      <xsl:value-of select="info/title"/>
    </xsl:when>
    <xsl:when test="title">
      <xsl:value-of select="title"/>
    </xsl:when>
  </xsl:choose>
	</div>

  <xsl:choose>
    <xsl:when test="articleinfo/subtitle">
      <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="articleinfo/subtitle"/>
    </xsl:when>
    <xsl:when test="artheader/subtitle">
      <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="artheader/subtitle"/>
    </xsl:when>
    <xsl:when test="info/subtitle">
      <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="info/subtitle"/>
    </xsl:when>
    <xsl:when test="subtitle">
      <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="subtitle"/>
    </xsl:when>
  </xsl:choose>
  <div class="credits">
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="articleinfo/corpauthor"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="artheader/corpauthor"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="info/corpauthor"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="articleinfo/authorgroup"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="artheader/authorgroup"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="info/authorgroup"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="articleinfo/author"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="artheader/author"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="info/author"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="articleinfo/othercredit"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="artheader/othercredit"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="info/othercredit"/>
  </div>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="articleinfo/releaseinfo"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="artheader/releaseinfo"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="info/releaseinfo"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="articleinfo/copyright"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="artheader/copyright"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="info/copyright"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="articleinfo/legalnotice"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="artheader/legalnotice"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="info/legalnotice"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="articleinfo/pubdate"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="artheader/pubdate"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="info/pubdate"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="articleinfo/revision"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="artheader/revision"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="info/revision"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="articleinfo/revhistory"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="artheader/revhistory"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="info/revhistory"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="articleinfo/abstract"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="artheader/abstract"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="info/abstract"/>
</xsl:template>

</xsl:stylesheet>
