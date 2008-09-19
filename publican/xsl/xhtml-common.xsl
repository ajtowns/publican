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
				xmlns:xslthl="http://xslthl.sf.net"
				version="1.0"
				exclude-result-prefixes="xlink exsl stext xtext"
				extension-element-prefixes="stext xtext xslthl"
>

<!-- Admonition Graphics -->
<xsl:param name="admon.graphics" select="1"/>
<xsl:param name="admon.style" select="''"/>
<xsl:param name="admon.graphics.path">./Common_Content/images/</xsl:param>
<xsl:param name="callout.graphics.path">./Common_Content/images/</xsl:param>

<xsl:param name="chunker.output.doctype-public" select="'-//W3C//DTD XHTML 1.0 Strict//EN'"/>
<xsl:param name="chunker.output.doctype-system" select="'http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd'"/>
<xsl:param name="chunker.output.encoding" select="'UTF-8'"/>
<xsl:param name="chunker.output.indent" select="'no'"/>
<xsl:param name="html.longdesc.link" select="0"/>
<xsl:param name="html.longdesc" select="0"/>
<xsl:param name="html.longdesc.embed" select="1"/>

<xsl:param name="html.stylesheet" select="'./Common_Content/css/default.css'"/>
<xsl:param name="html.stylesheet.type" select="'text/css'"/>
<xsl:param name="html.cleanup" select="0"/>
<xsl:param name="html.ext" select="'.html'"/>
<xsl:output method="xml" indent="no"/>
<xsl:param name="highlight.source" select="1"/>
<xsl:param name="tablecolumns.extensions" select="1"/>

<xsl:param name="qanda.in.toc" select="0"/>
<xsl:param name="segmentedlist.as.table" select="1"/>
<xsl:param name="othercredit.like.author.enabled" select="0"/>
<xsl:param name="email.delimiters.enabled">0</xsl:param>

<xsl:param name="generate.id.attributes" select="0"/>

<!-- TOC -->
<xsl:param name="section.autolabel" select="1"/>
<xsl:param name="section.label.includes.component.label" select="1"/>

<xsl:param name="generate.toc">
set toc
book toc
article toc
chapter toc
qandadiv toc
qandaset toc
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

	<meta xmlns="http://www.w3.org/1999/xhtml" name="generator" content="publican"/>

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
	<!--xsl:call-template name="paragraph">
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
	</xsl:call-template-->
	<xsl:apply-templates/>
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
      <xsl:call-template name="anchor">
        <xsl:with-param name="node" select=".."/>
        <xsl:with-param name="conditional" select="0"/>
      </xsl:call-template>
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

<!--
From: xhtml/qandaset.xsl
Reason: No stinking tables
Version: 1.72.0
-->

<xsl:template name="qandaset">
  <div class="qandaset">
    <xsl:apply-templates select="." mode="class.attribute"/>
    <xsl:apply-templates />
  </div>
</xsl:template>

<xsl:template name="process.qandaset">
  <div class="qandaset">
    <xsl:apply-templates select="." mode="class.attribute"/>
    <xsl:apply-templates />
  </div>
</xsl:template>

<xsl:template match="qandadiv">
  <xsl:variable name="preamble" select="*[local-name(.) != 'title'                                           and local-name(.) != 'titleabbrev'                                           and local-name(.) != 'qandadiv'                                           and local-name(.) != 'qandaentry']"/>

  <xsl:if test="blockinfo/title|info/title|title">
    <div class="qandadiv">
        <xsl:apply-templates select="(blockinfo/title|info/title|title)[1]"/>
    </div>
  </xsl:if>

  <xsl:variable name="toc">
    <xsl:call-template name="dbhtml-attribute">
      <xsl:with-param name="pis" select="processing-instruction('dbhtml')"/>
      <xsl:with-param name="attribute" select="'toc'"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="toc.params">
    <xsl:call-template name="find.path.params">
      <xsl:with-param name="table" select="normalize-space($generate.toc)"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:if test="(contains($toc.params, 'toc') and $toc != '0') or $toc = '1'">
    <div class="toc">
        <xsl:call-template name="process.qanda.toc"/>
    </div>
  </xsl:if>
  <xsl:if test="$preamble">
    <div class="preamble">
        <xsl:apply-templates select="$preamble"/>
    </div>
  </xsl:if>
  <div>
    <xsl:apply-templates select="." mode="class.attribute"/>
    <xsl:apply-templates select="qandadiv|qandaentry"/>
  </div>
</xsl:template>

<xsl:template match="qandaentry">
  <div>
    <xsl:apply-templates select="." mode="class.attribute"/>
    <xsl:apply-templates/>
  </div>
</xsl:template>

<xsl:template match="question">
  <xsl:variable name="deflabel">
    <xsl:choose>
      <xsl:when test="ancestor-or-self::*[@defaultlabel]">
        <xsl:value-of select="(ancestor-or-self::*[@defaultlabel])[last()] /@defaultlabel"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$qanda.defaultlabel"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:variable name="label.content">
    <xsl:apply-templates select="." mode="label.markup"/>
    <xsl:if test="$deflabel = 'number' and not(label)">
      <xsl:apply-templates select="." mode="intralabel.punctuation"/>
    </xsl:if>
  </xsl:variable>
  <div>
    <xsl:apply-templates select="." mode="class.attribute"/>
      <xsl:call-template name="anchor">
        <xsl:with-param name="node" select=".."/>
        <xsl:with-param name="conditional" select="0"/>
      </xsl:call-template>
      <!--xsl:call-template name="anchor">
        <xsl:with-param name="conditional" select="0"/>
      </xsl:call-template-->
      <xsl:if test="string-length($label.content) &gt; 0">
        <label>
          <xsl:copy-of select="$label.content"/>
        </label>
      </xsl:if>
    <div class="data">
      <xsl:apply-templates/>
    </div>
  </div>
</xsl:template>

<xsl:template match="answer">
  <xsl:variable name="deflabel">
    <xsl:choose>
      <xsl:when test="ancestor-or-self::*[@defaultlabel]">
        <xsl:value-of select="(ancestor-or-self::*[@defaultlabel])[last()] /@defaultlabel"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$qanda.defaultlabel"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <div>
    <xsl:apply-templates select="." mode="class.attribute"/>
    <xsl:variable name="answer.label">
      <xsl:apply-templates select="." mode="label.markup"/>
    </xsl:variable>
    <xsl:if test="string-length($answer.label) &gt; 0">
      <label>
        <xsl:copy-of select="$answer.label"/>
      </label>
    </xsl:if>
     <div class="data">
       <xsl:apply-templates />
     </div>
   </div>
</xsl:template>

<xsl:template match="xslthl:keyword">
  <span class="hl-keyword"><xsl:apply-templates/></span>
</xsl:template>

<xsl:template match="xslthl:string">
  <span class="hl-string"><xsl:apply-templates/></span>
</xsl:template>

<xsl:template match="xslthl:comment">
  <span class="hl-comment"><xsl:apply-templates/></span>
</xsl:template>

<xsl:template match="xslthl:tag">
  <span class="hl-tag"><xsl:apply-templates/></span>
</xsl:template>

<xsl:template match="xslthl:attribute">
  <span class="hl-attribute"><xsl:apply-templates/></span>
</xsl:template>

<xsl:template match="xslthl:value">
  <span class="hl-value"><xsl:apply-templates/></span>
</xsl:template>

<xsl:template match="xslthl:html">
  <span class="hl-html"><xsl:apply-templates/></span>
</xsl:template>

<xsl:template match="xslthl:xslt">
  <span class="hl-xslt"><xsl:apply-templates/></span>
</xsl:template>

<xsl:template match="xslthl:section">
  <span class="hl-section"><xsl:apply-templates/></span>
</xsl:template>

<xsl:template match="xslthl:directive">
  <span class="hl-directive"><xsl:apply-templates/></span>
</xsl:template>

<xsl:template match="xslthl:doctype">
  <span class="hl-doctype"><xsl:apply-templates/></span>
</xsl:template>

<xsl:template match="productnumber" mode="book.titlepage.recto.auto.mode">
<xsl:apply-templates select="." mode="book.titlepage.recto.mode"/>
</xsl:template>

<xsl:template match="productname" mode="titlepage.mode">
  <span>
    <xsl:apply-templates select="." mode="class.attribute"/>
    <xsl:apply-templates mode="titlepage.mode"/>
  </span>
</xsl:template>

<xsl:template match="productnumber" mode="titlepage.mode">
  <span>
    <xsl:apply-templates select="." mode="class.attribute"/>
    <xsl:apply-templates mode="titlepage.mode"/>
  </span>
</xsl:template>

<xsl:template match="productname" mode="book.titlepage.recto.auto.mode">
<xsl:apply-templates select="." mode="book.titlepage.recto.mode"/>
</xsl:template>

<xsl:template match="orgdiv" mode="titlepage.mode">
  <xsl:if test="preceding-sibling::*[1][self::orgname]">
    <xsl:text> </xsl:text>
  </xsl:if>
  <span>
    <xsl:apply-templates select="." mode="class.attribute"/>
    <xsl:apply-templates mode="titlepage.mode"/>
  </span>
</xsl:template>

<xsl:template match="orgname" mode="titlepage.mode">
  <span>
    <xsl:apply-templates select="." mode="class.attribute"/>
    <xsl:apply-templates mode="titlepage.mode"/>
  </span>
</xsl:template>

<xsl:template name="book.titlepage.recto">
  <xsl:choose>
    <xsl:when test="bookinfo/productname">
	<div class="producttitle" xsl:use-attribute-sets="book.titlepage.recto.style">
	  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="bookinfo/productname"/>
	  <xsl:text> </xsl:text>
	  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="bookinfo/productnumber"/>
	</div>
    </xsl:when>
  </xsl:choose>
  <xsl:choose>
    <xsl:when test="bookinfo/title">
      <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="bookinfo/title"/>
    </xsl:when>
    <xsl:when test="info/title">
      <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="info/title"/>
    </xsl:when>
    <xsl:when test="title">
      <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="title"/>
    </xsl:when>
  </xsl:choose>

  <xsl:choose>
    <xsl:when test="bookinfo/subtitle">
      <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="bookinfo/subtitle"/>
    </xsl:when>
    <xsl:when test="info/subtitle">
      <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="info/subtitle"/>
    </xsl:when>
    <xsl:when test="subtitle">
      <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="subtitle"/>
    </xsl:when>
  </xsl:choose>

  <xsl:apply-templates mode="titlepage.mode" select="bookinfo/edition"/>
  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="bookinfo/corpauthor"/>
  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="info/corpauthor"/>
  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="bookinfo/authorgroup"/>
  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="info/authorgroup"/>
  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="bookinfo/author"/>
  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="info/author"/>
  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="bookinfo/othercredit"/>
  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="info/othercredit"/>
  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="bookinfo/releaseinfo"/>
  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="info/releaseinfo"/>
  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="bookinfo/copyright"/>
  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="info/copyright"/>
  <hr/>
  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="bookinfo/legalnotice"/>
  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="info/legalnotice"/>
  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="bookinfo/pubdate"/>
  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="info/pubdate"/>
  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="bookinfo/revision"/>
  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="info/revision"/>
  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="bookinfo/revhistory"/>
  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="info/revhistory"/>
  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="bookinfo/abstract"/>
  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="info/abstract"/>
</xsl:template>

<xsl:template match="legalnotice" mode="titlepage.mode">
  <xsl:variable name="id"><xsl:call-template name="object.id"/></xsl:variable>
  <xsl:choose>
    <xsl:when test="$generate.legalnotice.link != 0">
      <xsl:variable name="filename">
        <xsl:call-template name="make-relative-filename">
          <xsl:with-param name="base.dir" select="$base.dir"/>
	  <xsl:with-param name="base.name">
            <xsl:apply-templates mode="chunk-filename" select="."/>
	  </xsl:with-param>
        </xsl:call-template>
      </xsl:variable>

      <xsl:variable name="title">
        <xsl:apply-templates select="." mode="title.markup"/>
      </xsl:variable>

      <xsl:variable name="href">
        <xsl:apply-templates mode="chunk-filename" select="."/>
      </xsl:variable>

      <a href="{$href}"><xsl:copy-of select="$title"/></a>

      <xsl:call-template name="write.chunk">
        <xsl:with-param name="filename" select="$filename"/>
        <xsl:with-param name="quiet" select="$chunk.quietly"/>
        <xsl:with-param name="content">
        <xsl:call-template name="user.preroot"/>
          <html>
            <head>
              <xsl:call-template name="system.head.content"/>
              <xsl:call-template name="head.content"/>
              <xsl:call-template name="user.head.content"/>
            </head>
            <body>
              <xsl:call-template name="body.attributes"/>
              <div>
                <xsl:apply-templates select="." mode="class.attribute"/>
                <xsl:apply-templates mode="titlepage.mode"/>
              </div>
            </body>
          </html>
          <xsl:value-of select="$chunk.append"/>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <div id="{$id}">
        <xsl:apply-templates select="." mode="class.attribute"/>
        <!--a id="{$id}"/-->
	<h1 class="legalnotice">
    <xsl:call-template name="gentext">
      <xsl:with-param name="key">legalnotice</xsl:with-param>
    </xsl:call-template>
	</h1>
        <xsl:apply-templates mode="titlepage.mode"/>
      </div>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="anchor">
  <xsl:param name="node" select="."/>
  <xsl:param name="conditional" select="1"/>
  <xsl:variable name="id">
    <xsl:call-template name="object.id">
      <xsl:with-param name="object" select="$node"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:if test="$conditional = 0 or $node/@id or $node/@xml:id">
	<xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
    <!--a id="{$id}"/-->
  </xsl:if>
</xsl:template>

<xsl:template match="title" mode="titlepage.mode">
  <xsl:variable name="id">
    <xsl:choose>
      <!-- if title is in an *info wrapper, get the grandparent -->
      <xsl:when test="contains(local-name(..), 'info')">
        <xsl:call-template name="object.id">
          <xsl:with-param name="object" select="../.."/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="object.id">
          <xsl:with-param name="object" select=".."/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
<!-- need id here because some blocks with titles don't have their id's set-->
  <h1 id="{$id}">
    <xsl:apply-templates select="." mode="class.attribute"/>
    <!--a id="{$id}"/-->
    <xsl:choose>
      <xsl:when test="$show.revisionflag != 0 and @revisionflag">
	<span class="{@revisionflag}">
	  <xsl:apply-templates mode="titlepage.mode"/>
	</span>
      </xsl:when>
      <xsl:otherwise>
	<xsl:apply-templates mode="titlepage.mode"/>
      </xsl:otherwise>
    </xsl:choose>
  </h1>
</xsl:template>

<xsl:template match="chapter/title" mode="titlepage.mode" priority="2">
  <xsl:call-template name="component.title">
    <xsl:with-param name="node" select="ancestor::chapter[1]"/>
  </xsl:call-template>
</xsl:template>

<xsl:template match="section/title                     |section/info/title                     |sectioninfo/title" mode="titlepage.mode" priority="2">
  <xsl:call-template name="section.title"/>
</xsl:template>

<xsl:template match="edition" mode="titlepage.mode">
  <p>
    <xsl:apply-templates select="." mode="class.attribute"/>
    <xsl:call-template name="gentext">
      <xsl:with-param name="key" select="'Edition'"/>
    </xsl:call-template>
    <xsl:call-template name="gentext.space"/>
    <xsl:apply-templates mode="titlepage.mode"/>
  </p>
</xsl:template>

<xsl:template name="article.titlepage.recto">
  <xsl:choose>
    <xsl:when test="articleinfo/productname">
	<div class="producttitle" xsl:use-attribute-sets="book.titlepage.recto.style">
	  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="articleinfo/productname"/>
	  <xsl:text> </xsl:text>
	  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="articleinfo/productnumber"/>
	</div>
    </xsl:when>
  </xsl:choose>
  <xsl:choose>
    <xsl:when test="articleinfo/title">
      <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="articleinfo/title"/>
    </xsl:when>
    <xsl:when test="artheader/title">
      <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="artheader/title"/>
    </xsl:when>
    <xsl:when test="info/title">
      <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="info/title"/>
    </xsl:when>
    <xsl:when test="title">
      <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="title"/>
    </xsl:when>
  </xsl:choose>

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
