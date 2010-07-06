<?xml version='1.0'?>

<!-- Transform bookinfo.xml into a SPEC File -->
<xsl:stylesheet version="1.0" xml:space="preserve" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output encoding="UTF-8" indent="no" method="text" omit-xml-declaration="no" standalone="no" version="1.0"/>
<!-- Note: do not indent this file!  Any whitespace here
     will be reproduced in the output -->
<xsl:template match="/"># Documentation Specfile
%define HTMLVIEW %(test "%{?dist}" == ".el5" &amp;&amp; echo 1 || echo 0)
%define ICONS <xsl:value-of select="$ICONS"/>

%define viewer xdg-open

%if %{HTMLVIEW}
%define viewer htmlview
%define vendor redhat-
%define vendoropt --vendor="redhat"
%endif

Name:         <xsl:value-of select="$book-title"/>-<xsl:value-of select="$lang"/>
Version:      <xsl:value-of select="$rpmver"/>
Release:      <xsl:value-of select="$rpmrel"/>%{?dist}
<xsl:if test="$translation = '1'">
Summary:      <xsl:value-of select="$language"/> translation of <xsl:value-of select="$docname"/>
Summary(<xsl:value-of select="$lang"/>):    <xsl:value-of select="/bookinfo/subtitle"/><xsl:value-of select="/setinfo/subtitle"/><xsl:value-of select="/articleinfo/subtitle"/>
</xsl:if>
<xsl:if test="$translation != '1'">
Summary:       <xsl:value-of select="/bookinfo/subtitle"/><xsl:value-of select="/setinfo/subtitle"/><xsl:value-of select="/articleinfo/subtitle"/>
</xsl:if>
Group:         Documentation
License:       <xsl:value-of select="$license"/>
URL:           <xsl:value-of select="$url"/>
Source:        <xsl:value-of select="$src_url"/>%{name}-%{version}-<xsl:value-of select="$rpmrel"/>.tgz
BuildArch:     noarch
BuildRoot:     %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires: publican >= 2.0
BuildRequires: desktop-file-utils
<xsl:if test="$brand != 'publican-common'">BuildRequires:    <xsl:value-of select="$brand"/></xsl:if>

%if %{HTMLVIEW}
Requires:    htmlview
%else
Requires:    xdg-utils
%endif

%description
<xsl:if test="$translation = '1'"><xsl:value-of select="$language"/> translation of <xsl:value-of select="$docname"/>

%description -l <xsl:value-of select="$lang"/></xsl:if>
<xsl:value-of select="$abstract" />

%prep
%setup -q

%build
publican build --formats="html-desktop" --langs=<xsl:value-of select="$lang"/>

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT%{_datadir}/applications

%if %{ICONS}
for icon in `ls icons/*x*.png`; do
	size=`echo "$icon" | sed -e 's/icons\/\(.*\)\.png/\1/'`;
	mkdir -p $RPM_BUILD_ROOT/usr/share/icons/hicolor/$size/apps
	cp $icon  $RPM_BUILD_ROOT/usr/share/icons/hicolor/$size/apps/<xsl:value-of select="$book-title"/>-<xsl:value-of select="$lang"/>.png;
done
mkdir -p $RPM_BUILD_ROOT/usr/share/icons/hicolor/scalable/apps
cp icons/icon.svg  $RPM_BUILD_ROOT/usr/share/icons/hicolor/scalable/apps/<xsl:value-of select="$book-title"/>-<xsl:value-of select="$lang"/>.svg;
%else
cp images/icon.svg  $RPM_BUILD_ROOT/usr/share/icons/hicolor/scalable/apps/<xsl:value-of select="$book-title"/>-<xsl:value-of select="$lang"/>.svg;
%endif

cat > %{name}.desktop &lt;&lt;'EOF'
[Desktop Entry]
Name=<xsl:value-of select="/bookinfo/productname" /><xsl:value-of select="/setinfo/productname" /><xsl:value-of select="/articleinfo/productname"/> <xsl:value-of select="/bookinfo/productnumber" /><xsl:value-of select="/setinfo/productnumber" /><xsl:value-of select="/articleinfo/productnumber"/>: <xsl:value-of select="/bookinfo/title" /><xsl:value-of select="/setinfo/title" /><xsl:value-of select="/articleinfo/title"/>
Comment=<xsl:value-of select="/bookinfo/subtitle"/><xsl:value-of select="/setinfo/subtitle"/><xsl:value-of select="/articleinfo/subtitle"/>
Exec=%{viewer} %{_docdir}/%{name}-%{version}/index.html
Icon=<xsl:value-of select="$book-title"/>-<xsl:value-of select="$lang"/>
Categories=Documentation;X-Red-Hat-Base;
Type=Application
Encoding=UTF-8
Terminal=false
EOF

%if %{HTMLVIEW}
desktop-file-install  %{?vendoropt} --dir=${RPM_BUILD_ROOT}%{_datadir}/applications %{name}.desktop
%else
desktop-file-install --dir=${RPM_BUILD_ROOT}%{_datadir}/applications %{name}.desktop
%endif

# Update Icon cache if it exists
%post
touch --no-create %{_datadir}/icons/hicolor &amp;>/dev/null || :

%postun
if [ $1 -eq 0 ] ; then
    touch --no-create %{_datadir}/icons/hicolor &amp;>/dev/null
    gtk-update-icon-cache %{_datadir}/icons/hicolor &amp;>/dev/null || :
fi

%posttrans
gtk-update-icon-cache %{_datadir}/icons/hicolor &amp;>/dev/null || :

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc tmp/<xsl:value-of select="$lang"/>/html-desktop/*
%if %{ICONS}
/usr/share/icons/hicolor/*
%endif
%if %{HTMLVIEW}
%{_datadir}/applications/%{?vendor}%{name}.desktop
%else
%{_datadir}/applications/%{name}.desktop
%endif

%changelog
<xsl:value-of select="$log"/>

</xsl:template>

</xsl:stylesheet>

