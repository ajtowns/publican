package Publican::CreateBook;

use strict;
use warnings;
use 5.008;
use Carp;
use Config::Simple '-strict';
use XML::TreeBuilder;
use File::Path;
use DateTime;
use Term::ANSIColor qw(:constants);
use Publican;
use Publican::Builder;

use vars qw( $VERSION );

$VERSION = '0.2';

# Icon used for menu
my $icon = q{<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg xmlns:svg="http://www.w3.org/2000/svg" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.0" width="32" height="32" id="svg3017">
  <defs id="defs3019">
    <linearGradient id="linearGradient2381">
      <stop id="stop2383" style="stop-color:#ffffff;stop-opacity:1" offset="0"/>
      <stop id="stop2385" style="stop-color:#ffffff;stop-opacity:0" offset="1"/>
    </linearGradient>
    <linearGradient x1="296.4996" y1="188.81061" x2="317.32471" y2="209.69398" id="linearGradient2371" xlink:href="#linearGradient2381" gradientUnits="userSpaceOnUse" gradientTransform="matrix(0.90776,0,0,0.90776,24.35648,49.24131)"/>
  </defs>
  <g transform="matrix(0.437808,-0.437808,0.437808,0.437808,-220.8237,43.55311)" id="g5089">
    <path d="m 8.4382985,-6.28125 c -0.6073916,0 -4.3132985,5.94886271 -4.3132985,8.25 l 0,26.71875 c 0,0.846384 0.5818159,1.125 1.15625,1.125 l 25.5625,0 c 0.632342,0 1.125001,-0.492658 1.125,-1.125 l 0,-5.21875 0.28125,0 c 0.49684,0 0.906249,-0.409411 0.90625,-0.90625 l 0,-27.9375 c 0,-0.4968398 -0.40941,-0.90625 -0.90625,-0.90625 l -23.8117015,0 z" transform="translate(282.8327,227.1903)" id="path5091" style="fill:#5c5c4f;stroke:#000000;stroke-width:3.23021388;stroke-miterlimit:4;stroke-dasharray:none"/>
    <rect width="27.85074" height="29.369793" rx="1.1414107" ry="1.1414107" x="286.96509" y="227.63805" id="rect5093" style="fill:#032c87"/>
    <path d="m 288.43262,225.43675 25.2418,0 0,29.3698 -26.37615,0.0241 1.13435,-29.39394 z" id="rect5095" style="fill:#ffffff"/>
    <path d="m 302.44536,251.73726 c 1.38691,7.85917 -0.69311,11.28365 -0.69311,11.28365 2.24384,-1.60762 3.96426,-3.47694 4.90522,-5.736 0.96708,2.19264 1.83294,4.42866 4.27443,5.98941 0,0 -1.59504,-7.2004 -1.71143,-11.53706 l -6.77511,0 z" id="path5097" style="fill:#a70000;fill-opacity:1;stroke-width:2"/>
    <rect width="25.241802" height="29.736675" rx="0.89682275" ry="0.89682275" x="290.73544" y="220.92249" id="rect5099" style="fill:#809cc9"/>
    <path d="m 576.47347,725.93939 6.37084,0.41502 0.4069,29.51809 c -1.89202,-1.31785 -6.85427,-3.7608 -8.26232,-1.68101 l 0,-26.76752 c 0,-0.82246 0.66212,-1.48458 1.48458,-1.48458 z" transform="matrix(0.499065,-0.866565,0,1,0,0)" id="rect5101" style="fill:#4573b3;fill-opacity:1"/>
    <path d="m 293.2599,221.89363 20.73918,0 c 0.45101,0 0.8141,0.3631 0.8141,0.81411 0.21547,6.32836 -19.36824,21.7635 -22.36739,17.59717 l 0,-17.59717 c 0,-0.45101 0.3631,-0.81411 0.81411,-0.81411 z" id="path5103" style="opacity:0.65536726;fill:url(#linearGradient2371);fill-opacity:1"/>
  </g>
</svg>
};

=head1 NAME

Publican::CreateBook - A module for generating documentation boilerplate

=head1 VERSION

This document describes Publican::CreateBook version $VERSION


=head1 SYNOPSIS

    use Publican::CreateBook;

    my $creator = Publican::CreateBook->new({name => 'foo'});
    $creator->create();
  
=head1 DESCRIPTION

    Creates a new Book, Article or Set for use with the publican package

=head1 INTERFACE 

=cut

=head2  new

Create a Publican object set.

=head3 Parameters:

   docname           Book Name        (Required)
   version           Product Version  (default: 0.1)
   edition           Edition          (default: 0)
   product           Product Name     (default: Documentation)
   brand             Brand            (default: common)
   xml_lang          Source Language  (default: en-US)
   type              Book|Set|Article (default: Book)

=cut

sub new {
    my ( $this, $args ) = @_;
    my $class = ref($this) || $this;

    my $config = new Config::Simple();
    $config->syntax('http');

    $config->param( 'docname',
        delete( $args->{name} )
            || croak( maketext("name is a required parameter") ) );
    $config->param( 'version', delete( $args->{version} ) || '0.1' );
    $config->param( 'edition', delete( $args->{edition} ) || '0' );
    $config->param( 'product',
        delete( $args->{product} ) || 'Documentation' );
    $config->param( 'brand',    delete( $args->{brand} ) || 'common' );
    $config->param( 'xml_lang', delete( $args->{lang} )  || 'en-US' );
    $config->param( 'type',     delete( $args->{type} )  || 'Book' );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    if ( $config->param('type') !~ m/^(Book|Set|Article)$/i ) {
        croak( maketext("type must be book, set, or article") );
    }

    my $self = bless {}, $class;

    $config->param( 'type', ucfirst( $config->param('type') ) );

    $self->{config} = $config;

    return $self;
}

=head2 create

Try embedding templates in perl to avoid licensing rubbish

=cut

sub create {
    my ($self) = @_;

    my $name    = $self->{config}->param('docname');
    my $version = $self->{config}->param('version');
    my $edition = $self->{config}->param('edition');
    my $product = $self->{config}->param('product');
    my $brand   = $self->{config}->param('brand');
    my $lang    = $self->{config}->param('xml_lang');
    my $type    = $self->{config}->param('type');

    my $lctype = lc($type);

    my $bookname = $self->{config}->param('docname');
    $bookname =~ s/_/ /g;

    croak( maketext( "directory [_1] exists!", $name ) ) if ( -e $name );

    mkpath("$name/$lang/images");

    my %files = (
        'Author_Group' => {
            types => 'Book Set Article',
            node  => XML::Element->new_from_lol(
                [   'authorgroup',
                    [   'author',
                        [   'firstname',
                            maketext('Enter your first name here.')
                        ],
                        [ 'surname', maketext('Enter your surname here.') ],
                        [   'affiliation',
                            [   'orgname',
                                maketext(
                                    q|Enter your organisation's name here.|)
                            ],
                            [   'orgdiv',
                                maketext(
                                    'Enter your organisational division here.'
                                )
                            ],
                        ],
                        [   'email',
                            maketext('Enter your email address here.')
                        ],
                    ],
                ],
            ),
        },
        'Book' => {
            types => 'Book',
            node  => XML::Element->new_from_lol(
                [   'book',
                    [   'xi:include',
                        {   href       => 'Book_Info.xml',
                            'xmlns:xi' => 'http://www.w3.org/2001/XInclude'
                        }
                    ],
                    [   'xi:include',
                        {   href       => 'Preface.xml',
                            'xmlns:xi' => 'http://www.w3.org/2001/XInclude'
                        }
                    ],
                    [   'xi:include',
                        {   href       => 'Chapter.xml',
                            'xmlns:xi' => 'http://www.w3.org/2001/XInclude'
                        }
                    ],
                    [   'xi:include',
                        {   href       => 'Revision_History.xml',
                            'xmlns:xi' => 'http://www.w3.org/2001/XInclude'
                        }
                    ],
                    ['index'],
                ],
            ),
        },
        'Article' => {
            types => 'Article',
            node  => XML::Element->new_from_lol(
                [   'article',
                    [   'xi:include',
                        {   href       => 'Article_Info.xml',
                            'xmlns:xi' => 'http://www.w3.org/2001/XInclude'
                        }
                    ],
                    [ 'para', maketext('This is a test paragraph') ],
                    [   'xi:include',
                        {   href       => 'Revision_History.xml',
                            'xmlns:xi' => 'http://www.w3.org/2001/XInclude'
                        }
                    ],
                    ['index'],
                ],
            ),
        },
        'Set' => {
            types => 'Set',
            node  => XML::Element->new_from_lol(
                [   'set',
                    [   'xi:include',
                        {   href       => 'Set_Info.xml',
                            'xmlns:xi' => 'http://www.w3.org/2001/XInclude'
                        }
                    ],
                    [   'remark',
                        maketext(
                            'NOTE: the href does not contain a language! This is CORRECT!'
                        )
                    ],
                    [   'remark',
                        '<xi:include href="My_Other_Book/My_Other_Book.xml" xmlns:xi="http://www.w3.org/2001/XInclude">'
                    ],
                    ['setindex'],
                ],
            ),
        },
        "$type"
            . "_Info" => {
            types => 'Book Set Article',
            node  => XML::Element->new_from_lol(
                [   $lctype . 'info',
                    [ 'title', $bookname ],
                    [   'subtitle',
                        maketext('Enter a short description here.')
                    ],
                    [ 'productname',   $product ],
                    [ 'productnumber', $version ],
                    [ 'edition',       $edition ],
                    [ 'pubsnumber',    '0' ],
                    [   'abstract',
                        [   'para',
                            maketext(
                                q|A short overview and summary of the book's subject and purpose, traditionally no more than one paragraph long. Note: the abstract will appear in the front matter of your book and will also be placed in the description field of the book's RPM spec file.|
                            )
                        ],
                    ],
                    [   'corpauthor',
                        [   'inlinemediaobject',
                            [   'imageobject',
                                [   'imagedata',
                                    {   format => 'SVG',
                                        fileref =>
                                            'Common_Content/images/title_logo.svg'
                                    }
                                ],
                            ],
                        ],
                    ],
                    [   'xi:include',
                        {   href       => 'Common_Content/Legal_Notice.xml',
                            'xmlns:xi' => 'http://www.w3.org/2001/XInclude'
                        }
                    ],
                    [   'xi:include',
                        {   href       => 'Author_Group.xml',
                            'xmlns:xi' => 'http://www.w3.org/2001/XInclude'
                        }
                    ],
                ],
            ),
            },
        'Revision_History' => {
            types => 'Book Set Article',
            node  => XML::Element->new_from_lol(
                [   'appendix',
                    [ 'title', maketext('Revision History') ],
                    [   'simpara',
                        [   'revhistory',
                            [   'revision',
                                [ 'revnumber', '0.0-0' ],
                                [   'date',
                                    DateTime->today()->strftime("%a %b %e %Y")
                                ],
                                [   'author',
                                    [   'firstname',
                                        maketext(
                                            'Enter your first name here.')
                                    ],
                                    [   'surname',
                                        maketext('Enter your surname here.')
                                    ],
                                    [   'email',
                                        maketext(
                                            'Enter your email address here.')
                                    ],
                                ],
                                [   'revdescription',
                                    [   'simplelist',
                                        [   'member',
                                            maketext(
                                                'Initial creation by publican'
                                            )
                                        ],
                                    ],
                                ],
                            ],
                        ],
                    ],
                ],
            ),
        },
        'Chapter' => {
            types => 'Book',
            node  => XML::Element->new_from_lol(
                [   'chapter',
                    [ 'title', maketext('Test Chapter') ],
                    [ 'para',  maketext('This is a test paragraph') ],
                    [   'section',
                        [ 'title', maketext('Test Section 1') ],
                        [   'para',
                            maketext('This is a test paragraph in a section')
                        ],
                    ],
                    [   'section',
                        [ 'title', maketext('Test Section 2') ],
                        [   'para',
                            maketext('This is a test paragraph in Section 2'),
                            [   'orderedlist',
                                [   'listitem',
                                    [   'para',
                                        maketext('This is a test listitem.')
                                    ],
                                ],
                            ],
                        ],
                    ],
                ],
            ),
        },
        'Preface' => {
            types => 'Book Set',
            node  => XML::Element->new_from_lol(
                [   'preface',
                    [ 'title', maketext('Preface') ],
                    [   'xi:include',
                        {   href       => 'Common_Content/Conventions.xml',
                            'xmlns:xi' => 'http://www.w3.org/2001/XInclude'
                        }
                    ],
                    [   'xi:include',
                        {   href       => 'Feedback.xml',
                            'xmlns:xi' => 'http://www.w3.org/2001/XInclude'
                        },
                        [   'xi:fallback',
                            {   'xmlns:xi' =>
                                    'http://www.w3.org/2001/XInclude'
                            },
                            [   'xi:include',
                                {   href => 'Common_Content/Feedback.xml',
                                    'xmlns:xi' =>
                                        'http://www.w3.org/2001/XInclude'
                                },
                            ],
                        ],
                    ],
                ],
            ),
        },

    );

    debug_msg("TODO: consolidate XML methods with Builder\n");

    # formatting
    foreach my $file ( keys(%files) ) {
        if ( $files{$file}->{types} !~ /$type/ ) {
            next;
        }
        my $xml_doc = $files{$file}->{node};
        $xml_doc->pos( $xml_doc->root() );
        my $node_type = $xml_doc->{'_tag'};
        my $text      = $xml_doc->as_XML($xml_doc);
        my $out_file  = "$name/$lang/$file" . ".xml";
        if ( $file =~ m/^(Book|Set|Article)$/ ) {
            $out_file = "$name/$lang/$name" . ".xml";
        }
        my $OUTDOC;
        open( $OUTDOC, ">:encoding(UTF-8)", $out_file )
            || croak(
            maketext( "Could not open [_1] for output!", $out_file, $@ ) );

        print( $OUTDOC Publican::Builder::dtd_string(
                { tag => $node_type, dtdver => '4.5', cleaning => 1 }
            )
        );

        print( $OUTDOC $text );
        close($OUTDOC);

        $xml_doc->root()->delete();
    }

    # remove these from the default configuration file
    # so that by default only the XML requires changing.
    $self->{config}->delete('docname');
    $self->{config}->delete('version');
    $self->{config}->delete('edition');
    $self->{config}->delete('product');

    $self->{config}->write("$name/publican.cfg");

    my $year = DateTime->today()->year();

    my $OUTDOC;
    open( $OUTDOC, ">:encoding(UTF-8)", "$name/$lang/$name" . ".ent" )
        || croak( maketext( "Could not open entity file. [_1]", $@ ) );
    my $holder_text
        = maketext(
        'You need to change the HOLDER entity in the [_1]/[_2].ent file',
        $lang, $name );
    print $OUTDOC <<EOL;
<!ENTITY PRODUCT "$product">
<!ENTITY BOOKID "$name">
<!ENTITY YEAR "$year">
<!ENTITY HOLDER "| $holder_text |">
EOL

    close($OUTDOC);

    open( $OUTDOC, ">:encoding(UTF-8)", "$name/$lang/images/icon.svg" )
        || croak( maketext( "Could not open icon file. [_1]", $@ ) );
    print( $OUTDOC $icon );
    close($OUTDOC);

    return;
}

1;    # Magic true value required at end of module

=head1 DIAGNOSTICS

=over

=item C<< unknown args %s >>

All subs with named parameters will return this error when unexpected named arguments are provided.

=item C<< %s is a required argument >>

Any sub with a mandatory parameter will return this error if the parameter is undef.

=item C<< directory %s exists >>

When creating a book a directory is created named publican-<book_name>. If a directory with that name is in the current directory the creation will fail.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Publican::CreateBook requires no configuration files or environment variables.


=head1 DEPENDENCIES

Carp
Config::Simple
XML::TreeBuilder
File::Path
DateTime
Term::ANSIColor
Publican

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<publican-list@redhat.com>, or through the web interface at
L<https://bugzilla.redhat.com/bugzilla/enter_bug.cgi?product=Publican&component=publican>.

=head1 AUTHOR

Jeff Fearn  C<< <jfearn@redhat.com> >>
