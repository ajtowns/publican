<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:outline="http://code.google.com/p/wkhtmltopdf/outline"
                xmlns="http://www.w3.org/1999/xhtml">
  <xsl:output doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN"
              doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"
              indent="yes" />
  <xsl:template match="outline:outline">
    <html>
      <head>
        <title>Table of Content</title>
        <style>
          h1 {
            text-align: center;
            font-size: 20px;
            font-family: sans-serif;
          }
          div { }
          span.page {
            float: right;
            padding-left: 2em !important;
            margin-left: 2em !important;
            background: white;
          }
          li li span.filler {
            border-style: none !important;
          }
          li {list-style: none;}
          ul {
            font-size: 14px;
            font-family: sans-serif;
            overflow-x: hidden;
          }

          li div{
            margin-top: 1em;
            font-weight: bold;
          }
          li li div {
            font-weight: normal;
            margin-top: 0.1em;
            width: 100%
          }
          ul ul { }
          ul {
            padding-left: 0em;
          }
          ul ul {
            padding-left: 1em;
          }
          a {
            text-decoration:none;
            color: black;
            background: white;
            padding-right: 0.5em;
          }
          body > ul > li:before {
            float: left;
            width: 0;
            white-space: nowrap;
            content:
 ". . . . . . . . . . . . . . . . . . . . "
 ". . . . . . . . . . . . . . . . . . . . "
 ". . . . . . . . . . . . . . . . . . . . "
 ". . . . . . . . . . . . . . . . . . . . "
 ". . . . . . . . . . . . . . . . . . . . "
 ". . . . . . . . . . . . . . . . . . . . "
 ". . . . . . . . . . . . . . . . . . . . "
 ". . . . . . . . . . . . . . . . . . . . "
 ". . . . . . . . . . . . . . . . . . . . "
 ". . . . . . . . . . . . . . . . . . . . "
 ". . . . . . . . . . . . . . . . . . . . "
 ". . . . . . . . . . . . . . . . . . . . "
 ". . . . . . . . . . . . . . . . . . . . "
 ". . . . . . . . . . . . . . . . . . . . ";
          }
 </style>
      </head>
      <body>
        <h1>Table of Contents</h1>
        <ul><xsl:apply-templates select="outline:item/outline:item"/></ul>
      </body>
    </html>
  </xsl:template>
  <xsl:template match="outline:item">
    <li>
      <xsl:if test="@title!=''">
        <div>
          <a>
            <xsl:if test="@link">
              <xsl:attribute name="href"><xsl:value-of select="@link"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="@backLink">
              <xsl:attribute name="name"><xsl:value-of select="@backLink"/></xsl:attribute>
            </xsl:if>
            <xsl:value-of select="@title" />
          </a>
          <span class="page"> <xsl:value-of select="@page" /> </span>
        </div>
      </xsl:if>
      <ul>
        <xsl:apply-templates select="outline:item"/>
      </ul>
    </li>
  </xsl:template>
</xsl:stylesheet>
