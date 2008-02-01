<!-- Get subtitle from Book_Info.xml for a language -->
<xsl:stylesheet version="1.0" xml:space="preserve" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output encoding="UTF-8" indent="no" method="text" omit-xml-declaration="no" standalone="no" version="1.0"/>
<xsl:template match="/"><xsl:apply-templates select="//revision"/></xsl:template>
<xsl:template match="revision">
<xsl:text>* </xsl:text><xsl:value-of select="./date"/><xsl:text> </xsl:text><xsl:value-of select="./author/firstname"/><xsl:text> </xsl:text><xsl:value-of select="./author/surname"/><xsl:text> </xsl:text><xsl:value-of select="./author/email"/><xsl:text> </xsl:text><xsl:value-of select="./revnumber"/>
<xsl:apply-templates select="revdescription/simplelist/member"/>
</xsl:template>
<xsl:template match="member"><xsl:text>- </xsl:text><xsl:value-of select="."/>
</xsl:template>
</xsl:stylesheet>

