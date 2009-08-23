package Publican::CreateBook;

use strict;
use warnings;
use Carp;
use version;
use Config::Simple;

use XML::TreeBuilder;
use File::Path;
use DateTime;
use Term::ANSIColor qw(:constants);
use Publican;
use Publican::Builder;

use vars qw( $VERSION );

$VERSION = version->new('0.1');

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
    $config->param( 'version',  delete( $args->{version} ) || '0.1' );
    $config->param( 'edition',  delete( $args->{edition} ) || '0' );
    $config->param( 'product',  delete( $args->{product} ) || 'Documentation' );
    $config->param( 'brand',    delete( $args->{brand} )   || 'common' );
    $config->param( 'xml_lang', delete( $args->{lang} )    || 'en-US' );
    $config->param( 'type',     delete( $args->{type} )    || 'Book' );

    if ( %{$args} ) {
        croak(
            maketext( "unknown arguments: [_1]", join( ", ", keys %{$args} ) ) );
    }

    if ( $config->param('type') !~ m/^(Book|Set|Article)$/i ) {
        croak( maketext("type must be Book|Set|Article") );
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

    my $h = XML::Element->new_from_lol(
        [   'html',
            [ 'head', [ 'title', 'I like stuff!' ], ],
            [   'body',
                { 'lang', 'en-JP', _implicit => 1 },
                'stuff',
                [ 'p', 'um, p < 4!', { 'class' => 'par123' } ],
                [ 'div', { foo => 'bar' }, '123' ],
            ]
        ]
    );

    my %files = (
        'Author_Group' => {
            types => 'Book Set Article',
            node  => XML::Element->new_from_lol(
                [   'authorgroup',
                    [   'author',
                        [ 'firstname', 'Dude' ],
                        [ 'surname',   'McPants' ],
                        [   'affiliation',
                            [ 'orgname', 'Somewhere' ],
                            [ 'orgdiv',  'Someone' ],
                        ],
                        [ 'email', 'Dude.McPants@example.com' ],
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
                    [ 'para', 'This is a test paragraph' ],
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
                        'NOTE: the href does not contain a language! This is CORRECT!'
                    ],
                    [   'remark',
                        '<xi:include href="My_Other_Book/My_Other_Book.xml" xmlns:xi="http://www.w3.org/2001/XInclude">'
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
        "$type"
            . "_Info" => {
            types => 'Book Set Article',
            node  => XML::Element->new_from_lol(
                [   $lctype . 'info',
                    [ 'title',         $name ],
                    [ 'subtitle',      'short description' ],
                    [ 'productname',   $product ],
                    [ 'productnumber', $version ],
                    [ 'edition',       $edition ],
                    [ 'pubsnumber',    '0' ],
                    [   'abstract',
                        [   'para',
                            q|A short overview and summary of the book's subject and purpose, traditionally no more than one paragraph long. Note: the abstract will appear in the front matter of your book and will also be placed in the description field of the book's RPM spec file.|
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
                    [ 'title', 'Revision History' ],
                    [   'simpara',
                        [   'revhistory',
                            [   'revision',
                                [ 'revnumber', '0' ],
                                [   'date',
                                    DateTime->today()->strftime("%a %b %e %Y")
                                ],
                                [   'author',
                                    [ 'firstname', 'Dude' ],
                                    [ 'surname',   'McPants' ],
                                    [ 'email',     'Dude.McPants@example.com' ],
                                ],
                                [   'revdescription',
                                    [   'simplelist',
                                        [   'member',
                                            'Initial creation of book by publican'
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
                    [ 'title', 'Test Chapter' ],
                    [ 'para',  'This is a test paragraph' ],
                    [   'section',
                        [ 'title', 'Test Section 1' ],
                        [ 'para',  'This is a test paragraph in a section' ],
                    ],
                    [   'section',
                        [ 'title', 'Test Section 2' ],
                        [   'para',
                            'This is a test paragraph in Section 2',
                            [   'orderedlist',
                                [ 'listitem', [ 'para', 'listitem text' ], ],
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
                    [ 'title', 'Preface' ],
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
                            { 'xmlns:xi' => 'http://www.w3.org/2001/XInclude' },
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
        my $text     = $xml_doc->as_XML($xml_doc);
        my $out_file = "$name/$lang/$file" . ".xml";
        if ( $file =~ m/^(Book|Set|Article)$/ ) {
            $out_file = "$name/$lang/$name" . ".xml";
        }
        my $OUTDOC;
        open( $OUTDOC, ">:utf8", $out_file )
            || croak(
            maketext( "Could not open [_1] for output!", $out_file, $@ ) );

        print( $OUTDOC Publican::Builder::dtd_string(
                { tag => $type, dtdver => '4.5' }
            )
        );

        print( $OUTDOC $text );
        close($OUTDOC);

        $xml_doc->root()->delete();
    }

    #    $name.ent

    $self->{config}->write("$name/publican.cfg");

    my $year = DateTime->today()->year();

    my $OUTDOC;
    open( $OUTDOC, ">:utf8", "$name/$lang/$name" . ".ent" );
    print $OUTDOC <<EOL;
<!ENTITY PRODUCT "$product">
<!ENTITY BOOKID "$name">
<!ENTITY YEAR "$year">
<!ENTITY HOLDER "| You need to change the HOLDER entity in the $lang/$name.ent file |">
EOL

    close($OUTDOC);

    return;
}

1;    # Magic true value required at end of module

=head1 DIAGNOSTICS

=over

=item C<< unknown args %s >>

All subs with named parameters will return this error when unexpected anmed arguments are provided.

=item C<< %s is a required argument >>

Any sub with a mandadtory parameter will return this error if the parameter is undef.

=item C<< directory %s exists >>

When creating a book a directory is created named publilcan-<book_name>. If a directory with that name is in the current directory the creation will fail.

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
L<https://bugzilla.redhat.com/bugzilla/enter_bug.cgi?product=Fedora&amp;version=rawhide&amp;component=publican>.


=head1 AUTHOR

Jeff Fearn  C<< <jfearn@redhat.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Jeff Fearn C<< <jfearn@redhat.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

