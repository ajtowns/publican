<?xml version='1.0'?>
 
<!--
	Copyright 2007 Red Hat, Inc.
	License: GPL
	Author: Jeff Fearn <jfearn@redhat.com>
	Author: Tammy Fox <tfox@redhat.com>
	Author: Andy Fitzsimon <afitzsim@redhat.com>
-->

<!DOCTYPE xsl:stylesheet [
<!ENTITY lowercase "'abcdefghijklmnopqrstuvwxyz'">
<!ENTITY uppercase "'ABCDEFGHIJKLMNOPQRSTUVWXYZ'">
 ]>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		version='1.0'
		xmlns="http://www.w3.org/TR/xhtml1/transitional"
		xmlns:fo="http://www.w3.org/1999/XSL/Format"
		exclude-result-prefixes="#default">

<xsl:import href="http://docbook.sourceforge.net/release/xsl/current/fo/docbook.xsl"/>
<xsl:import href="http://docbook.sourceforge.net/release/xsl/current/fo/graphics.xsl"/>
<xsl:import href="../../../xsl/pdf.xsl"/>

<xsl:param name="title.color">#a70000</xsl:param>
<xsl:param name="admon.graphics.extension" select="'.svg'"/>

<!--<xsl:param name="chapter.autolabel" select="0"/>-->


<xsl:param name="local.l10n.xml" select="document('')"/> 
<l:i18n xmlns:l="http://docbook.sourceforge.net/xmlns/l10n/1.0">
  <l:l10n language="en">
    <l:context name="title-numbered">
      <l:template name="chapter" text="Lab %n: &#8220;%t&#8221;"/>
    </l:context>    
  </l:l10n>
<l:l10n language="ja">
    <l:context name="title-numbered">
      <l:template name="chapter" text="演習 %n: %t"/>
    </l:context>    
  </l:l10n>
</l:i18n>

<xsl:attribute-set name="remark.properties">
	<xsl:attribute name="font-style">italic</xsl:attribute>
	<xsl:attribute name="background-color">#ffff00</xsl:attribute>
</xsl:attribute-set>

</xsl:stylesheet>

