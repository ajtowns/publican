package Publican::CreateBrand;

use strict;
use warnings;
use Carp;
use Config::Simple;
use File::Path;
use File::pushd;
use DateTime;
use Image::Magick;
use Publican;
use Publican::Builder;
use Term::ANSIColor qw(:constants uncolor);

use vars qw( $VERSION $MAX_COUNT );

$VERSION   = '0.2';
$MAX_COUNT = 29;

my $INIT_VERSION  = '0.1';

## NOTE Change this for betas
my $PUBLICAN_NAME = 'publican';

=head1 NAME

Publican::CreateBrand - A module for generating new brand boilerplate.

=head1 VERSION

This document describes Publican::CreateBrand version 0.1 


=head1 SYNOPSIS

    use Publican::CreateBrand;

    my $creator = Publican::CreateBrand->new({name => 'foo'});
    $creator->create();
  
=head1 DESCRIPTION

    Creates a new Brand for use with the publican package

=head1 INTERFACE 

=cut

=head2 new

Create a Publican object set.

=head3 Parameters:

   name              Brand Name        (Required)

=cut

sub new {
    my ( $this, $args ) = @_;
    my $class = ref($this) || $this;

    my $config = new Config::Simple();
    $config->syntax('http');

    $config->param( 'brand',
        delete( $args->{name} )
            || croak( maketext("name is a required parameter") ) );
    $config->param( 'xml_lang',
        delete( $args->{lang} )
            || croak( maketext("lang is a required parameter") ) );

    if ( %{$args} ) {
        croak(
            maketext( "unknown arguments: [_1]", join( ", ", keys %{$args} ) ) );
    }


    $config->param( 'type',    'brand' );
    $config->param( 'version', $INIT_VERSION );
    $config->param( 'release', '0' );

    my $self = bless {}, $class;

    $self->{config} = $config;

    return $self;
}

=head2 create

Create all the required files.

=cut

sub create {
    my ($self) = @_;

    my ( $OUT, $out_file );

    my $name = $self->{config}->param('brand');
    my $lang = $self->{config}->param('xml_lang');

    croak( maketext( "Invalid language supplied: [_1]", $lang ) . "\n" )
        unless ( Publican::valid_lang($lang) );

    croak(
        maketext( "Can't create brand, dirctory 'publican-[_1]' exists!", $name )
    ) if ( -d "publican-$name" );

    mkpath("publican-$name")
        || croak( maketext( "Can't create directory: [_1]", $@ ) );
    my $dir = pushd("publican-$name");
    mkpath("$lang/images")
        || croak( maketext( "Can't create directory: [_1]", $@ ) );

    $self->conf_files();
    $self->xml_files();
    $self->images();

    mkpath("$lang/css");

    $out_file = "$lang/css/overrides.css";

    open( $OUT, ">:utf8", $out_file )
        || croak(
        maketext( "Could not open [_1] for output: [_2]", $out_file, $@ ) );

    print $OUT <<CSS;
a:link {
	color:#0066cc;
}

a:visited {
	color:#6699cc;
}

h1 {
	color:#a70000;
}

.producttitle {
	background: #800 url(../images/h1-bg.png) top left repeat;
}

.section h1.title {
	color:#a70000;
}


h2,h3,h4,h5,h6 {
	color:#a70000;
}

table {
	border:1px solid #aaa;
}

table th {
	background-color:#900;
}

table tr.even td {
	background-color:#f5f5f5;
}

#title a {
	height:54px;
}

.term{
	color:#a70000;
}

.revhistory table th {
	color:#a70000;
}

.edition {
	color: #a70000;
}

span.remark{
	background-color: #ffff00;
}

CSS

    close($OUT);

    return;
}

=head2 xml_files

Create XML files.

=cut

sub xml_files {
    my ($self) = @_;

    my $lang = $self->{config}->param('xml_lang');

    my %files = (
        'Feedback' => {
            'type' => 'section',
            'node' => XML::Element->new_from_lol(
                [   'section',
                    [ 'title', 'We Need Feedback!' ],
                    [   'indexterm',
                        [ 'primary',   'feedback1' ],
                        [ 'secondary', 'contact information for this brand' ],
                    ],
                    [   'para',
                        'SETUP: You should change this text to reflect the default contact information for this brand. e.g. mail list, ticketing system etc.'
                    ],
                ],
            ),
        },
        'Legal_Notice' => {
            'type' => 'legalnotice',
            'node' => XML::Element->new_from_lol(
                [   'legalnotice',
                    [   'para',
                        'Copyright <trademark class="copyright"></trademark> &YEAR; &HOLDER;'
                    ],
                    [   'para',
                        'SETUP: Enter the blurb for your license here. Often a short description of the license with a URL linking to the full text.'
                    ],
                ],
            ),
        },
    );

    foreach my $file ( keys(%files) ) {
        my $xml_doc = $files{$file}->{node};
        my $type    = $files{$file}->{type};
        $xml_doc->pos( $xml_doc->root() );
        my $text     = $xml_doc->as_XML($xml_doc);
        my $out_file = "$lang/$file" . ".xml";
        my $OUTDOC;
        open( $OUTDOC, ">:utf8", $out_file )
            || croak(
            maketext( "Could not open file [_1] for output!", $out_file ) );

        print( $OUTDOC Publican::Builder::dtd_string(
                { tag => $type, dtdver => '4.5' }
            )
        );
        print( $OUTDOC $text );
        close($OUTDOC);

        $xml_doc->root()->delete();
    }

    return;
}

=head2 conf_files

Create configuration files.

=cut

sub conf_files {
    my ($self) = @_;

    my ( $OUT, $out_file );

    my $brand   = $self->{config}->param('brand');
    my $lcbrand = lc($brand);

    my $cfg_file = 'publican.cfg';

    # publican.cfg
    $self->{config}->write($cfg_file)
        || croak(
        maketext(
            "Can't write to [_1]: [_2]",
            $cfg_file, Config::Simple->error()
        )
        );

    debug_msg("TODO: conf_files: COPYING - URL for where to wget it\n");
    debug_msg("TODO: conf_files: TODO README\n");

    my $config = new Config::Simple();
    $config->syntax('http');
    $config->param( 'prod_url', 'http://www.SETUP.example.com' );
    $config->param( 'doc_url',  'http://www.SETUP.example.com/docs' );
    $config->write('defaults.cfg')
        || croak(
        maketext( "Can't write to defaults.cfg: [_1]", Config::Simple->error() )
        );
    $config->close();

    $config = new Config::Simple();
    $config->syntax('http');
    $config->param( 'strict', 0 );
    $config->write('overrides.cfg')
        || croak(
        maketext( "Can't write to overrides.cfg: [_1]", Config::Simple->error() )
        );
    $config->close();

    # spec file
    my $date = DateTime->today()->strftime("%a %b %e %Y");
    $out_file = "publican-$lcbrand.spec";

    open( $OUT, ">:utf8", $out_file )
        || croak( maketext( "Could not open file [_1] for output!", $out_file ) );

    print $OUT <<SPEC;
%define brand $brand

Name:		publican-$lcbrand
Summary:	Common documentation files for %{brand}
Version:	$INIT_VERSION
Release:	0%{?dist}
License:	SETUP: Set This
Group:		Applications/Text
Buildroot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Buildarch:	noarch
Source:		https://www.SETUP.set.me.example.com/source/%{name}-%{version}.tgz
Requires:	$PUBLICAN_NAME >= 1.99
BuildRequires:	$PUBLICAN_NAME >= 1.99
URL:		https://www.SETUP.set.me.example.com

%description
This package provides common files and templates needed to build documentation
for %{brand} with publican.

%prep
%setup -q 

%build
publican build --formats=xml --langs=all --publish

%install
rm -rf \$RPM_BUILD_ROOT
mkdir -p -m755 \$RPM_BUILD_ROOT%{_datadir}/$PUBLICAN_NAME/Common_Content
publican install_brand --path=\$RPM_BUILD_ROOT%{_datadir}/$PUBLICAN_NAME/Common_Content

%clean
rm -rf \$RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc README
%doc COPYING
%{_datadir}/$PUBLICAN_NAME/Common_Content/%{brand}

%changelog
* $date  SETUP:YourName <SETUP:your.email\@example.com> 0.1
- Created Brand

SPEC

    close($OUT);

    open( $OUT, ">:utf8", 'README' )
        || croak( maketext( "Could not open file README for output!" ) );

    print($OUT "SETUP This file should be a short description of your project");
    close($OUT);

    open( $OUT, ">:utf8", 'COPYING' )
        || croak( maketext( "Could not open file COPYING for output!" ) );

    print($OUT "SETUP This file should contain your COPYRIGHT License");
    close($OUT);

    return;
}

=head2 images

Create images dir and all the default images in svg and png format.

=cut

sub images {
    my ($self) = @_;

    my ( $OUT, $out_file );
    my $lang = $self->{config}->param('xml_lang');

    # create call out numbers
    for ( my $count = 1; $count <= $MAX_COUNT; $count++ ) {
        my $svg = <<SVG;
<?xml version="1.0" encoding="UTF-8" standalone="no"?>

<svg
   xmlns:svg="http://www.w3.org/2000/svg"
   xmlns="http://www.w3.org/2000/svg"
   version="1.0"
   width="32"
   height="32"
   id="svg$count">
  <defs
     id="defs$count" />
  <circle
     cx="16"
     cy="16"
     r="14"
     id="circle"
     style="fill:#aa0000" />
  <text
     x="16"
     y="16"
     transform="scale(0.89833804,1.1131667)"
     id="text$count"
     xml:space="preserve"
     style="font-size:20px;font-style:normal;font-variant:normal;font-weight:bold;font-stretch:normal;text-align:center;line-height:125%;writing-mode:lr-tb;text-anchor:middle;fill:#ffffff;fill-opacity:1;stroke:none;font-family:Liberation Serif;"><tspan
       x="18"
       y="20"
       id="tspan$count">$count</tspan></text>
</svg>
SVG

        open( $OUT, ">:utf8", "$lang/images/$count.svg" )
            || croak(
            maketext(
                "Can't open SVG file [_1]: [_2]", "$lang/images/$count.svg",
                $@
            )
            );
        print( $OUT $svg );
        close($OUT);
        my $image = Image::Magick->new;
        $image->ReadImage("$lang/images/$count.svg");
        $image->Write("$lang/images/$count.png");
    }

    my %images = (

        # Nav images
        'stock-go-back'    => { x => 22, y => 22 },
        'stock-go-forward' => { x => 22, y => 22 },
        'stock-go-up'      => { x => 22, y => 22 },
        'stock-home'       => { x => 22, y => 22 },

        # Logo images
        'image_left'  => { x => 88,  y => 45 },
        'image_right' => { x => 199, y => 41 },
        'title_logo'  => { x => 112, y => 100 },
        'h1-bg'       => { x => 5,   y => 100 },

        # Admonition images
        'important' => { x => 48, y => 48 },
        'note'      => { x => 48, y => 48 },
        'warning'   => { x => 48, y => 48 },

        # List style images
        'dot2' => { x => 5, y => 6 },
        'dot'  => { x => 5, y => 6 },

        # Watermark
        'watermark-draft' => { x => 500, y => 500 },
    );

    foreach my $image ( keys(%images) ) {
        $self->default_images(
            {   file => $image,
                x    => $images{$image}->{x},
                y    => $images{$image}->{y}
            }
        );
    }

    return;
}

=head2 default_images

Generate images with default text in SVG and PNG formats.

=cut

sub default_images {
    my ( $self, $args ) = @_;

    my $file = delete( $args->{file} )
        || croak( maketext("file is a mandatory argument") );
    my $x = delete( $args->{x} )
        || croak( maketext("x is a mandatory argument") );
    my $y = delete( $args->{y} )
        || croak( maketext("y is a mandatory argument") );

    if ( %{$args} ) {
        croak(
            maketext( "unknown arguments: [_1]", join( ", ", keys %{$args} ) ) );
    }

    my ($OUT);
    my $lang = $self->{config}->param('xml_lang');

    my $x1 = $x / 2;
    my $x2 = $x1 + 2;
    my $y1 = $y / 2;
    my $y2 = $y1 + 2;

    my $svg = <<SVG;
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg
   xmlns:svg="http://www.w3.org/2000/svg"
   xmlns="http://www.w3.org/2000/svg"
   version="1.0"
   width="$x"
   height="$y"
   id="svg$file">
  <defs
     id="defs$file" />
  <text
     x="$x1"
     y="$y1"
     transform="scale(0.89833804,1.1131667)"
     id="text$file"
     xml:space="preserve"
     style="font-size:20px;font-style:normal;font-variant:normal;font-weight:bold;font-stretch:normal;text-align:center;line-height:125%;writing-mode:lr-tb;text-anchor:middle;fill:#ffffff;fill-opacity:1;stroke:none;font-family:Liberation Serif;"><tspan
       x="$x2"
       y="$y2"
       id="tspan$file">$file</tspan></text>
</svg>
SVG

    open( $OUT, ">:utf8", "$lang/images/$file.svg" )
        || croak(
        maketext(
            "Can't open SVG file [_1]: [_2]", "$lang/images/$file.svg", $@
        )
        );
    print( $OUT $svg );
    close($OUT);
    my $image = Image::Magick->new;
    $image->ReadImage("$lang/images/$file.svg");
    $image->Write("$lang/images/$file.png");

    return;
}

1;    # Magic true value required at end of module

=head1 DIAGNOSTICS

=over

=item C<< unknown args %s >>

All subs with named parameters will return this error when unexpected named arguments are provided.

=item C<< %s is a required parameter >>

Any sub with a mandatory parameter will return this error if the parameter is undef.

=item C<< "Can't create brand, dirctory %s exists! >>

When creating a Brand a directory is created with the same name as the
brand. If a directory with that name is in the current directory the
creation will fail.

=item C<< Invalid language supplied: %s >>

The language supplied is not a valid language.

=item C<< Can't create directory: %s >>

=item C<< Could not open %s for output! >>

=item C<< Can't write file >>

=item C<< Can't open SVG file %s >>

=back

=head1 CONFIGURATION AND ENVIRONMENT

Publican::CreateBrand requires no configuration files or environment variables.

=head1 DEPENDENCIES

Carp
version
Config::Simple
File::Path
File::pushd
DateTime
Image::Magick
Publican
Term::ANSIColor

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

None reported.

Please report any bugs or feature requests to
C<publican-list@redhat.com>, or through the web interface at
L<https://bugzilla.redhat.com/bugzilla/enter_bug.cgi?product=Fedora&amp;version=rawhide&amp;component=publican>.

=head1 AUTHOR

Jeff Fearn  C<< <jfearn@redhat.com> >>

