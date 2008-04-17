<?xml version='1.0'?>
 
<!--
	Copyright 2007 Red Hat, Inc.
	License: GPL
	Author: Jeff Fearn <jfearn@redhat.com>
	Author: Tammy Fox <tfox@redhat.com>
	Author: Andy Fitzsimon <afitzsim@redhat.com>
-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
				xmlns:exsl="http://exslt.org/common"
				version="1.0"
				exclude-result-prefixes="exsl">

<xsl:import href="http://docbook.sourceforge.net/release/xsl/current/eclipse/eclipse.xsl"/>

<xsl:include href="defaults.xsl"/>
<xsl:include href="xhtml-common.xsl"/>
<xsl:param name="confidential" select="0"/>

<xsl:param name="generate.legalnotice.link" select="1"/>
<xsl:param name="generate.revhistory.link" select="0"/>

<xsl:param name="chunk.section.depth" select="4"/>
<xsl:param name="chunk.first.sections" select="1"/>
<xsl:param name="chunk.toc" select="''"/>

<!--
From: xhtml/footnote.xsl
Reason: remove inline css from hr
Version: 1.72.0
-->
<xsl:template name="process.footnotes">
  <xsl:variable name="footnotes" select=".//footnote"/>
  <xsl:variable name="table.footnotes" select=".//tgroup//footnote"/>

  <!-- Only bother to do this if there's at least one non-table footnote -->
  <xsl:if test="count($footnotes)&gt;count($table.footnotes)">
    <div class="footnotes">
      <br/>
      <hr/>
      <xsl:apply-templates select="$footnotes" mode="process.footnote.mode"/>
    </div>
  </xsl:if>

  <xsl:if test="$annotation.support != 0 and //annotation">
    <div class="annotation-list">
      <div class="annotation-nocss">
	<p>The following annotations are from this essay. You are seeing
	them here because your browser doesn&#8217;t support the user-interface
	techniques used to make them appear as &#8216;popups&#8217; on modern browsers.</p>
      </div>

      <xsl:apply-templates select="//annotation" mode="annotation-popup"/>
    </div>
  </xsl:if>
</xsl:template>

</xsl:stylesheet>
