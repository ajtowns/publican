<?xml version='1.0'?>
 
<!--
	Copyright 2008 Red Hat, Inc.
	License: GPL
	Author: Jeff Fearn <jfearn@redhat.com>
-->
<!-- Transform bookinfo.xml into a OMF File -->
<xsl:stylesheet version="1.0" xml:space="preserve" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output encoding="UTF-8" indent="no" method="text" omit-xml-declaration="no" standalone="no" version="1.0"/>
<!-- Note: do not indent this file!  Any whitespace here
     will be reproduced in the output -->
<xsl:template match="/">&lt;?xml version="1.0" encoding="UTF-8"?&gt;
&lt;!DOCTYPE omf PUBLIC "-//OMF//DTD Scrollkeeper OMF Variant V1.0//EN" 
"http://scrollkeeper.sourceforge.net/dtds/scrollkeeper-omf-1.0/scrollkeeper-omf.dtd"&gt;
&lt;omf&gt;
  &lt;resource&gt;
    &lt;creator&gt;
         <xsl:value-of select="/bookinfo/copyright/holder" />
    &lt;/creator&gt;
    &lt;maintainer&gt;
        docs@redhat.com
    &lt;/maintainer&gt;
    &lt;title&gt;
	<xsl:value-of select="/bookinfo/subtitle"/><xsl:value-of select="/setinfo/subtitle"/>
    &lt;/title&gt;
    &lt;date&gt;
        <xsl:value-of select="/bookinfo/pubdate" />
    &lt;/date&gt;
    &lt;subject category="<xsl:value-of select="$prod" />|<xsl:value-of select="$category" />"/&gt;
    &lt;description&gt;
        <xsl:value-of select="/bookinfo/abstract/para" /><xsl:value-of select="/setinfo/abstract/para" />
    &lt;/description&gt;
    &lt;type&gt;
        Deployment Guide
    &lt;/type&gt;
    &lt;format mime="text/xml" dtd="-//OASIS//DTD DocBook XML V4.1.2//EN"/&gt;
    &lt;identifier url="file:///usr/share/doc/<xsl:value-of select="$book-title"/>-<xsl:value-of select="$lang"/>-<xsl:value-of select="/bookinfo/issuenum"/><xsl:value-of select="/setinfo/issuenum"/>/<xsl:value-of select="$docname"/>.xml"/&gt;
    &lt;language code="<xsl:value-of select="$lang2"/>"/&gt;
    &lt;relation seriesid="<xsl:value-of select="$book-title"/>-<xsl:value-of select="/bookinfo/issuenum"/><xsl:value-of select="/setinfo/issuenum"/>"/&gt;
    &lt;rights type="OPL" license.version="1.1" holder="<xsl:value-of select="/bookinfo/copyright/holder" />"/&gt;
  &lt;/resource&gt;
&lt;/omf&gt;
</xsl:template>

</xsl:stylesheet>

