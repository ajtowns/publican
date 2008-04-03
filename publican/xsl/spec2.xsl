<?xml version='1.0'?>
 
<!--
	Copyright 2007 Red Hat, Inc.
	License: GPL
	Author: Jeff Fearn <jfearn@redhat.com>
-->
<!-- Transform bookinfo.xml into a SPEC File -->
<xsl:stylesheet version="1.0" xml:space="preserve" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output encoding="UTF-8" indent="no" method="text" omit-xml-declaration="no" standalone="no" version="1.0"/>
<!-- Note: do not indent this file!  Any whitespace here
     will be reproduced in the output -->
<xsl:template match="/"># Red Hat Documentation Specfile
Name:           <xsl:value-of select="$book-title"/>
Version:        <xsl:value-of select="/bookinfo/issuenum"/><xsl:value-of select="/setinfo/issuenum"/>
Release:        <xsl:value-of select="/bookinfo/productnumber"/><xsl:value-of select="/setinfo/productnumber"/>
Summary:        <xsl:value-of select="/bookinfo/subtitle"/><xsl:value-of select="/setinfo/subtitle"/>
Group:          Documentation
License:        OPL + Restrictions
URL:            http://www.redhat.com/docs
Source0:         %{name}-%{version}-%{release}.tgz
BuildArch:      noarch
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires: yelp

%description
<xsl:value-of select="/bookinfo/abstract/para" /><xsl:value-of select="/setinfo/abstract/para" />

%package -n %{name}-<xsl:value-of select="$book-lang"/>
Summary:    <xsl:value-of select="/bookinfo/subtitle" /><xsl:value-of select="/setinfo/subtitle" />
Group:      Documentation
Requires: yelp

%description -n %{name}-<xsl:value-of select="$book-lang"/>
<xsl:value-of select="/bookinfo/abstract/para" />

%prep
%setup -q

%build

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/usr/share/applications/

cat > $RPM_BUILD_ROOT/usr/share/applications/%{name}.desktop &lt;&lt;'EOF'
[Desktop Entry]
Name=<xsl:value-of select="/bookinfo/subtitle"/><xsl:value-of select="/setinfo/subtitle"/>
<xsl:value-of select="$titles"/>
Comment=<xsl:value-of select="/bookinfo/title" /><xsl:value-of select="/setinfo/title" />
Exec=yelp ghelp:%{name}
#Exec=yelp %{_docdir}/%{name}-<xsl:value-of select="$book-lang"/>-%{version}/<xsl:value-of select="$main-file"/>
Icon=%{_docdir}/%{name}-<xsl:value-of select="$book-lang"/>-%{version}/images/icon.svg
Categories=Documentation;X-Red-Hat-Base;
Type=Application
Encoding=UTF-8
Terminal=false
EOF

mkdir -p $RPM_BUILD_ROOT/usr/share/gnome/help/%{name}
#mkdir -p $RPM_BUILD_ROOT/usr/share/omf/%{name}
#cp omf/*.omf $RPM_BUILD_ROOT/usr/share/omf/%{name}/.

%clean
rm -rf $RPM_BUILD_ROOT

%post -n %{name}-<xsl:value-of select="$book-lang"/>
%define _locale %(echo <xsl:value-of select="$book-lang"/> |sed 's/-/_/')
if [ -d /usr/share/gnome/help/%{name}/%{_locale} ]; then
	rm -rf /usr/share/gnome/help/%{name}/%{_locale}
fi
ln -sf %{_docdir}/%{name}-<xsl:value-of select="$book-lang"/>-%{version} /usr/share/gnome/help/%{name}/%{_locale};
if [ -d /usr/share/gnome/help/%{name}/C ]; then
	rm -rf /usr/share/gnome/help/%{name}/C
fi
ln -sf %{_docdir}/%{name}-<xsl:value-of select="$book-lang"/>-%{version} /usr/share/gnome/help/%{name}/C;
#scrollkeeper-update

%postun -n %{name}-<xsl:value-of select="$book-lang"/>
rm -rf /usr/share/gnome/help/%{name}
#scrollkeeper-update

%posttrans -n %{name}-<xsl:value-of select="$book-lang"/>
%define _locale %(echo <xsl:value-of select="$book-lang"/> |sed 's/-/_/')
if [ -d %{_docdir}/%{name}-<xsl:value-of select="$book-lang"/>-%{version} ]; then
	mkdir -p /usr/share/gnome/help/%{name}
	if [ -d /usr/share/gnome/help/%{name}/%{_locale} ]; then
		rm -rf /usr/share/gnome/help/%{name}/%{_locale}
	fi
	ln -sf %{_docdir}/%{name}-<xsl:value-of select="$book-lang"/>-%{version} /usr/share/gnome/help/%{name}/%{_locale};
	if [ -d /usr/share/gnome/help/%{name}/C ]; then
		rm -rf /usr/share/gnome/help/%{name}/C
	fi
	ln -sf %{_docdir}/%{name}-<xsl:value-of select="$book-lang"/>-%{version} /usr/share/gnome/help/%{name}/C;
fi

%files -n %{name}-<xsl:value-of select="$book-lang"/>
%defattr(-,root,root,-)
%doc <xsl:value-of select="$book-lang"/>/*
/usr/share/applications/%{name}.desktop
/usr/share/gnome/help/%{name}
#/usr/share/omf/%{name}/%{name}-C.omf

@@@SUBPACKAGES@@@

%changelog
<xsl:value-of select="$book-log"/>

</xsl:template>

</xsl:stylesheet>

