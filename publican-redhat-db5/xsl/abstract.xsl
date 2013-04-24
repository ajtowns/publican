<!-- Get abstract from Book_Info.xml -->
<xsl:stylesheet version="1.0" xml:space="preserve" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:d="http://docbook.org/ns/docbook">
<xsl:output encoding="UTF-8" indent="no" method="text" omit-xml-declaration="no" standalone="no" version="1.0"/>
<xsl:template match="/"><xsl:value-of select="//bookinfo/abstract"/><xsl:value-of select="//setinfo/abstract"/><xsl:value-of select="//articleinfo/abstract"/><xsl:value-of select="/d:info/d:abstract"/><xsl:value-of select="/d:book/d:info/d:abstract" /><xsl:value-of select="/d:set/d:info/d:abstract" /><xsl:value-of select="/d:article/d:info/d:abstract" />
</xsl:template>
</xsl:stylesheet>
