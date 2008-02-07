<?xml version='1.0'?>
 
<!--
	Copyright 2007 Red Hat, Inc.
	License: GPL
	Author: Jeff Fearn <jfearn@redhat.com>
	Author: Tammy Fox <tfox@redhat.com>
	Author: Andy Fitzsimon <afitzsim@redhat.com>
-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/1999/xhtml"
				xmlns:exsl="http://exslt.org/common"
				xmlns:xtext="xalan://com.nwalsh.xalan.Text"
				xmlns:xlink="http://www.w3.org/1999/xlink"
				xmlns:stext="http://nwalsh.com/xslt/ext/com.nwalsh.saxon.TextFactory"
				version="1.0"
				exclude-result-prefixes="xlink exsl stext xtext"
				extension-element-prefixes="stext xtext"
>

<!-- Admonition Graphics -->
<xsl:param name="admon.graphics" select="1"/>
<xsl:param name="admon.style" select="''"/>
<xsl:param name="admon.graphics.path">./Common_Content/images/</xsl:param>
<xsl:param name="callout.graphics.path">./Common_Content/images/</xsl:param>

<xsl:param name="chunker.output.doctype-public" select="'-//W3C//DTD XHTML 1.0 Strict//EN'"/>
<xsl:param name="chunker.output.doctype-system" select="'http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd'"/>
<xsl:param name="chunker.output.encoding" select="'UTF-8'"/>
<xsl:param name="chunker.output.indent" select="'yes'"/>
<xsl:param name="html.longdesc.link" select="0"/>
<xsl:param name="html.longdesc" select="0"/>
<xsl:param name="html.longdesc.embed" select="1"/>

<xsl:param name="html.stylesheet" select="'./Common_Content/css/default.css'"/>
<xsl:param name="html.stylesheet.type" select="'text/css'"/>
<xsl:param name="html.cleanup" select="1"/>
<xsl:param name="html.ext" select="'.html'"/>
<xsl:output method="xml" indent="yes"/>


<!-- TOC -->
<xsl:param name="section.autolabel" select="1"/>
<xsl:param name="section.label.includes.component.label" select="1"/>

<xsl:param name="generate.toc">
set toc
book toc
article toc
chapter toc
qandadiv toc
qandaset nop
sect1 nop
sect2 nop
sect3 nop
sect4 nop
sect5 nop
section toc
part toc
</xsl:param>

<xsl:param name="suppress.navigation" select="0"/>
<xsl:param name="suppress.header.navigation" select="0"/>
<xsl:param name="suppress.footer.navigation" select="0"/>

<xsl:param name="header.rule" select="0"/>
<xsl:param name="footer.rule" select="0"/>
<xsl:param name="css.decoration" select="0"/>
<xsl:param name="ulink.target"/>
<xsl:param name="table.cell.border.style"/>

<!-- BUGBUG TODO 

	There is a bug where inserting elements in to the body level
	of xhtml will add xmlns="" to the tag. This is invalid xhtml.
	To overcome this I added:
		xmlns="http://www.w3.org/1999/xhtml"
	to the outer most tag. This gets stripped by the parser, resulting
	in valid xhtml ... go figure.
-->

<!--
From: xhtml/admon.xsl
Reason: remove tables
Version: 1.72.0
-->
<xsl:template name="graphical.admonition">
	<xsl:variable name="admon.type">
		<xsl:choose>
			<xsl:when test="local-name(.)='note'">Note</xsl:when>
			<xsl:when test="local-name(.)='warning'">Warning</xsl:when>
			<xsl:when test="local-name(.)='caution'">Caution</xsl:when>
			<xsl:when test="local-name(.)='tip'">Tip</xsl:when>
			<xsl:when test="local-name(.)='important'">Important</xsl:when>
			<xsl:otherwise>Note</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>

	<xsl:variable name="alt">
		<xsl:call-template name="gentext">
			<xsl:with-param name="key" select="$admon.type"/>
		</xsl:call-template>
	</xsl:variable>

	<div xmlns="http://www.w3.org/1999/xhtml">
	 	 <xsl:apply-templates select="." mode="class.attribute"/>
		<xsl:if test="$admon.style != ''">
			<xsl:attribute name="style">
				<xsl:value-of select="$admon.style"/>
			</xsl:attribute>
		</xsl:if>

		<xsl:call-template name="anchor"/>
			<xsl:if test="$admon.textlabel != 0 or title">
				<h2>
					<xsl:apply-templates select="." mode="object.title.markup"/>
				</h2>
			</xsl:if>
		<xsl:apply-templates/>
	</div>
</xsl:template>

<!--
From: xhtml/lists.xsl
Reason: Remove invalid type attribute from ol
Version: 1.72.0
-->
<xsl:template match="substeps">
	<xsl:variable name="numeration">
		<xsl:call-template name="procedure.step.numeration"/>
	</xsl:variable>
	<xsl:call-template name="anchor"/>
	<ol xmlns="http://www.w3.org/1999/xhtml" class="{$numeration}">
		<xsl:apply-templates/>
	</ol>
</xsl:template>

<!--
From: xhtml/lists.xsl
Reason: Remove invalid type, start & compact attributes from ol, use role as class
Version: 1.72.0
-->
<xsl:template match="orderedlist">
	<div xmlns="http://www.w3.org/1999/xhtml">
		<xsl:apply-templates select="." mode="class.attribute"/>
		<xsl:call-template name="anchor"/>
		<xsl:if test="title">
			<xsl:call-template name="formal.object.heading"/>
		</xsl:if>
<!-- Preserve order of PIs and comments -->
		<xsl:apply-templates select="*[not(self::listitem or self::title or self::titleabbrev)] |
                                      comment()[not(preceding-sibling::listitem)] |
									  processing-instruction()[not(preceding-sibling::listitem)]"/>
		<ol>
          <xsl:if test="@role">
            <xsl:apply-templates select="." mode="class.attribute">
              <xsl:with-param name="class" select="@role"/>
            </xsl:apply-templates>
          </xsl:if>
          <xsl:apply-templates select="listitem | comment()[preceding-sibling::listitem] | processing-instruction()[preceding-sibling::listitem]"/>
		</ol>
	</div>
</xsl:template>

<!--
From: xhtml/lists.xsl
Reason: Remove invalid type, start & compact attributes from ol
Version: 1.72.0
-->
<xsl:template match="procedure">
	<xsl:variable name="param.placement" select="substring-after(normalize-space($formal.title.placement), concat(local-name(.), ' '))"/>

	<xsl:variable name="placement">
		<xsl:choose>
			<xsl:when test="contains($param.placement, ' ')">
				<xsl:value-of select="substring-before($param.placement, ' ')"/>
			</xsl:when>
			<xsl:when test="$param.placement = ''">before</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$param.placement"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>

<!-- Preserve order of PIs and comments -->
	<xsl:variable name="preamble" select="*[not(self::step or self::title or self::titleabbrev)] |comment()[not(preceding-sibling::step)]	|processing-instruction()[not(preceding-sibling::step)]"/>
	<div xmlns="http://www.w3.org/1999/xhtml">
		<xsl:apply-templates select="." mode="class.attribute"/>
		<xsl:call-template name="anchor">
			<xsl:with-param name="conditional">
				<xsl:choose>
					<xsl:when test="title">0</xsl:when>
					<xsl:otherwise>1</xsl:otherwise>
				</xsl:choose>
			</xsl:with-param>
		</xsl:call-template>
		<xsl:if test="title and $placement = 'before'">
			<xsl:call-template name="formal.object.heading"/>
		</xsl:if>
		<xsl:apply-templates select="$preamble"/>
		<xsl:choose>
			<xsl:when test="count(step) = 1">
				<ul>
					<xsl:apply-templates select="step |comment()[preceding-sibling::step] |processing-instruction()[preceding-sibling::step]"/>
				</ul>
			</xsl:when>
			<xsl:otherwise>
				<ol>
					<xsl:attribute name="class">
						<xsl:value-of select="substring($procedure.step.numeration.formats,1,1)"/>
					</xsl:attribute>
					<xsl:apply-templates select="step |comment()[preceding-sibling::step] |processing-instruction()[preceding-sibling::step]"/>
				</ol>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:if test="title and $placement != 'before'">
			<xsl:call-template name="formal.object.heading"/>
		</xsl:if>
	</div>
</xsl:template>

<!--
From: xhtml/graphics.xsl
Reason:  Remove html markup (align)
Version: 1.72.0
-->
<xsl:template name="longdesc.link">
	<xsl:param name="longdesc.uri" select="''"/>

	<xsl:variable name="this.uri">
	<xsl:call-template name="make-relative-filename">
		<xsl:with-param name="base.dir" select="$base.dir"/>
			<xsl:with-param name="base.name">
				<xsl:call-template name="href.target.uri"/>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:variable>
	<xsl:variable name="href.to">
		<xsl:call-template name="trim.common.uri.paths">
			<xsl:with-param name="uriA" select="$longdesc.uri"/>
			<xsl:with-param name="uriB" select="$this.uri"/>
			<xsl:with-param name="return" select="'A'"/>
		</xsl:call-template>
	</xsl:variable>
	<div xmlns="http://www.w3.org/1999/xhtml" class="longdesc-link">
		<br/>
		<span class="longdesc-link">
			<xsl:text>[</xsl:text>
			<a href="{$href.to}">D</a>
			<xsl:text>]</xsl:text>
		</span>
	</div>
</xsl:template>

<!--
From: xhtml/docbook.xsl
Reason: Remove inline style for draft mode
Version: 1.72.0
-->
<xsl:template name="head.content">
	<xsl:param name="node" select="."/>
	<xsl:param name="title">
		<xsl:apply-templates select="$node" mode="object.title.markup.textonly"/>
	</xsl:param>

	<title xmlns="http://www.w3.org/1999/xhtml" >
		<xsl:copy-of select="$title"/>
	</title>

	<xsl:if test="$html.stylesheet != ''">
		<xsl:call-template name="output.html.stylesheets">
			<xsl:with-param name="stylesheets" select="normalize-space($html.stylesheet)"/>
		</xsl:call-template>
	</xsl:if>

	<xsl:if test="$link.mailto.url != ''">
		<link rev="made" href="{$link.mailto.url}"/>
	</xsl:if>

	<xsl:if test="$html.base != ''">
		<base href="{$html.base}"/>
	</xsl:if>

	<meta xmlns="http://www.w3.org/1999/xhtml" name="generator" content="DocBook {$DistroTitle} V{$VERSION}"/>

	<xsl:if test="$generate.meta.abstract != 0">
		<xsl:variable name="info" select="(articleinfo |bookinfo |prefaceinfo |chapterinfo |appendixinfo |sectioninfo |sect1info |sect2info |sect3info |sect4info |sect5info |referenceinfo |refentryinfo |partinfo |info |docinfo)[1]"/>
		<xsl:if test="$info and $info/abstract">
			<meta xmlns="http://www.w3.org/1999/xhtml" name="description">
				<xsl:attribute name="content">
					<xsl:for-each select="$info/abstract[1]/*">
						<xsl:value-of select="normalize-space(.)"/>
						<xsl:if test="position() &lt; last()">
							<xsl:text> </xsl:text>
						</xsl:if>
					</xsl:for-each>
				</xsl:attribute>
			</meta>
		</xsl:if>
	</xsl:if>

	<xsl:apply-templates select="." mode="head.keywords.content"/>
</xsl:template>

<!--
From: xhtml/docbook.xsl
Reason: Add css class for draft mode
Version: 1.72.0
-->
<xsl:template name="body.attributes">
	<xsl:if test="($draft.mode = 'yes' or ($draft.mode = 'maybe' and ancestor-or-self::*[@status][1]/@status = 'draft'))">
		<xsl:attribute name="class">
			<xsl:value-of select="ancestor-or-self::*[@status][1]/@status"/>
		</xsl:attribute>
	</xsl:if>
</xsl:template>

<!--
From: xhtml/docbook.xsl
Reason: Add confidential to footer
Version: 1.72.0
-->
<xsl:template name="user.footer.content">
	<xsl:param name="node" select="."/>
	<xsl:if test="$confidential = '1'">
		<h1 xmlns="http://www.w3.org/1999/xhtml" class="confidential">
			<xsl:text>Red Hat Confidential!</xsl:text>
		</h1>
	</xsl:if>
</xsl:template>

<!--
From: xhtml/block.xsl
Reason:  default class (otherwise) to formalpara
Version: 1.72.0
-->
<xsl:template match="formalpara">
	<xsl:call-template name="paragraph">
		<xsl:with-param name="class">
			<xsl:choose>
				<xsl:when test="@role and $para.propagates.style != 0">
					<xsl:value-of select="@role"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>formalpara</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:with-param>
		<xsl:with-param name="content">
			<xsl:call-template name="anchor"/>
			<xsl:apply-templates/>
		</xsl:with-param>
	</xsl:call-template>
</xsl:template>

<!--
From: xhtml/block.xsl
Reason:  h5 instead of <b>, remove default title end punctuation
Version: 1.72.0
-->
<xsl:template match="formalpara/title|formalpara/info/title">
	<xsl:variable name="titleStr">
			<xsl:apply-templates/>
	</xsl:variable>
	<h5 xmlns="http://www.w3.org/1999/xhtml" class="formalpara">
		<xsl:copy-of select="$titleStr"/>
	</h5>
</xsl:template>

<!--
From: xhtml/lists.xsl
Reason:  use role as class
Version: 1.72.0
-->
<xsl:template match="itemizedlist">
  <div xmlns="http://www.w3.org/1999/xhtml">
    <xsl:apply-templates select="." mode="class.attribute"/>
    <xsl:call-template name="anchor"/>
    <xsl:if test="title">
      <xsl:call-template name="formal.object.heading"/>
    </xsl:if>

    <!-- Preserve order of PIs and comments -->
    <xsl:apply-templates select="*[not(self::listitem or self::title or self::titleabbrev)] |
								  comment()[not(preceding-sibling::listitem)] |
								  processing-instruction()[not(preceding-sibling::listitem)]"/>
    <ul>
      <xsl:if test="@role">
        <xsl:apply-templates select="." mode="class.attribute">
          <xsl:with-param name="class" select="@role"/>
        </xsl:apply-templates>
      </xsl:if>
      <xsl:if test="$css.decoration != 0">
        <xsl:attribute name="type">
          <xsl:call-template name="list.itemsymbol"/>
        </xsl:attribute>
      </xsl:if>

      <xsl:if test="@spacing='compact'">
        <xsl:attribute name="compact">
          <xsl:value-of select="@spacing"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates select="listitem | comment()[preceding-sibling::listitem] | processing-instruction()[preceding-sibling::listitem]"/>
    </ul>
  </div>
</xsl:template>

<!--
From: xhtml/xref.xsl
Reason:  use role as class
Version: 1.72.0
-->
<xsl:template match="ulink" name="ulink">
  <xsl:param name="url" select="@url"/>
  <xsl:variable name="link">
    <a xmlns="http://www.w3.org/1999/xhtml">
      <xsl:if test="@id or @xml:id">
        <xsl:attribute name="id">
          <xsl:value-of select="(@id|@xml:id)[1]"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:attribute name="href"><xsl:value-of select="$url"/></xsl:attribute>
      <xsl:if test="$ulink.target != ''">
        <xsl:attribute name="target">
          <xsl:value-of select="$ulink.target"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@role">
        <xsl:apply-templates select="." mode="class.attribute">
          <xsl:with-param name="class" select="@role"/>
        </xsl:apply-templates>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="count(child::node())=0">
          <xsl:value-of select="$url"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates/>
        </xsl:otherwise>
      </xsl:choose>
    </a>
  </xsl:variable>
  <xsl:copy-of select="$link"/>
</xsl:template>


<xsl:template match="*" mode="class.attribute">
  <xsl:param name="class" select="local-name(.)"/>
  <!-- permit customization of class attributes -->
  <!-- Use element name by default -->
  <xsl:choose>
    <xsl:when test="@role">
      <xsl:attribute name="class">
        <xsl:value-of select="@role"/>
      </xsl:attribute>
	</xsl:when>
    <xsl:otherwise>
      <xsl:attribute name="class">
        <xsl:value-of select="$class"/>
      </xsl:attribute>
	</xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!--
From: xhtml/graphics.xsl
Reason:  allow long descr to be inline
Version: 1.72.0
-->
<xsl:template match="imagedata">
  <xsl:variable name="filename">
    <xsl:call-template name="mediaobject.filename">
      <xsl:with-param name="object" select=".."/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:choose>
    <xsl:when test="@format='linespecific'">
      <xsl:choose>
        <xsl:when test="$use.extensions != '0'                         and $textinsert.extension != '0'">
          <xsl:choose>
            <xsl:when test="element-available('stext:insertfile')">
              <stext:insertfile href="{$filename}" encoding="{$textdata.default.encoding}"/>
            </xsl:when>
            <xsl:when test="element-available('xtext:insertfile')">
              <xtext:insertfile href="{$filename}"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:message terminate="yes">
                <xsl:text>No insertfile extension available.</xsl:text>
              </xsl:message>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <a xlink:type="simple" xlink:show="embed" xlink:actuate="onLoad" href="{$filename}"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>
      <xsl:variable name="longdesc.uri">
        <xsl:call-template name="longdesc.uri">
          <xsl:with-param name="mediaobject" select="ancestor::imageobject/parent::*"/>
        </xsl:call-template>
      </xsl:variable>

      <xsl:variable name="phrases" select="ancestor::mediaobject/textobject[phrase]                             |ancestor::inlinemediaobject/textobject[phrase]                             |ancestor::mediaobjectco/textobject[phrase]"/>

      <xsl:call-template name="process.image">
        <xsl:with-param name="alt">
          <xsl:apply-templates select="$phrases[not(@role) or @role!='tex'][1]"/>
        </xsl:with-param>
        <xsl:with-param name="longdesc">
          <xsl:call-template name="write.longdesc">
            <xsl:with-param name="mediaobject" select="ancestor::imageobject/parent::*"/>
          </xsl:call-template>
        </xsl:with-param>
      </xsl:call-template>

      <xsl:if test="$html.longdesc != 0 and $html.longdesc.link != 0                     and ancestor::imageobject/parent::*/textobject[not(phrase)]">
        <xsl:call-template name="longdesc.link">
          <xsl:with-param name="longdesc.uri" select="$longdesc.uri"/>
        </xsl:call-template>
      </xsl:if>
      <xsl:if test="$html.longdesc.embed != 0 and ancestor::imageobject/parent::*/textobject[not(phrase)]">
        <div xmlns="http://www.w3.org/1999/xhtml" class="longdesc">
            <xsl:for-each select="ancestor::imageobject/parent::*/textobject[not(phrase)]">
              <xsl:apply-templates select="./*"/>
            </xsl:for-each>
        </div>
      </xsl:if>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="formal.object.heading">
  <xsl:param name="object" select="."/>
  <xsl:param name="title">
    <xsl:apply-templates select="$object" mode="object.title.markup">
      <xsl:with-param name="allow-anchors" select="1"/>
    </xsl:apply-templates>
  </xsl:param>
  <h6><xsl:copy-of select="$title"/></h6>
</xsl:template>

</xsl:stylesheet>
