<?xml version='1.0'?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/1999/xhtml"
				xmlns:exsl="http://exslt.org/common"
				version="1.0"
				exclude-result-prefixes="exsl">

<xsl:import href="http://docbook.sourceforge.net/release/xsl/current/epub/docbook.xsl"/>
<xsl:import href="defaults.xsl"/>
<xsl:import href="xhtml-common.xsl"/>
<xsl:param name="suppress.navigation" select="1"/>
<xsl:param name="tablecolumns.extensions" select="1"/>
<xsl:param name="epub.oebps.dir" select="'OEBPS/'"/> 
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

</xsl:stylesheet>
