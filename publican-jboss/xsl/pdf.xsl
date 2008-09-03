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
<xsl:import href="../defaults.xsl"/>
<xsl:import href="../pdf.xsl"/>

<xsl:param name="title.color">#a70000</xsl:param>
<xsl:param name="admon.graphics.extension" select="'.svg'"/>

<xsl:template name="pickfont-sans">
	<xsl:variable name="font">
		<xsl:choose>
			<xsl:when test="$l10n.gentext.language = 'ja-JP'">
				<xsl:text>HGGothicB,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'ko-KR'">
				<xsl:text>BaekmukBatang,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'zh-CN'">
				<xsl:text>Zysong,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'as-IN'">
				<xsl:text>LohitBengali,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'bn-IN'">
				<xsl:text>LohitBengali,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'ta-IN'">
				<xsl:text>LohitTamil,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'pa-IN'">
				<xsl:text>LohitPunjabi,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'hi-IN'">
				<xsl:text>Lohit-Hindi,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'mr-IN'">
				<xsl:text>Lohit-Hindi,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'gu-IN'">
				<xsl:text>LohitGujarati,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'zh-TW'">
				<xsl:text>Uming,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'kn-IN'">
				<xsl:text>LohitKannada,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'ml-IN'">
				<xsl:text>LohitMalayalam,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'or-IN'">
				<xsl:text>LohitOriya,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'te-IN'">
				<xsl:text>LohitTelugu,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'si-LK'">
				<xsl:text>Lklug,</xsl:text>
			</xsl:when>
		</xsl:choose>
	</xsl:variable>
	<xsl:copy-of select="$font"/><xsl:text>LiberationSans,sans-serif</xsl:text>
</xsl:template>

<xsl:template name="pickfont-serif">
	<xsl:variable name="font">
		<xsl:choose>
			<xsl:when test="$l10n.gentext.language = 'ja-JP'">
				<xsl:text>HGGothicB,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'ko-KR'">
				<xsl:text>BaekmukBatang,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'zh-CN'">
				<xsl:text>Zysong,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'as-IN'">
				<xsl:text>LohitBengali,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'bn-IN'">
				<xsl:text>LohitBengali,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'ta-IN'">
				<xsl:text>LohitTamil,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'pa-IN'">
				<xsl:text>LohitPunjabi,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'hi-IN'">
				<xsl:text>Lohit-Hindi,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'mr-IN'">
				<xsl:text>Lohit-Hindi,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'gu-IN'">
				<xsl:text>LohitGujarati,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'zh-TW'">
				<xsl:text>Uming,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'kn-IN'">
				<xsl:text>LohitKannada,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'ml-IN'">
				<xsl:text>LohitMalayalam,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'or-IN'">
				<xsl:text>LohitOriya,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'te-IN'">
				<xsl:text>LohitTelugu,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'si-LK'">
				<xsl:text>Lklug,</xsl:text>
			</xsl:when>
		</xsl:choose>
	</xsl:variable>
	<xsl:copy-of select="$font"/><xsl:text>LiberationSerif,serif</xsl:text>
</xsl:template>

<xsl:template name="pickfont-mono">
	<xsl:variable name="font">
		<xsl:choose>
			<xsl:when test="$l10n.gentext.language = 'ja-JP'">
				<xsl:text>HGGothicB,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'ko-KR'">
				<xsl:text>BaekmukBatang,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'zh-CN'">
				<xsl:text>Zysong,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'as-IN'">
				<xsl:text>LohitBengali,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'bn-IN'">
				<xsl:text>LohitBengali,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'ta-IN'">
				<xsl:text>LohitTamil,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'pa-IN'">
				<xsl:text>LohitPunjabi,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'hi-IN'">
				<xsl:text>Lohit-Hindi,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'mr-IN'">
				<xsl:text>Lohit-Hindi,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'gu-IN'">
				<xsl:text>LohitGujarati,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'zh-TW'">
				<xsl:text>Uming,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'kn-IN'">
				<xsl:text>LohitKannada,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'ml-IN'">
				<xsl:text>LohitMalayalam,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'or-IN'">
				<xsl:text>LohitOriya,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'te-IN'">
				<xsl:text>LohitTelugu,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'si-LK'">
				<xsl:text>Lklug,</xsl:text>
			</xsl:when>
		</xsl:choose>
	</xsl:variable>
       <xsl:copy-of select="$font"/><xsl:text>LiberationMono,monospace</xsl:text>
</xsl:template>

</xsl:stylesheet>

