package Publican::Translate;

use utf8;
use strict;
use warnings;
use 5.008;
use Carp qw(carp croak cluck);
use Publican;
use Publican::Builder;
use Publican::Localise;
use File::Copy::Recursive qw(fcopy rcopy dircopy fmove rmove dirmove);
use File::Path;
use Term::ANSIColor qw(:constants);
use DateTime;
use Locale::PO;
use XML::TreeBuilder;
use String::Similarity;
use Encode qw(is_utf8 decode_utf8 encode_utf8);

use vars qw($VERSION);

$VERSION = '0.2';

# What tags do we translate?
my $TRANSTAGS
    = qr/^(?:ackno|bridgehead|caption|conftitle|contrib|entry|firstname|glossterm|indexterm|jobtitle|keyword|label|lastname|lineannotation|lotentry|member|orgdiv|orgname|othername|para|phrase|productname|refclass|refdescriptor|refentrytitle|refmiscinfo|refname|refpurpose|releaseinfo|revremark|screeninfo|secondaryie|seealsoie|seeie|seg|segtitle|simpara|subtitle|surname|term|termdef|tertiaryie|textobject|title|titleabbrev|screen|programlisting|literallayout)$/;

# Blocks that contain translatable tags that need to be kept inline
my $IGNOREBLOCKS
    = qr/^(?:footnote|citerefentry|indexterm|productname|phrase|textobject)$/;

# Preserve white space in these tags
my $VERBATIM = qr/^(?:screen|programlisting|literallayout)$/;

=head1 NAME

Publican::Translate - Module for manipulating POT and PO files.


=head1 VERSION

This document describes Publican::Translate version $VERSION


=head1 SYNOPSIS

	use Publican::Translate;
	my $po = Publican::Translate->new();

 	$po->update_pot();
	$po->update_po({ langs => 'fr-FR,de-DE' });
	$po->update_po({ langs => 'all' });
	$po->merge_xml({ lang  => 'fr-FR' });

=head1 DESCRIPTION

Creates, updates and merges POT and PO files for Publican projects.

=head1 INTERFACE 

=cut

=head2  new

Create a new Publican::Translate object.

=cut

sub new {
    my ( $this, $args ) = @_;
    my $class = ref($this) || $this;
    my $self = bless {}, $class;

    my $publican = Publican->new();
    $self->{publican} = $publican;

    return $self;
}

=head2 update_pot

Update the pot files

=cut

sub update_pot {
    my ($self) = shift();

    mkdir 'pot' if ( !-d 'pot' );

    my $xml_lang = $self->{publican}->param('xml_lang');
    my @xml_files = dir_list( $xml_lang, '*.xml' );
    foreach my $xml_file ( sort(@xml_files) ) {
        next if ( $xml_file =~ m|$xml_lang/extras/| );
        next if ( $xml_file =~ m|$xml_lang/Legal_Notice.xml| );
        logger( "\t" . maketext( "Processing file [_1]", $xml_file ) . "\n" );
        my $pot_file = $xml_file;
        $pot_file =~ s/\.xml/\.pot/;
        $pot_file =~ s/^$xml_lang/pot/;
        $pot_file =~ m|^(.*)/[^/]+$|;
        my $path = $1;
        mkpath($path) if ( !-d $path );

        my $xml_doc = Publican::Builder::new_tree();
        $xml_doc->parse_file($xml_file)
            || croak(
            maketext( "Can't open file [_1]. Error: [_2]", $xml_file, $@ ) );
        $xml_doc->pos( $xml_doc->root() );

        my $msg_list = $self->get_msgs( { doc => $xml_doc } );
##debug_msg( "hash: " . join( "\n\n", keys( %{$msgids} ) ) . "\n\n" );
        $self->print_msgs( { msg_list => $msg_list, pot_file => $pot_file } );

        # Remove pot files with no content
        unlink($pot_file) if ( -z $pot_file );
    }

    return;
}

=head2 po2xml

Merge XML and PO into a translated XML file.

=cut

sub po2xml {
    my ( $self, $args ) = @_;
    my $xml_file = delete( $args->{xml_file} )
        || croak( maketext("xml_file is a mandatory argument") );
    my $po_file = delete( $args->{po_file} )
        || croak( maketext("po_file is a mandatory argument") );
    my $out_file = delete( $args->{out_file} )
        || croak( maketext("out_file is a mandatory argument") );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    logger(
        "\t"
            . maketext( "Merging [_1] >> [_2] -> [_3]",
            $po_file, $xml_file, $out_file )
            . "\n"
    );

    my $dtdver = $self->{publican}->param('dtdver');

    my $out_doc = Publican::Builder::new_tree();
    $out_doc->parse_file($xml_file)
        || croak(
        maketext( "Can't open file [_1]. Error: [_2]", $xml_file, $@ ) );
    $out_doc->pos( $out_doc->root() );

    my $msgids = Locale::PO->load_file_ashash($po_file);
    foreach my $key ( keys( %{$msgids} ) ) {
##debug_msg("key: $key\n");
##debug_msg("is utf8  key " . utf8::is_utf8($key) . "\n");
        my $msgref = $msgids->{$key};
##debug_msg("is utf8 msgref " . utf8::is_utf8($msgref->msgstr()) . "\n");
        if ( $msgref->obsolete() ) {
##            debug_msg("Deleting obsolete msg_id: $key\n");
            delete( $msgids->{$key} );
        }
        if ( $msgref->fuzzy() ) {
##            debug_msg("no fuzzy matches: $key\n");
            $msgref->msgstr("");
        }
    }

##debug_msg( "hash: " . join( "\n\n", keys( %{$msgids} ) ) . "\n\n" );

    $self->merge_msgs( { out_doc => $out_doc, msgids => $msgids } );

    $out_doc->pos( $out_doc->root() );
    foreach my $node ( $out_doc->look_down( 'processed', 1 ) ) {
        $node->attr( 'processed', undef );
    }

    $out_doc->pos( $out_doc->root() );
    my $type = $out_doc->attr("_tag");
    my $text = $out_doc->as_XML();

##    $text =~ s/&#10;//g;
##    $text =~ s/&#9;//g;
    $text =~ s/&#38;([a-zA-Z-_0-9]+;)/&$1/g;
    $text =~ s/&#38;/&amp;/g;
    $text =~ s/&#60;/&lt;/g;
    $text =~ s/&#62;/&gt;/g;
    $text =~ s/&#34;/"/g;
    $text =~ s/&#39;/'/g;
    $text =~ s/&quot;/"/g;
    $text =~ s/&apos;/'/g;

    $out_doc->root()->delete();

    my $OUTDOC;

    open( $OUTDOC, ">:encoding(UTF-8)", "$out_file" )
        || croak( maketext( "Could not open [_1] for output!", $out_file ) );
    print $OUTDOC Publican::Builder::dtd_string(
        { tag => $type, dtdver => $dtdver, cleaning => 1 } );
##debug_msg("is utf8 text: " . utf8::is_utf8($text) . "\n");
    print( $OUTDOC $text );
    close($OUTDOC);

    return;
}

=head2 update_po

Update the PO files using internal process or msgmerge

=cut

sub update_po {
    my ( $self, $args ) = @_;

    my $langs = delete( $args->{langs} )
        || croak( maketext("langs is a mandatory argument") );

    my $msgmerge  = delete( $args->{msgmerge} );
    my $firstname = delete( $args->{firstname} )
        || croak( maketext("firstname is a mandatory argument") );
    my $surname = delete( $args->{surname} )
        || croak( maketext("surname is a mandatory argument") );
    my $email = delete( $args->{email} )
        || croak( maketext("email is a mandatory argument") );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    my $docname  = $self->{publican}->param('docname');
    my $version  = $self->{publican}->param('version');
    my $type     = $self->{publican}->param('type');
    my $xml_lang = $self->{publican}->param('xml_lang');

    my @pot_files = dir_list( 'pot', '*.pot' );

    foreach my $lang ( sort( split( /,/, $langs ) ) ) {
        next if ( $lang eq $xml_lang );

        unless ( Publican::valid_lang($lang) ) {
            logger(
                maketext( "WARNING: Skipping invalid language: [_1]", $lang )
                    . "\n" );
            next;
        }

        my $lc_lang = $lang;
        $lc_lang =~ s/-/_/g;
        my $locale = Publican::Localise->get_handle($lc_lang)
            || croak(
            maketext(
                "Could not create a Publican::Localise object for language: [_1]",
                $lang
            )
            );
        $locale->encoding("UTF-8");
        $locale->textdomain("publican");
##        $locale->die_for_lookup_failures(1);

        # If asked to update a  non-existing language, create it
        mkdir $lang if ( !-d $lang );

        foreach my $pot_file ( sort(@pot_files) ) {
            my $po_file = $pot_file;

            # remove the t from .pot
            chop($po_file);
            $po_file =~ s/^pot/$lang/;
            logger(
                "\t"
                    . maketext( "Processing file [_1] -> [_2]",
                    $pot_file, $po_file )
                    . "\n"
            );

            # handle nested directories
            $pot_file =~ m|^(.*)/[^/]+$|;
            my $path = $1;
            mkpath($path) if ( !-d $path );
            if ( !-f $po_file || -z $po_file ) {
                fcopy( $pot_file, $po_file );
            }
            else {
                if ( !$msgmerge ) {
                    $self->merge_po(
                        { po_file => $po_file, pot_file => $pot_file } );
                }
                elsif (
                    system(
                        "msgmerge",      "--no-wrap", "--quiet",
                        "--backup=none", "--update",  $po_file,
                        $pot_file
                    ) != 0
                    )
                {
                    croak(
                        maketext(
                            "Fatal Error: msgmerge failed to merge updates. POT File: [_1]. Po File: [_2]",
                            $pot_file,
                            $po_file
                        )
                    );
                }
            }

            my $xml_file = $pot_file;
            $xml_file =~ s/^pot/$xml_lang/;
            $xml_file =~ s/pot$/xml/;
            logger(
                maketext( "WARNING: No source xml file exists for [_1]",
                    $pot_file )
                    . "\n",
                CYAN
            ) unless ( -f $xml_file );
        }

        if ( $self->{publican}->param('type') ne 'brand' ) {
            my ( $edition, $release )
                = $self->{publican}->get_ed_rev( { lang => $xml_lang } );

            my @members = (
                decode_utf8(
                    $locale->maketext(
                        "Translation files synchronised with XML sources [_1]-[_2]",
                        $edition,
                        $release
                    )
                )
            );

            $self->{publican}->add_revision(
                {   lang      => $lang,
                    revnumber => "$edition-$release.1",
                    members   => \@members,
                    email     => $email,
                    firstname => $firstname,
                    surname   => $surname
                }
            );
        }

    }

    return;
}

=head2 merge_po

Merge updated POT files in to existing PO files.

TODO Impliment this...

=cut

sub merge_po {
    my ( $self, $args ) = @_;

    my $po_file = delete( $args->{po_file} )
        || croak( maketext("po_file is a mandatory argument") );
    my $pot_file = delete( $args->{pot_file} )
        || croak( maketext("pot_file is a mandatory argument") );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    my $pot_arry      = Locale::PO->load_file_asarray($pot_file);
    my $po_hash       = Locale::PO->load_file_ashash($po_file);
    my @po_keys       = keys( %{$po_hash} );
    my %po_start_keys = map { $_ => 1 } @po_keys;
    my @out_arry      = ();

POT:
    foreach my $pot ( @{$pot_arry} ) {
        my $pot_id  = $pot->msgid();
        my $matched = 0;
        my %highest = ();
        foreach my $po_id (@po_keys) {
            my $match = $self->match_strings( $pot_id, $po_id );
            if ( $match >= 1 ) {
                delete( $po_start_keys{$po_id} );
                $po_hash->{$po_id}->obsolete(0)
                    if ( $po_hash->{$po_id}->obsolete() );
                $po_hash->{$po_id}->fuzzy(0)
                    if ( $po_hash->{$po_id}->fuzzy() );
                push( @out_arry, $po_hash->{$po_id} );
                next POT;
            }
            elsif ( $match >= 0.8 ) {
                $matched = 1;
                delete( $po_start_keys{$po_id} );
                if (   ( !defined( $highest{match} ) )
                    || ( $match > $highest{match} ) )
                {
                    $highest{match}  = $match;
                    $highest{pot_id} = $pot_id;
                    $highest{po_id}  = $po_id;
                }
            }
        }

        if ( !$matched ) {
            push( @out_arry, $pot );
        }
        else {
            my $id = $highest{po_id};
            $po_hash->{$id}->fuzzy(1) unless ( $po_hash->{$id}->fuzzy() );
            $po_hash->{$id}->obsolete(0) if ( $po_hash->{$id}->obsolete() );
            $po_hash->{$id}
                ->msgid( $po_hash->{$id}->dequote( $highest{pot_id} ) );
            push( @out_arry, $po_hash->{$id} );
        }
    }

    foreach my $obsolete ( keys(%po_start_keys) ) {
        $po_hash->{$obsolete}->obsolete(1);
        push( @out_arry, $po_hash->{$obsolete} );
    }

    Locale::PO->save_file_fromarray( $po_file, \@out_arry );

    return;
}

=head2 match_strings

Compare 2 strings and return how closely they match.

Returns a vlaue between 0 and 1, weighted for string length.

=cut

sub match_strings {
    my ( $self, $s1, $s2 ) = @_;

    croak(
        maketext(
            "match_strings requires 2 arguments [_1], [_2].", $s1, $s2
        )
    ) unless ( ($s1) && ($s2) && ( $s1 ne "" ) && ( $s2 ne "" ) );

    my $similarity = similarity( $s1, $s2 );

## TODO factor string length in to similarity?

    return ($similarity);
}

=head2 update_po_all

Update the PO files for all languages

=cut

sub update_po_all {
    my ( $self, $args ) = @_;

    my $msgmerge  = delete( $args->{msgmerge} );
    my $firstname = delete( $args->{firstname} );
    my $surname   = delete( $args->{surname} );
    my $email     = delete( $args->{email} );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    $self->update_po(
        {   langs     => get_all_langs(),
            msgmerge  => $msgmerge,
            email     => $email,
            firstname => $firstname,
            surname   => $surname,
        }
    );
    return;
}

=head2 get_msgs

Get the strings to translate from an XML::TreeBuilder object

=cut

sub get_msgs {
    my ( $self, $args ) = @_;
    my $doc = delete( $args->{doc} ) || croak("doc is a mandatory argument");

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    my $trans_tree = XML::TreeBuilder->new(
        { 'NoExpand' => "1", 'ErrorContext' => "2" } );

    my $trans_node;

    # Break strings up in to translatable blocks
    # some block level tags, $IGNOREBLOCKS, should be treated inline
    # indexterm is special as it's both translatable and ignorable >_<
    foreach my $child (
        $doc->look_down(
            '_tag',
            qr/$TRANSTAGS/,
            sub {
                my $inner = $_[0];
## an index term NOT in a translatable tag should be translated as a block.
## An indexterm in a translatable tag should be translated inline
                if ( $inner->tag() =~ /indexterm|productname|phrase/ ) {
                    not defined(
                        $inner->look_up(
                            '_tag',
                            qr/$IGNOREBLOCKS/,
                            sub {
                                $_[0]->tag() =~ /$TRANSTAGS/
                                    && $inner->parent()
                                    && $inner->parent()->tag()
                                    =~ /$TRANSTAGS/;
                            },
                        )
                    );
                }
                else {
## Other IGNOREBLOCKS tags are completely ignored for translation structure.
                    not defined(
                        $inner->look_up( '_tag', qr/$IGNOREBLOCKS/ ) );

                }
            }
        )
        )
    {
## BUGBUG is this required here?
##        next if ( $child->attr('processed') );
##        $child->attr( 'processed', 1 );

        next if ( $child->is_empty );

        $trans_node = XML::Element->new( $child->tag() );

     # Have to be inside a translatable tag here, so don't need to check again
        my @matches = $child->look_down(
            '_tag',
            qr/$TRANSTAGS/,
            sub { not defined( $_[0]->look_up( '_tag', qr/$IGNOREBLOCKS/ ) ) }
        );

    # No Nesting so push all of this nodes content on to the output trans_tree
        if ( !$#matches ) {
            $trans_node->push_content( $child->content_list() );
        }
        else {

            #debug_msg("processing a $child->tag()\n");

            # Nesting, need to start a new output node
            $trans_tree->push_content($trans_node)
                if ( !$trans_node->is_empty );
            $trans_node = XML::Element->new( $child->tag() )
                ;    # Does this dupliacte new above?

            # Text nodes are not ref
            # any non-matching node should be pushed on to output with text
            # this catches inline tags
            foreach my $nested ( $child->content_list() ) {
                if (ref $nested

                    && $nested->look_down(
                        '_tag',
                        qr/$TRANSTAGS/,
                        sub {
                            not defined(
                                $_[0]->look_up( '_tag', qr/$IGNOREBLOCKS/ ) );
                        }
                    )
                    )
                {
                    $trans_tree->push_content($trans_node)
                        if ( !$trans_node->is_empty );
                    $trans_node = XML::Element->new( $child->tag() );
                    $trans_tree->push_content(
                        $self->get_msgs( { doc => $nested } )->content_list()
                    );
                }
                else {
                    $trans_node->push_content($nested);
                }
            }

            $trans_tree->push_content($trans_node)
                if ( !$trans_node->is_empty );
        }
        $trans_tree->push_content($trans_node)
            if ( !$trans_node->is_empty );
        $child->delete();
    }

    return ($trans_tree);
}

=head2 merge_msgs

Merge translations in to XML

=cut

sub merge_msgs {
    my ( $self, $args ) = @_;
    my $out_doc = delete( $args->{out_doc} )
        || croak("out_doc is a mandatory argument");
    my $msgids = delete( $args->{msgids} )
        || croak("msgids is a mandatory argument");

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }
    foreach my $child (
        $out_doc->look_down(
            '_tag',
            qr/$TRANSTAGS/,
##            sub { not defined( $_[0]->look_up( '_tag', qr/$IGNOREBLOCKS/ ) ) }
            sub {
                my $inner = $_[0];
## an index term NOT in a translatable tag should be translated as a block.
## An indexterm in a translatable tag should be translated inline
                if ( $inner->tag() =~ /indexterm|productname|phrase/ ) {
                    not defined(
                        $inner->look_up(
                            '_tag',
                            qr/$IGNOREBLOCKS/,
                            sub {
                                $_[0]->tag() =~ /$TRANSTAGS/
                                    && $inner->parent()
                                    && $inner->parent()->tag()
                                    =~ /$TRANSTAGS/;
                            },
                        )
                    );
                }
                else {
## Other IGNOREBLOCKS tags are completely ignored for translation structure.
                    not defined(
                        $inner->look_up( '_tag', qr/$IGNOREBLOCKS/ ) );

                }
            }
        )
        )
    {

        next if ( $child->attr('processed') );
        $child->attr( 'processed', 1 );

        next if ( $child->is_empty );

        my @matches = $child->look_down(
            '_tag',
            qr/$TRANSTAGS/,
            sub { not defined( $_[0]->look_up( '_tag', qr/$IGNOREBLOCKS/ ) ) }
        );

    # No Nesting so push all of this nodes content on to the output trans_tree
        if ( !$#matches ) {
            $self->translate( { node => $child, msgids => $msgids } );
        }
        else {

            my $trans_node = XML::Element->new( $child->tag() );

            # have to recurse through children
            # pop off all children
            my @content = $child->detach_content();
            foreach my $nested (@content) {

                # No ref == text node
                if (ref $nested
                    && $nested->look_down(
                        '_tag',
                        qr/$TRANSTAGS/,
                        sub {
                            not defined(
                                $_[0]->look_up( '_tag', qr/$IGNOREBLOCKS/ ) );
                        }
                    )
                    )
                {
                    if ( $trans_node && !$trans_node->is_empty ) {
                        $self->translate(
                            { node => $trans_node, msgids => $msgids } );
                        $child->push_content( $trans_node->content_list() );
                        $trans_node->delete();
                        $trans_node = XML::Element->new( $child->tag() );
                    }
                    $self->merge_msgs(
                        { out_doc => $nested, msgids => $msgids } );
                    $child->push_content($nested);
                }
                else {
                    $trans_node->push_content($nested);
                }
            }

            if ( $trans_node && !$trans_node->is_empty ) {
                $self->translate(
                    { node => $trans_node, msgids => $msgids } );
                $child->push_content( $trans_node->content_list() );
                $trans_node->delete();
            }
        }
    }

    return;
}

=head2 translate

Replace strings with translated strings.

=cut

sub translate {
    my ( $self, $args ) = @_;
    my $node = delete( $args->{node} )
        || croak("node is a mandatory argument");
    my $msgids = delete( $args->{msgids} )
        || croak("msgids is a mandatory argument");

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    my $msgid = $node->as_XML();
    my $tag   = $node->tag();

##debug_msg("msgid 1: $tag, $msgid\n");
    my $attr_text = '';

##debug_msg("is utf8 msgid: ".utf8::is_utf8($msgid)."\n");
    utf8::encode($msgid);

    $msgid = $self->normalise( $msgid, $tag );
    $msgid = po_format( $msgid, $tag );
    if ( $tag =~ /$VERBATIM/ ) {
        $msgid =~ s/\\\\n/\\n/g;
    }

    #debug_msg("msgid 3: |$msgid| |$tag|\n");

    # If a tag has attributes we need to remove them for comparison as
    # the PO format does not allow this to be stored
## BUGBUG document this better
    if ( $msgid =~ m/^"<$tag([\t ]+[^>]+)>[\t ]*(.*)$/ ) {
        $attr_text = $1;
        $msgid     = qq{"$2};
        $attr_text =~ s/\\//g;
    }

##debug_msg("msgid 4: $tag, $msgid\n");
    # mixed mode tags, para, caption, can be empty at this point
    if ( $msgid and ( $msgid eq '""' ) ) {

        #nop
    }
    elsif ( $msgid
        && defined $msgids->{$msgid} )
    {
        if ( $msgids->{$msgid}{msgstr} ne '""' ) {
            my $msgstr = $msgids->{$msgid}{msgstr};
            debug_msg("DANGER: found obsolete msg: $msgid\n")
                if ( $msgstr =~ /^#~/ );
##debug_msg("is utf8 msgstr 1: " . utf8::is_utf8($msgstr) . "\n");
            utf8::decode($msgstr);
##debug_msg("is utf8 msgstr 2: " . utf8::is_utf8($msgstr) . "\n");
##debug_msg("msgstr: |$msgstr|\n");

            my $repl = po_unformat( $msgstr, $tag );

##debug_msg("is utf8 repl: ".utf8::is_utf8($repl)."\n");
##debug_msg("repl: |$repl|\n");
            my $dtd = Publican::Builder::dtd_string(
                {   tag      => $tag,
                    dtdver   => $self->{publican}->param('dtdver'),
                    cleaning => 1
                }
            );
            my $new_tree = Publican::Builder::new_tree();
            $new_tree->parse(qq|$dtd<$tag$attr_text>$repl</$tag>|);
            $node->delete_content();
            $node->push_content( $new_tree->content_list() );
        }
        else {
##        debug_msg("WARNING: Un-translated message: '$msgid'\n");
            if ( $msgids->{$msgid}->fuzzy() )
            {    # BUGBUG TEST this is still set
                logger( maketext("WARNING: Fuzzy message in PO file."), RED );
            }
            else {
                logger(
                    maketext("WARNING: Un-translated message in PO file."),
                    RED );
            }
            my $str = $msgid;
            $str = substr( $str, 0, 64 ) . '...' if ( length($str) > 64 );
            logger(
                "\n" . $msgids->{$msgid}->loaded_line_number . ": $str\n\n",
                RED );
        }
    }
    else {
##         debug_msg("WARNING: Missing message: '\n$msgid\n'\n");
        logger(
            maketext(
                "WARNING: Message missing from PO file, consider updating your POT and PO files."
            ),
            RED
        );
        logger( "\n" . $msgid . "\n\n", RED );
    }
    return;
}

=head2 print_msgs

Print the translation strings in an XML::TreeBuilder object to a POT file

=cut

sub print_msgs {
    my ( $self, $args ) = @_;
    my $msg_list = delete( $args->{msg_list} )
        || croak("msg_list is a mandatory argument");
    my $pot_file = delete( $args->{pot_file} )
        || croak( maketext("pot_file is a mandatory argument") );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    my $fh;

    open( $fh, ">:encoding(UTF-8)", $pot_file )
        or croak(
        maketext(
            "Failed to open output file [_1]. Error: [_2]",
            $pot_file, $@
        )
        );

    print( $fh $self->header() );

    my %msgs = ();

    foreach my $child ( $msg_list->content_list() ) {
        my $msg_id = $child->as_XML();
##debug_msg("is utf8 msg_id 1: '" . utf8::is_utf8($msg_id) . "'\n");
##debug_msg("msg_id: $msg_id\n");

##        my $msg_id = $child->as_text();
        $msg_id = po_format( $self->normalise( $msg_id, $child->tag() ),
            $child->tag() );
        next unless $msg_id;

##        $msg_id = qq|"$msg_id"|;
        next
            if ( $msg_id eq '' || $msg_id eq '""' || defined $msgs{$msg_id} );
##debug_msg("is utf8 msg_id 2: '" . utf8::is_utf8($msg_id) . "'\n");
##debug_msg("msg_id: $msg_id\n\n");
        $msgs{$msg_id} = 1;
        if ( $child->tag() =~ /$VERBATIM/ ) {
            $msg_id =~ s/\\\\n/\\n"\n"/g;
        }
##debug_msg("is utf8 msg_id 3: '" . utf8::is_utf8($msg_id) . "'\n");
##debug_msg("msg_id: $msg_id\n\n");
        my $tag = $child->tag();
        print $fh <<MSGID
#. Tag: $tag
#, no-c-format
msgid $msg_id
msgstr ""

MSGID

    }

    close($fh);

    return;
}

=head2 header

Returns a valid PO header string.

=cut

sub header {
    my $self = shift;

    #    my $date = UnixDate( ParseDate("today"), "%Y-%m-%d %H:%M%z" );
    my $date = DateTime->now->iso8601();

    my $string = <<POT;
# 
# AUTHOR <EMAIL\@ADDRESS>, YEAR.
#
msgid ""
msgstr ""
"Project-Id-Version: 0\\n"
"POT-Creation-Date: $date\\n"
"PO-Revision-Date: $date\\n"
"Last-Translator: Automatically generated\\n"
"Language-Team: None\\n"
"MIME-Version: 1.0\\n"
"Content-Type: application/x-publican; charset=UTF-8\\n"
"Content-Transfer-Encoding: 8bit\\n"

POT

    return ($string);
}

=head2 normalise

Remove extraneous white space.

=cut

sub normalise {
    my $self = shift;
    my $norm = shift;
    my $name = shift;
    if ( $name =~ /$VERBATIM/ ) {
        $norm =~ s/\n/\\n/g;    # CR
    }
    else {
        $norm =~ s/\n/ /g;        # CR
        $norm =~ s/^[\t ]*//g;    # space at start of line
        $norm =~ s/[\t ]*$//g;    # space at end of line
        $norm =~ s/[\t ]+/ /g;    # colapse spacing
    }

    # Escaped entities :(
## TODO dupe code from XmlClean
##    $norm =~ s/&#10;//g;
##    $norm =~ s/&#9;//g;
##    $norm =~ s/&#38;([a-zA-Z-_0-9]+;)/&$1/g;
    $norm =~ s/&#38;/&amp;/g;
##    $norm =~ s/&amp;#x200B;/&#x200B;/g;
##    $norm =~ s/&#x200B; &#x200B;/ /g;
##    $norm =~ s/&#x200B; / /g;
    $norm =~ s/&#60;/&lt;/g;
    $norm =~ s/&#62;/&gt;/g;
    $norm =~ s/&#34;/"/g;
    $norm =~ s/&#39;/'/g;
    $norm =~ s/&quot;/"/g;
    $norm =~ s/&apos;/'/g;

##debug_msg("is utf8 norm: '" . utf8::is_utf8($norm) . "'\n");
##debug_msg("norm: $norm\n\n");

    return $norm;
}

=head2 po_format

Format a string for use in a PO file.

=cut

sub po_format {
    my $string = shift;
    my $name = shift || '';

    debug_msg("unknown tag for: $string") if $name eq '';

    if ( $name =~ /$VERBATIM/ ) {
        $string =~ s/^<$name>//s;    # remove start tag to reduce polution
        $string =~ s/<\/$name>(?:\\n|[\t ])*$//s
            ;                        # remove close tag to reduce polution
        $string =~ s/\\/\\\\/g;  # \ seen as control sequence by msg* programs
        $string =~ s/\"/\\"/g;   # " seen as special char by msg* programs
    }
    else {
        $string =~ s/^<$name>[\t ]*//s;  # remove start tag to reduce polution
        $string
            =~ s/[\t ]*<\/$name>$//s;    # remove close tag to reduce polution
        $string =~ s/\\/\\\\/g;  # \ seen as control sequence by msg* programs
        $string =~ s/\"/\\"/g;   # " seen as special char by msg* programs
    }
    $string = qq|"$string"|;

    return $string;
}

=head2 po_unformat

Remove PO formatting from a string.

=cut

sub po_unformat {
    my $string = shift;
    my $name = shift || '';

    if ( $name =~ /$VERBATIM/ ) {
        $string =~ s/^\"//msg;    # strip sol quotes added by msguniq etc
        $string =~ s/\"$//msg;    # strip sol quotes added by msguniq etc
##debug_msg("string: $string");
        $string =~ s/\\n/\n/msg;  # strip eol quotes added by msguniq etc
##debug_msg("string: $string");
        $string =~ s/\\"/\"/msg;  # unescape quotes added by po_format
        $string =~ s/\\\\/\\/g;   # unescape backslash added by po_format
    }
    else {
        $string =~ s/^\"//msg;      # strip sol quotes added by msguniq etc
        $string =~ s/\"$//msg;      # strip sol quotes added by msguniq etc
        $string =~ s/\n//msg;       # strip eol quotes added by msguniq etc
        $string =~ s/^[\t ]*//msg
            ;    # strip the leading spaces left from the msgid "" line
        $string =~ s/\\"/\"/msg;    # unescape quotes added by po_format
        $string =~ s/\\\\/\\/g;     # unescape backslash added by po_format
    }
    return $string;
}

=head2 po_report

Generate translation statistics for the supplied language.

=cut

sub po_report {
    my ( $self, $args ) = @_;

    my $lang = delete( $args->{lang} )
        || croak( maketext("'lang' is a mandatory argument") );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    my @po_files = dir_list( $lang, '*.po' );

    my %lang_stats = (
        msg_count     => 0,
        fuzzy_count   => 0,
        trans_count   => 0,
        untrans_count => 0,
        word_count    => 0,
    );
    my $sep   = '=' x 82;
    my $rate  = 250;
    my $frate = $rate * 2;

    my $file_name    = maketext("File Name");
    my $untranslated = maketext("Untranslated");
    my $fuzzy        = maketext("Fuzzy");
    my $translated   = maketext("Translated");

    logger("$sep\n");
    logger(
        sprintf(
            "%-40s %15s %10s %10s\n",
            $file_name, $untranslated, $fuzzy, $translated
        )
    );
    logger("$sep\n");

    foreach my $po_file ( sort(@po_files) ) {

        my $msgids = Locale::PO->load_file_ashash($po_file);

        #debug_msg( "hash: " . join( "\n\n", keys( %{$msgids} ) ) . "\n\n" );

        my %po_stats = (
            msg_count     => 0,
            fuzzy_count   => 0,
            trans_count   => 0,
            untrans_count => 0,
            word_count    => 0,
        );

        foreach my $key ( keys( %{$msgids} ) ) {
            my $msgref = $msgids->{$key};
            $po_stats{msg_count}++;
            next unless $msgref->msgid();

            if ( $msgref->obsolete() ) {
                $po_stats{msg_count}--;
                next;
            }
## More accurate word counts
##            my $count = () = $msgref->msgid() =~ /\w+/g;
            my $count = ()
                = $msgref->msgid()
                =~ /(?:\s+|<\/[a-zA-Z]+><[a-zA-Z]+>\S|-|.$)/g;
            $po_stats{word_count} += $count;
            if ( $msgref->msgstr() =~ /^""$/ ) {
                $po_stats{untrans_count} += $count;
            }
            elsif ( $msgref->fuzzy() ) {
                $po_stats{fuzzy_count} += $count;
            }
            else {
                $po_stats{trans_count} += $count;
            }
        }

        logger(
            sprintf(
                "%-45s %10d %10d %10d\n",
                $po_file,               $po_stats{untrans_count},
                $po_stats{fuzzy_count}, $po_stats{trans_count}
            )
        );

        $lang_stats{msg_count}     += $po_stats{msg_count};
        $lang_stats{fuzzy_count}   += $po_stats{fuzzy_count};
        $lang_stats{trans_count}   += $po_stats{trans_count};
        $lang_stats{untrans_count} += $po_stats{untrans_count};
        $lang_stats{word_count}    += $po_stats{word_count};
    }

    logger("$sep\n");

    my $total = maketext( "Total for [_1]", $lang );
    logger(
        sprintf(
            "%-45s %10d %10d %10d\n",
            $total,                   $lang_stats{untrans_count},
            $lang_stats{fuzzy_count}, $lang_stats{trans_count}
        )
    );

    my $remaining = maketext( "Remaining hours for [_1]", $lang );

    logger(
        sprintf(
            "%-45s %10.2f %10.2f\n",
            $remaining,
            ( $lang_stats{untrans_count} / $rate ),
            ( $lang_stats{fuzzy_count} / $frate )
        )
    );
    logger("$sep\n");

    return;
}

1;    # Magic true value required at end of module
__END__

=head1 DIAGNOSTICS

=over

=item C<< unknown args %s >>

All subs with named parameters will return this error when unexpected named arguments are provided.

=item C<< %s is a required argument >>

Any sub with a mandatory parameter will return this error if the parameter is undef.

=back


=head1 CONFIGURATION AND ENVIRONMENT

Publican requires no configuration files or environment variables.


=head1 DEPENDENCIES

Carp
version
Publican
File::Copy::Recursive
File::Path

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<publican-list@redhat.com>, or through the web interface at
L<https://bugzilla.redhat.com/bugzilla/enter_bug.cgi?product=Publican&amp;component=publican>.


=head1 AUTHOR

Jeff Fearn  C<< <jfearn@redhat.com> >>
