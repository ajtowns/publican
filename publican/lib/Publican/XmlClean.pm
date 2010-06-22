package Publican::XmlClean;

use strict;
use warnings;
use Carp;
use XML::TreeBuilder;
use Config::Simple;
use Publican;
use File::Path;
use Image::Magick;
use Image::Size;
use Term::ANSIColor qw(:constants);
use Publican::Builder;

## Testing collation
my $test_collate = undef;
if ($test_collate) {
    use Unicode::Collate;
}

use vars qw( $VERSION );

$VERSION = '0.2';

=head1 NAME

Publican::XmlClean - A module to reformat XML to Publican standards

=head1 VERSION

This document describes Publican::XmlClean version $VERSION

=head1 SYNOPSIS

    use Publican::XmlClean;

    my $cleaner = Publican::XmlClean->new( { clean_id => 1 } );

    foreach my $xml_file ( sort(@xml_files) ) {
        $cleaner->process_file( { file => $xml_file, out_file => $xml_file } );
    }

  
=head1 DESCRIPTION

Publican::XmlClean tidies XML formatting and filters structure based on input rules.

=head1 INTERFACE 

=cut

my %UPDATED_IDS;

my %MAP_OUT = (
    'section'    => { 'block' => 1, 'newline_after' => 1 },
    'refsection' => { 'block' => 1, 'newline_after' => 1, no_id => 1 },
    'chapter'       => { 'block'         => 1 },
    'preface'       => { 'block'         => 1 },
    'bibliography'  => { 'block'         => 1 },
    'bibliodiv'     => { 'block'         => 1 },
    'biblioentry'   => { 'block'         => 1 },
    'othercredit'   => { 'block'         => 1 },
    'legalnotice'   => { 'block'         => 1 },
    'address'       => { 'block'         => 1 },
    'book'          => { 'block'         => 1 },
    'article'       => { 'block'         => 1 },
    'part'          => { 'block'         => 1 },
    'partintro'     => { 'block'         => 1 },
    'para'          => { 'block'         => 1 },
    'formalpara'    => { 'block'         => 1 },
    'simpara'       => { 'block'         => 1 },
    'itemizedlist'  => { 'block'         => 1 },
    'orderedlist'   => { 'block'         => 1 },
    'variablelist'  => { 'block'         => 1 },
    'seglistitem'   => { 'block'         => 1 },
    'segtitle'      => { 'newline_after' => 1 },
    'seg'           => { 'newline_after' => 1 },
    'segmentedlist' => { 'block'         => 1 },
    'simplelist'    => { 'block'         => 1 },
    'qandaset'      => { 'block'         => 1 },
    'qandaentry'    => { 'block'         => 1 },
    'question'      => { 'block'         => 1 },
    'answer'        => { 'block'         => 1 },
    'member'        => { 'newline_after' => 1 },
    'remark'        => { 'newline_after' => 1 },
    'userinput'     => {},
    'listitem'      => { 'block'         => 1, 'keep_id' => 1 },
    'title'         => { 'newline_after' => 1 },
    'refentrytitle' => { 'newline_after' => 1 },
    'refpurpose'    => { 'newline_after' => 1 },
    'refname'       => { 'newline_after' => 1 },
    'refnamediv'    => { 'block'         => 1, 'id_node' => 'refname' },
    'manvolnum'     => { 'newline_after' => 1 },
    'street'        => { 'newline_after' => 1 },
    'city'          => {},
    'state'         => {},
    'postcode'      => {},
    'coutry'        => {},
    'phone'    => { 'newline_after' => 1 },
    'fax'      => { 'newline_after' => 1 },
    'pob'      => {},
    'subtitle' => { 'newline_after' => 1 },
    'screen'           => { 'block'       => 1, 'verbatim'      => 1 },
    'programlisting'   => { 'block'       => 1, 'verbatim'      => 1 },
    'programlistingco' => { 'block'       => 1, 'newline_after' => 1 },
    'xref'             => { 'force_empty' => 1 },
    'footnoteref'      => { 'force_empty' => 1 },
    'important'        => { 'block'       => 1, 'no_id'         => 1 },
    'note'             => { 'block'       => 1, 'no_id'         => 1 },
    'warning'          => { 'block'       => 1, 'no_id'         => 1 },
    'figure'           => { 'block'       => 1 },
    'mediaobject'      => { 'block'       => 1 },
    'imageobject'      => { 'block'       => 1 },
    'imagedata'        => {},
    'xi:include'  => { 'newline_after' => 1 },
    'xi:fallback' => { 'newline_after' => 1 },

#    'glossary'          => { 'block'         => 1 },
#    'glossentry'        => { 'block'         => 1, 'id_node' => 'glossterm' },
#    'glossdiv'          => { 'block'         => 1 },
#    'glossdef'          => { 'block'         => 1 },
#    'glossterm'         => { 'newline_after' => 1 },
#    'glosssee'          => { 'newline_after' => 1 },
#    'glossseealso'      => { 'newline_after' => 1 },
    'table'             => { 'block'         => 1 },
    'informaltable'     => { 'block'         => 1 },
    'thead'             => { 'block'         => 1 },
    'tgroup'            => { 'block'         => 1 },
    'tbody'             => { 'block'         => 1 },
    'tr'                => { 'block'         => 1 },
    'td'                => { 'block'         => 1 },
    'row'               => { 'block'         => 1 },
    'entry'             => { 'block'         => 1 },
    'refentry'          => { 'block'         => 1 },
    'refmeta'           => { 'block'         => 1 },
    'refentryinfo'      => { 'block'         => 1, no_id => 1 },
    'reference'         => { 'block'         => 1 },
    'indexterm'         => { 'block'         => 1 },
    'primary'           => { 'newline_after' => 1 },
    'secondary'         => { 'newline_after' => 1 },
    'tertiary'          => { 'newline_after' => 1 },
    'bookinfo'          => { 'block'         => 1 },
    'articleinfo'       => { 'block'         => 1 },
    'abstract'          => { 'block'         => 1 },
    'inlinemediaobject' => { 'block'         => 1 },
    'publisher'         => { 'block'         => 1 },
    'copyright'         => { 'block'         => 1 },
    'authorgroup'       => { 'block'         => 1 },
    'author'            => { 'block'         => 1 },
    'editor'            => { 'block'         => 1 },
    'corpauthor'        => { 'block'         => 1 },
    'revision'          => { 'block'         => 1 },
    'revhistory'        => { 'block'         => 1 },
    'revdescription'    => { 'block'         => 1 },
    'publishername'     => { 'block'         => 1 },
    'affiliation'       => { 'block'         => 1 },
    'year'              => { 'newline_after' => 1 },
    'holder'            => { 'newline_after' => 1 },
    'revnumber'         => { 'newline_after' => 1 },
    'date'              => { 'newline_after' => 1 },
    'honorific'         => { 'newline_after' => 1 },
    'firstname'         => { 'newline_after' => 1 },
    'surname'           => { 'newline_after' => 1 },
    'email'             => { 'newline_after' => 1 },
    'isbn'              => { 'newline_after' => 1 },
    'issuenum'          => { 'newline_after' => 1 },
    'edition'           => { 'newline_after' => 1 },
    'pubdate'           => { 'newline_after' => 1 },
    'productname'       => { 'newline_after' => 1 },
    'productnumber'     => { 'newline_after' => 1 },
    'pubsnumber'        => { 'newline_after' => 1 },
    'contrib'           => { 'newline_after' => 1 },
    'shortaffil'        => { 'newline_after' => 1 },
    'jobtitle'          => { 'newline_after' => 1 },
    'orgname'           => { 'newline_after' => 1 },
    'orgdiv'            => { 'newline_after' => 1 },
    'citetitle'      => {},
    'country'        => { 'newline_after' => 1 },
    'trademark'      => {},
    'ulink'          => {},
    'firstterm'      => {},
    'menuchoice'     => {},
    'acronym'        => {},
    'abbrev'         => {},
    'command'        => {},
    'filename'       => {},
    'index'          => {},
    'application'    => {},
    'package'        => {},
    'guimenu'        => {},
    'sgmltag'        => {},
    'guilabel'       => {},
    'guibutton'      => {},
    'emphasis'       => {},
    'phrase'         => {},
    'replaceable'    => {},
    'computeroutput' => {},
    'guimenuitem'    => {},
    'textobject'     => { 'block' => 1 },
    'varlistentry'   => { 'block' => 1 },
    'term'           => { 'newline_after' => 1 },
    'colspec'        => { 'newline_after' => 1 },
    'areaspec'       => { 'block' => 1 },
    'areaset'        => { 'block' => 1, 'keep_id' => 1 },
    'area'           => { 'newline_after' => 1, 'keep_id' => 1 },
    'calloutlist'  => { 'block' => 1 },
    'callout'      => { 'block' => 1 },
    'procedure'    => { 'block' => 1, 'newline_after' => 1 },
    'appendix'     => { 'block' => 1 },
    'appendixinfo' => { 'block' => 1 },
    'cmdsynopsis'  => { 'block' => 1 },
    'arg'          => { 'block' => 1 },
    'group'        => { 'block' => 1 },
    'accel'         => {},
    'blockquote'    => { 'block' => 1 },
    'classname'     => {},
    'code'          => {},
    'colophon'      => { 'block' => 1 },
    'envar'         => {},
    'example'       => { 'block' => 1 },
    'footnote'      => { 'keep_id' => 1 },
    'guisubmenu'    => {},
    'interface'     => {},
    'keycap'        => {},
    'keycombo'      => {},
    'literal'       => {},
    'literallayout' => { 'block' => 1, 'verbatim' => 1 },
    'option'        => {},
    'parameter'     => {},
    'prompt'        => {},
    'property'      => {},
    'see'              => { 'newline_after' => 1, },
    'seealso'          => { 'newline_after' => 1, },
    'step'             => { 'block'         => 1 },
    'substeps'         => { 'block'         => 1 },
    'stepalternatives' => { 'block'         => 1 },
    'systemitem'       => {},
    'wordasword'       => {},
    'citerefentry'     => {},
    'manvolnum'        => {},
    'function'         => {},
    'uri'              => {},
    'mousebutton'      => {},
    'hardware'         => {},
    'type'             => {},
    'methodname'       => {},
    'exceptionname'    => {},
    'varname'          => {},
    'interfacename'    => {},
    'othername'        => { 'newline_after' => 1 },
    '~comment'         => {},
    'foreignphrase'    => {},
    'chapterinfo'      => { 'block'         => 1 },
    'keywordset'       => { 'block'         => 1 },
    'keyword'          => { 'newline_after' => 1 },
    'subjectset'       => { 'block'         => 1 },
    'subject'          => { 'block'         => 1 },
    'subjectterm'      => { 'newline_after' => 1 },
);

my %BANNED_TAGS = (
    'glosslist' => {
        'reason' => maketext(
            'This tag set imposes English-language order on glossaries, making them useless when translated.'
        ),
    },
    'glossdiv' => {
        'reason' => maketext(
            'This tag set imposes English-language order on glossaries, making them useless when translated.'
        ),
    },
    'glossary' => {
        'reason' => maketext(
            'This tag set imposes English-language order on glossaries, making them useless when translated.'
        ),
    },
    'glossentry' => {
        'reason' => maketext(
            'This tag set imposes English-language order on glossaries, making them useless when translated.'
        ),
    },
    'glossdef' => {
        'reason' => maketext(
            'This tag set imposes English-language order on glossaries, making them useless when translated.'
        ),
    },

#    'glossterm' => {
#        'reason' => maketext(
#            'This tag set imposes English-language order on glossaries, making them useless when translated.'
#        ),
#    },
    'glosssee' => {
        'reason' => maketext(
            'This tag set imposes English-language order on glossaries, making them useless when translated.'
        ),
    },
    'glossseealso' => {
        'reason' => maketext(
            'This tag set imposes English-language order on glossaries, making them useless when translated.'
        ),
    },
    'entrytbl' => {
        'reason' => maketext(
            'Nested tables break pdf generation -- reconsider your data structure.'
        ),
    },
    'link' => {
        'reason' => maketext(
            'Undesirable tag -- use xref for internal links or ulink for external links.'
        ),
    },
    'olink' => {
        'reason' => maketext(
            'Undesirable tag -- use xref for internal links or ulink for external links.'
        ),
    },
    'inlinegraphic' => {
        'reason' => maketext(
            'This tag breaks section 508 accessibility standards and makes translation extremely difficult.'
        ),
    },
    'tip' => {
        'reason' =>
            maketext('This tag is unnecessary. Use note or important.'),
    },
    'caution' => {
        'reason' =>
            maketext('This tag is unnecessary. Use important or warning.'),
    },
);

my %BANNED_ATTRS = (
    'xreflabel' => {
        'reason' => maketext(
            'xreflabel hides data from translators and, consequently, causes translation errors.'
        ),
    },
    'endterm' => {
        'reason' => maketext(
            'endterm hides data from translators and, consequently, causes translation errors.'
        ),
    },
);

=head2 new

Create a new Publican::XmlClean object.

=cut

sub new {
    my ( $this, $args ) = @_;
    my $class = ref($this) || $this;

    my $config = new Config::Simple();
    $config->syntax('simple');

    $config->param( 'lang', delete( $args->{lang} ) ) if ( $args->{lang} );
    $config->param( 'update_includes', delete( $args->{update_includes} ) )
        if ( $args->{update_includes} );
    $config->param( 'clean_id', ( delete( $args->{clean_id} ) ) || 0 );
    $config->param( 'show_unknown', delete( $args->{show_unknown} ) )
        if ( $args->{show_unknown} );
    $config->param( 'donotset_lang',
        ( delete( $args->{donotset_lang} ) ) || 0 );
    $config->param( 'distributed_set',
        ( delete( $args->{distributed_set} ) ) || 0 );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    my $self = bless {}, $class;
    $self->{config} = $config;

    my $publican = Publican->new();
    $self->{publican} = $publican;

    return $self;
}

=head2  print_known_tags

Print a list of tags that have had their output QA'd.

=cut

sub print_known_tags {
    my $self = shift();
    foreach my $key ( sort( keys(%MAP_OUT) ) ) {
        print("$key\n");
    }

    return;
}

=head2  print_banned_tags

Print a list of tags that are not supported.

=cut

sub print_banned_tags {
    my $self = shift();
    print "\n" . maketext("Banned tags:") . "\n\n";
    foreach my $key ( sort( keys(%BANNED_TAGS) ) ) {
        my $tabs = "\t";

        # Line up output since linegraphic is bigger than 8
        $tabs .= "\t" if ( length($key) < 8 );
        print( "$key:$tabs" . $BANNED_TAGS{$key}{'reason'} . "\n" );
    }

    print "\n\n" . maketext("Banned attributes:") . "\n\n";
    foreach my $attr ( sort( keys(%BANNED_ATTRS) ) ) {
        print( "$attr:\t" . $BANNED_ATTRS{$attr}{'reason'} . "\n" );
    }

    return;
}

=head2 prune_xml($node)

Remove unwanted nodes.

If $lang is set then delete all nodes that have lang set and do not contain $lang

If $arch is set then delete all nodes that have arch set and do not contain $arch

If $condition is set then delete all nodes that have condition set and do not contain $condition 

=cut

sub prune_xml {
    my ( $self, $xml_doc ) = @_;

    my $original_tag = $xml_doc->root()->{'_tag'};

    if ($xml_doc) {
        if ( $self->{config}->param('lang') ) {
            $xml_doc->pos( $xml_doc->root() );
            while (
                my $node = $xml_doc->look_down(
                    sub {
                        $_[0]->attr('lang')
                            && $_[0]->attr('lang')
                            !~ ( $self->{config}->param('lang') );
                    }
                )
                )
            {
                croak(
                    maketext(
                        "FATAL ERROR: language profiling would prune root node. Do NOT set lang in a root node."
                    )
                ) if ( $node->same_as( $xml_doc->root() ) );
                $node->delete();
            }
        }
        if ( $self->{publican}->param('arch') ) {
            $xml_doc->pos( $xml_doc->root() );
            while (
                my $node = $xml_doc->look_down(
                    sub {
                        $_[0]->attr('arch')
                            && $_[0]->attr('arch')
                            !~ ( $self->{publican}->param('arch') );
                    }
                )
                )
            {
                croak(
                    maketext(
                        "FATAL ERROR: arch profiling would prune root node. Do NOT set arch in a root node."
                    )
                ) if ( $node->same_as( $xml_doc->root() ) );
                $node->delete();
            }
        }

        if ( $self->{publican}->param('condition') ) {
            $xml_doc->pos( $xml_doc->root() );
            while (
                my $node = $xml_doc->look_down(
                    sub {
                        $_[0]->attr('condition')
                            && $_[0]->attr('condition')
                            !~ ( $self->{publican}->param('condition') );
                    }
                )
                )
            {
                croak(
                    maketext(
                        "FATAL ERROR: condition profiling would prune root node. Do NOT set condition in a root node."
                    )
                ) if ( $node->same_as( $xml_doc->root() ) );
                $node->delete();
            }
        }
    }

    return;
}

=head2 Clean_ID

Rename ID's and update xrefs.

If this node has a title as a child set it's ID else remove the ID

=cut

sub Clean_ID {
    my ( $self, $node ) = @_;
    my $my_id   = "";
    my $docname = $self->{publican}->param('docname');

    if ($node) {
        my $tag = $node->{'_tag'};

        # keep_id means keep the current ID without modification.
        if ( $MAP_OUT{$tag}->{'keep_id'} ) {
            $my_id = $node->id() || "";
        }
        elsif ( !$MAP_OUT{$tag}->{'no_id'} ) {
            foreach my $child ( $node->content_refs_list() ) {
                if ( ref $$child
                    && $$child->{'_tag'} eq
                    ( $MAP_OUT{$tag}->{'id_node'} || 'title' ) )
                {
                    $my_id = $$child->as_text;
                    $my_id =~ s/[- ]/_/g;
                    $my_id =~ s/[^a-zA-Z0-9\._]//g;
                    $my_id =~ s/_+/_/g;

                    # Must start with a letter!
                    if ( $my_id =~ /^\d/ ) {
                        $my_id = 'a' . $my_id;
                    }

                    if ( $node->parent() ) {
                        my $par_title = $node->parent()
                            ->look_up( sub { $_[0]->attr('id'); } );
                        if ( $my_id ne "" && $par_title ) {
                            my $my_p_id = $par_title->attr('id');

                            $my_p_id =~ s/^.*-//;
                            $my_id = "$my_p_id-$my_id";
                        }
                    }
                    last;
                }
            }
        }

        # prepend book name (to avoid problems in sets)
        # prepend tag type for translations BZ #427312
        if ( $my_id ne "" ) {
            $my_id = "$docname-$my_id";
            $my_id = substr( $tag, 0, 4 ) . "-$my_id";
        }

        if ( $node->id() && $node->id() ne $my_id ) {
            $UPDATED_IDS{ $node->id() } = $my_id;
        }

        if ( $my_id eq "" ) {
            $my_id = undef;
        }

        $node->attr( 'id', $my_id );
    }

    return;
}

=head2 print_xml

Print out utf8 XML files

Have to output xml/DTD header

=cut

sub print_xml {
    my ( $self, $args ) = @_;

    my $xml_doc = delete( $args->{xml_doc} )
        || croak( maketext("xml_doc is a mandatory argument") );
    my $out_file = delete( $args->{out_file} )
        || croak( maketext("out_file is a mandatory argument") );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    my $lvl     = 0;
    my $dtdver  = $self->{publican}->param('dtdver');
    my $docname = $self->{publican}->param('docname');
    my $lang    = $self->{config}->param('lang');

    if ($xml_doc) {
        my $file = $out_file;
        my $path = '';

        # handle nested directories
        if ( $file =~ m|^(.*/xml)/(.*\/)[^\/]*\.xml| ) {
            $path = $2;
            mkpath("$1/$path") if ( !-d $path );
            $path =~ s|[^/]*/|\.\./|g;
        }

        $xml_doc->pos( $xml_doc->root() );
        if (   !$self->{config}->param('clean_id')
            && !$self->{config}->param('update_includes')
            && !$self->{config}->param('donotset_lang') )
        {
            $xml_doc->attr( 'lang', $lang );
        }
        my $type = $xml_doc->attr("_tag");
        $file =~ m|^(.*/xml/)|;
        my $text = $self->my_as_XML(
            { xml_doc => $xml_doc, path => ( $1 || './' ) } );

##        $text =~ s/&#10;//g;
##        $text =~ s/&#9;//g;
        $text =~ s/&#38;([a-zA-Z-_0-9\.-\:]+;)/&$1/g;
        $text =~ s/&#38;/&amp;/g;
##        $text =~ s/&amp;#x200B;/&#x200B;/g;
##        $text =~ s/&#x200B; &#x200B;/ /g;
##        $text =~ s/&#x200B; / /g;
##        $text =~ s/&#60;/&lt;/g;
##        $text =~ s/&#62;/&gt;/g;
##        $text =~ s/&#34;/"/g;
##        $text =~ s/&#39;/'/g;
        $xml_doc->root()->delete();

        my $OUTDOC;
        open( $OUTDOC, ">:utf8", "$out_file" )
            || croak(
            maketext( "Could not open [_1] for output!", $out_file ) );

        my $ent_file = undef;

        # Will be unset when processing common files outside books
        if ($docname) {
            my $xml_lang = $self->{publican}->param('xml_lang');
            if ( -e "$xml_lang/$docname" . '.ent' ) {
                $ent_file = "$path$docname.ent";
            }
        }

        print( $OUTDOC Publican::Builder::dtd_string(
                { tag => $type, dtdver => $dtdver, ent_file => $ent_file }
            )
        );

        #debug_msg("is utf8: " . utf8::is_utf8($text) . "\n");
        print( $OUTDOC $text );
        close($OUTDOC);
    }

    return;
}

=head2 my_as_XML

Traverse tree and output xml as text. Overrides traverse ... evil stuff.

=cut

sub my_as_XML {
    my ( $self, $args ) = @_;

    my $xml_doc = delete( $args->{xml_doc} )
        || croak( maketext("'xml_doc' is a mandatory argument") );
    my $path = delete( $args->{path} )
        || croak( maketext("'path' is a mandatory argument") );

    # based on as_HTML
    my $tree              = $xml_doc->root();
    my @xml               = ();
    my $empty_element_map = $tree->_empty_element_map;

    my $STRICT = 0;    # $self->{publican}->param('strict');
    my $show_unknown = $self->{config}->param('show_unknown');
    my $clean_id     = $self->{config}->param('clean_id');
    my $lang         = $self->{config}->param('lang');

    # This flags tags that use  /> instead of end tags IF they are empty.
    $empty_element_map->{'xref'}        = 1;
    $empty_element_map->{'footnoteref'} = 1;
    $empty_element_map->{'index'}       = 1;
    $empty_element_map->{'xi:include'}  = 1;
    $empty_element_map->{'ulink'}       = 1;
    $empty_element_map->{'imagedata'}   = 1;
    $empty_element_map->{'area'}        = 1;

    my $depth  = 0;
    my $indent = "\t";

    my ( $tag, $node, $start );    # per-iteration scratch

    # $_[0] = node
    # $_[1] = startflag
    # $_[2] = depth
    # $_[3] = parent
    # $_[4] = text node index

    $tree->traverse(
        sub {
            ( $node, $start ) = @_;
            if ( ref $node ) {     # it's an element
                                   # delete internal attrs
                $node->attr( 'depth', undef );
                $node->attr( 'name',  undef );

                $tag = $node->{'_tag'};

                if ($start) {      # on the way in
                    if ( $BANNED_TAGS{$tag} ) {
                        logger(
                            maketext(
                                "*WARNING: Questionable tag found: [_1]",
                                $tag )
                                . "\n",
                            RED
                        );
                        logger( "\t" . $BANNED_TAGS{$tag}->{'reason'} . "\n",
                            RED );
                        logger(
                            "\t"
                                . maketext(
                                "Consider not using this tag", RED
                                )
                                . "\n\n"
                        );
                        if ($STRICT) {
                            croak(
                                maketext(
                                    "Questionable tags are not permitted in STRICT mode. Remove all '[_1]' tags before attempting to build.",
                                    $tag
                                    )
                                    . "\n\n"
                            );
                        }
                    }

                    foreach my $attr ( keys(%BANNED_ATTRS) ) {
                        if ( $node->attr($attr) ) {
                            logger(
                                maketext(
                                    "*WARNING: Questionable attribute found: [_1]",
                                    $attr
                                    )
                                    . "\n",
                                RED
                            );
                            logger(
                                "\t"
                                    . $BANNED_ATTRS{$attr}->{'reason'} . "\n",
                                RED
                            );
                            logger(
                                "\t"
                                    . maketext(
                                    "Consider not using this attribute.")
                                    . "\n\n",
                                RED
                            );

                            if ($STRICT) {
                                croak(
                                    maketext(
                                        "Questionable attributes are not permitted in STRICT mode. Remove all '[_1]' attributes before attempting to build.",
                                        $attr
                                        )
                                        . "\n\n"
                                );
                            }
                        }
                    }

                    if ( ( $show_unknown || $STRICT ) && !$MAP_OUT{$tag} ) {
                        logger(
                            maketext(
                                "*WARNING: Unvalidated tag: '[_1]'. This tag may not be displayed correctly, may generate invalid xhtml, or may breach Section 508 Accessibility standards.",
                                $tag
                                )
                                . "\n",
                            RED
                        );
                    }
                    if ($clean_id) {
                        $self->Clean_ID($node);
                    }

                    if ( $MAP_OUT{$tag}->{'newline'} ) {
                        push( @xml, "\n", $indent x $depth );
                    }

                    if ( $MAP_OUT{$tag}->{'verbatim'} ) {
                        push( @xml, "\n" );
                    }
                    elsif ( $MAP_OUT{$tag}->{'block'} ) {

                   # Check to make sure the block is starting on it's own line
                   # If not add a new line and indent
                        if ( $xml[$#xml] && $xml[$#xml] =~ /\S/ ) {
                            push( @xml, "\n", $indent x $depth );
                        }
                        $depth++;
                    }

                    if ( $tag eq 'imagedata' ) {
                        $node->attr('fileref') =~ m/(...)$/;
                        my $format = uc($1);
                        if ($format) {
                            $node->attr( 'format', $format );
                        }

                        my $img_file = "$path" . $node->attr('fileref');
                        $img_file
                            = $self->{publican}->param('xml_lang') . "/"
                            . $img_file
                            if ($clean_id);
                        if ( -f $img_file ) {
                            my ( $width, $height ) = imgsize($img_file);
                            if ( $@ || !$width ) {
                                logger(
                                    maketext(
                                        "Can't calculate image size, image may render badly. Image File: [_1]. Error Message: [_2]",
                                        $img_file, $@
                                        )
                                        . "\n"
                                );
                            }
                            elsif ( $width
                                > $self->{publican}->param('max_image_width')
                                )
                            {
                                $node->attr( 'width',
                                    $self->{publican}
                                        ->param('max_image_width') );
                            }
                        }
                        elsif ( $img_file !~ /Common_Content/ ) {
                            logger(
                                "\t"
                                    . maketext(
                                    "WARNING: Image missing: [_1]",
                                    $img_file )
                                    . "\n",
                                RED
                            );
                        }

                  # when building distrubuted sets, we need to prepend the
                  # books name to the image path to prevent image name clashes
                        my $preptxt
                            = 'images/' . $self->{publican}->param('docname');

                        if (   $self->{config}->param('distributed_set')
                            && $node->attr('fileref') !~ /^$preptxt/ )
                        {
                            $node->attr( 'fileref',
                                "$preptxt/" . $node->attr('fileref') );
                        }
                    }

                    if ( $empty_element_map->{$tag}
                        and !@{ $node->content_array_ref() } )
                    {
                        push( @xml, $node->starttag_XML( undef, 1 ) );
                        if ( $MAP_OUT{$tag}->{'newline_after'} ) {
                            push( @xml, "\n", $indent x $depth );
                        }
                    }
                    else {
                        push( @xml, $node->starttag_XML(undef) );
                    }

                    if ( $MAP_OUT{$tag}->{'block'} ) {
                        if (   $node->parent()
                            && $MAP_OUT{ $node->parent()->{'_tag'} }
                            ->{'line_wrap'} )
                        {
                            push( @xml, "\n" );
                        }
                        elsif ( not $MAP_OUT{$tag}->{'verbatim'} ) {
                            push( @xml, "\n", $indent x $depth );
                        }
                    }
                }
                else {    # on the way out
                    if ( $MAP_OUT{$tag}->{'block'} ) {

                        # remove empty lines
                        if ( $xml[$#xml] =~ /^[\t ]*$/s ) {
                            pop(@xml);
                            if ( $xml[$#xml] =~ /^[\t ]*$/s ) {
                                pop(@xml);
                            }
                        }

                        # remove trailing space
                        if ( $xml[$#xml] =~ /[\t ]*$/ )    # ||
                        {
                            $xml[$#xml] =~ s/[\t ]*$//;
                        }

                        if ( $MAP_OUT{$tag}->{'block'} ) {
                            if ( $MAP_OUT{$tag}->{'verbatim'} ) {
## BZ #604465 don't add trailing newline.
##                                push( @xml, "\n" );
                            }
                            elsif ($node->parent()
                                && $MAP_OUT{ $node->parent()->{'_tag'} }
                                ->{'line_wrap'} )
                            {
                                $depth--;
                                push( @xml, "\n" );
                            }
                            else {
                                $depth--;
                                push( @xml, "\n", $indent x $depth );
                            }
                        }
                    }

                    unless ( $empty_element_map->{$tag}
                        and !@{ $node->content_array_ref() } )
                    {
                        push( @xml, $node->endtag_XML() );
                    }    # otherwise it will have been an <... /> tag.

                    if ( $MAP_OUT{$tag}->{'newline_after'} ) {
                        push( @xml, "\n", $indent x $depth );
                    }

                    if ( ( $MAP_OUT{$tag}->{'block'} ) ) {
                        push( @xml, "\n", $indent x $depth );
                    }
                }
            }
            else {       # it's just text
                my $parent = $_[3];

                # Remove extra space from non-verbatim tags
                if ( $parent
                    && !( $MAP_OUT{ $parent->{'_tag'} }->{'verbatim'} ) )
                {

                  # Don't out put empty tags
                  # BZ #453067 but spaces between inline tags should be output
                    if ( $node !~ /^[\t ]*$/ || $node !~ /\n/ ) {

                        # Truncate leading space
                        $node =~ s/[\n\r\f\t ]+/ /g;

                        if ( $MAP_OUT{ $parent->{'_tag'} }->{'block'} ) {

                     # for the first child, remove leading space and indent it
                            if ( $_[4] == 0 ) {
                                $node =~ s/^ //g;
                            }
                        }

                        $tree->_xml_escape($node);

                        # zero width space to allow Chinese to wrap
                        if ( $lang
                            && ( $lang eq 'zh-CN' || $lang eq 'zh-TW' ) )
                        {
                            $node =~ s/([\x{2000}-\x{AFFF}])/$1\&\#x200B\;/g;
                        }

                        push( @xml, $node );
                    }
                }
                else {    # Verbatim
                    $tree->_xml_escape($node);
                    push( @xml, $node );
                }
            }
            1;            # keep traversing
        }
    );

    return ( join( '', @xml, "\n" ) );
}

=head2 validate_tables

Ensure Tables comply to requirements not enforceable in XML validation.

1. tgroup attribute cols must match the number of entries in every row.

=cut

sub validate_tables {
    my ( $self, $xml_doc ) = @_;

    if ($xml_doc) {
        $xml_doc->pos( $xml_doc->root() );

        foreach my $node ( $xml_doc->look_down( "_tag", "tgroup" ) ) {

            # TODO this should report the line number
            # until then it try's to determine the Tables title or id
            my $table = $node->look_up( "_tag", qr/table|informaltable/ );
            if ( !$table ) {
                logger(
                    maketext(
                        "WARNING: table validation failed. Could not determine table for tgroup, column numbers cannot be validated"
                    )
                );
                next;
            }
            my $title = $table->look_down( "_tag", "title" );
            if ($title) {
                $title = $title->as_text();
            }
            else {
                $title = ( $table->attr('id') || "Can't identify table" );
            }
            my $cols = $node->attr('cols')
                || croak maketext(
                "*ERROR: Fatal Table Error* Table ([_1]) contains invalid data\nAttribute cols is mandatory for tgroup",
                $title
                ) . "\n";

            foreach my $row ( $node->look_down( "_tag", "row" ) ) {
                my @entries = $row->look_down( "_tag", "entry" );
                if ( @entries > $cols ) {
                    croak maketext(
                        "*ERROR: Fatal Table Error* Table ([_1]) contains invalid data\nAttribute cols ([_2]) does not match number of entry elements ([_3])",
                        $title, $cols, @entries )
                        . "\n";
                }
            }
        }
    }

    return;
}

=head2 sort_glossaries

Sort glosslists

=cut

sub sort_glossaries {
    my ( $self, $xml_doc ) = @_;

    return unless ($test_collate);

    my $Collator = Unicode::Collate->new();

    if ($xml_doc) {
        foreach
            my $glosslist ( $xml_doc->root->look_down( "_tag", "glosslist" ) )
        {
            my @glossentries = sort( {
                    $Collator->cmp(
                        $a->look_down( "_tag", "glossterm" )->as_text(),
                        $b->look_down( "_tag", "glossterm" )->as_text()
                    )
            } $glosslist->look_down( "_tag", "glossentry" ) );

            foreach my $glossentry (@glossentries) {
                $glossentry->detach();
                $glosslist->push_content($glossentry);
            }
        }
    }

    return;
}

=head2 process_file

Create XML::TreeBuilder object and perform operations.

=cut

sub process_file {
    my ( $self, $args ) = @_;

    my $file = delete( $args->{file} )
        || croak( maketext("file is a mandatory argument") );
    my $out_file = delete( $args->{out_file} )
        || croak( maketext("out_file is a mandatory argument") );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    logger(   "\t"
            . maketext( "Processing file [_1] -> [_2]", $file, $out_file )
            . "\n" );

    my $clean_id        = $self->{config}->param('clean_id');
    my $update_includes = $self->{config}->param('update_includes');
    my $xml_lang        = $self->{publican}->param('xml_lang');

    my $xml_doc = XML::TreeBuilder->new(
        { 'NoExpand' => "1", 'ErrorContext' => "2" } );
    $xml_doc->store_comments(1);
##debug_msg("here 1");

    $xml_doc->parse_file($file)
        || croak( maketext( "Can't open file '[_1]' [_2]", $file, $@ ) );
##debug_msg("here 2");

    $self->validate_tables($xml_doc);
    $self->sort_glossaries($xml_doc);

    if ($update_includes) {
        $self->update_include($xml_doc);
    }
    elsif ( !$clean_id ) {
        $self->prune_xml($xml_doc);
    }

    $self->print_xml( { xml_doc => $xml_doc, out_file => $out_file } );

    if ($clean_id) {
        debug_msg(
            "\nTODO: process_file: need to switch from back-ticks to perl. Maybe use PO2XML::load_po as a base fo direct PO manipulation?\n\n"
        );

        # Update links in xml
        foreach my $xml_file ( dir_list( $xml_lang, '*.xml' ) ) {
            foreach my $key ( keys(%UPDATED_IDS) ) {

                # xml usage
                my $count = `grep -c 'linkend="$key"' $xml_file`;
                chomp($count);
                if ($count) {
                    logger(
                        maketext( "\t\tUpdating link '[_1]' in XML file [_2]",
                            $key, $xml_file )
                            . "\n"
                    );
                    my $cmd
                        = q{sed -i -e 's/linkend="} 
                        . $key
                        . '"/linkend="'
                        . $UPDATED_IDS{$key}
                        . q|"/g' |
                        . $xml_file;
                    `$cmd`;
                }
            }
        }

        # update links in PO files
        foreach my $dir ( split( /,/, get_all_langs() ) ) {
            next if ( $dir eq $xml_lang );
            foreach my $po_file ( dir_list( $dir, '*.po' ) ) {
                foreach my $key ( keys(%UPDATED_IDS) ) {
                    my $count = `grep -c '"$key"' $po_file`;
                    chomp($count);
                    if ($count) {
                        logger(
                            maketext(
                                "\t\tUpdating link '[_1]' in PO file [_2]",
                                $key, $po_file )
                                . "\n"
                        );
## TODO could probably do this in a single command with option groups on the slashes
## since the slashes are missing if the line is wrapped at the start or the end of the ID

                        # all of string on one line
                        my $cmd
                            = q{sed -i -e 's/=\\\\"} 
                            . $key
                            . '\\\\"/=\\\\"'
                            . $UPDATED_IDS{$key}
                            . q|\\\\"/g' |
                            . $po_file;
                        `$cmd`;

                        # tail of string line wrapped
                        $cmd
                            = q{sed -i -e 's/=\\\\"} 
                            . $key
                            . '"/=\\\\"'
                            . $UPDATED_IDS{$key}
                            . q|"/g' |
                            . $po_file;
                        `$cmd`;

                        # string line wrapped after '='
                        $cmd
                            = q{sed -i -e 's/\\\\"} 
                            . $key
                            . '\\\\"/\\\\"'
                            . $UPDATED_IDS{$key}
                            . q|\\\\"/g' |
                            . $po_file;
                        `$cmd`;
                    }
                }
            }
        }
    }

    return;
}

1;    # Magic true value required at end of module

=head1 DIAGNOSTICS

=over

=item C<< unknown args %s >>

All subs with named parameters will return this error when unexpected named arguments are provided.

=item C<< %s is a required argument >>

Any sub with a mandatory parameter will return this error if the parameter is undef.

=item C<< Could not open %s for output! >>

The named file could not be opened.

=item C<< Can't calculate image size of %s >>

Images are automatically scaled if thy are to wide, this check could not be
performed due to either access permissions or file weirdness.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Publican::XmlClean requires no configuration files or environment variables.


=head1 DEPENDENCIES

Carp
version
XML::TreeBuilder
Text::Wrap
Config::Simple
Publican
File::Path
Image::Size
Term::ANSIColor
Cwd

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<publican-list@redhat.com>, or through the web interface at
L<https://bugzilla.redhat.com/bugzilla/enter_bug.cgi?product=Fedora&#59amp;version=rawhide&amp;component=publican>.

=head1 AUTHOR

Jeff Fearn  C<< <jfearn@redhat.com> >>
