<?xml version='1.0'?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/1999/xhtml"
				xmlns:exsl="http://exslt.org/common"
				version="1.0"
				exclude-result-prefixes="exsl">

<xsl:import href="http://docbook.sourceforge.net/release/xsl/current/epub/docbook.xsl"/>
<xsl:include href="defaults.xsl"/>
<xsl:include href="xhtml-common.xsl"/>

<xsl:param name="tablecolumns.extensions" select="1"/>
<xsl:param name="epub.oebps.dir" select="'OEBPS/'"/> 

</xsl:stylesheet>
