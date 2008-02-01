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
<!--xsl:import href="http://docbook.sourceforge.net/release/xsl/1.72.0/htmlhelp/htmlhelp.xsl"/-->
<xsl:import href="http://docbook.sourceforge.net/release/xsl/1.72.0/xhtml/docbook.xsl"/>
<xsl:import href="http://docbook.sourceforge.net/release/xsl/1.72.0/xhtml/chunk-common.xsl"/>
<xsl:import href="http://docbook.sourceforge.net/release/xsl/1.72.0/xhtml/chunk-code.xsl"/>
<xsl:import href="xhtml-common.xsl"/>

<xsl:include href="defaults.xsl"/>

<xsl:param name="suppress.navigation" select="1"/>
<xsl:param name="suppress.header.navigation" select="1"/>
<xsl:param name="suppress.footer.navigation" select="1"/>

<xsl:param name="chunk.section.depth" select="5"/>
<xsl:param name="chunk.first.sections" select="1"/>
<xsl:param name="chunk.toc" select="''"/>
<xsl:param name="chapter.autolabel" select="0"/>
<!-- TOC -->
<xsl:param name="section.autolabel" select="0"/>
<xsl:param name="appendix.autolabel" select="0"/>
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
section nop
part toc
appendix toc
</xsl:param>

</xsl:stylesheet>
