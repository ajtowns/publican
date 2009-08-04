package Publican::Translate;

use utf8;
use strict;
use warnings;
use Carp;
use version;
use Publican;
use Publican::Builder;
use File::Copy::Recursive qw(fcopy rcopy dircopy fmove rmove dirmove);
use File::Path;
use Term::ANSIColor qw(:constants);
use DateTime;
use Locale::PO;
use Encode;

use vars qw($VERSION);

$VERSION = 0.1;

# What tags do we translate?
my $TRANSTAGS
    = '^(ackno|bridgehead|conftitle|contrib|entry|glossterm|jobtitle|label|lineannotation|lotentry|member|orgdiv|para|primary|refclass|refdescriptor|refentrytitle|refmiscinfo|refname|refpurpose|releaseinfo|revremark|screeninfo|secondary|secondaryie|see|seealso|seealsoie|seeie|seg|segtitle|simpara|subtitle|term|termdef|tertiary|tertiaryie|title|titleabbrev)$';

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
        $self->print_msgs( { msg_list => $msg_list, pot_file => $pot_file } );

        # Remove pot files with no content
        unlink($pot_file) if ( !( stat($pot_file) )[7] );
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
            maketext( "unknown arguments: [_1]", join( ", ", keys %{$args} ) ) );
    }
    my $dtdver = $self->{publican}->param('dtdver');

    my $out_doc = Publican::Builder::new_tree();
    $out_doc->parse_file($xml_file)
        || croak(
        maketext( "Can't open file [_1]. Error: [_2]", $xml_file, $@ ) );
    $out_doc->pos( $out_doc->root() );

    my $msgids = Locale::PO->load_file_ashash($po_file);

    #debug_msg( "hash: " . join( "\n\n", keys( %{$msgids} ) ) . "\n\n" );

    $self->merge_msgs( { out_doc => $out_doc, msgids => $msgids } );

    $out_doc->pos( $out_doc->root() );

    $out_doc->traverse(
        sub {
            my ( $node, $start ) = @_;
            if ( ref $node ) {    # it's an element
                $node->attr( 'NoExpand',     undef );
                $node->attr( 'ErrorContext', undef );
            }
        }
    );

    $out_doc->pos( $out_doc->root() );
    my $type = $out_doc->attr("_tag");
    my $text = $out_doc->as_XML();
    $text =~ s/&#10;//g;
    $text =~ s/&#9;//g;
    $text =~ s/&#38;([a-zA-Z-_0-9]+;)/&$1/g;
    $text =~ s/&#38;/&amp;/g;
    $text =~ s/&#60;/&lt;/g;
    $text =~ s/&#62;/&gt;/g;
    $text =~ s/&#34;/"/g;
    $out_doc->root()->delete();

    my $OUTDOC;

    open( $OUTDOC, ">:utf8", "$out_file" )
        || croak( maketext( "Could not open [_1] for output!", $out_file ) );
    print $OUTDOC Publican::Builder::dtd_string(
        { tag => $type, dtdver => $dtdver } );
    print( $OUTDOC $text );
    close($OUTDOC);

    return;
}

=head2 update_po

Update the PO files using msgmerge

=cut

sub update_po {
    my ( $self, $args ) = @_;

    my $langs = delete( $args->{langs} )
        || croak( maketext("langs is a mandatory argument") );

    if ( %{$args} ) {
        croak(
            maketext( "unknown arguments: [_1]", join( ", ", keys %{$args} ) ) );
    }

    my $docname  = $self->{publican}->param('docname');
    my $version  = $self->{publican}->param('version');
    my $type     = $self->{publican}->param('type');
    my $xml_lang = $self->{publican}->param('xml_lang');

    my @pot_files = dir_list( 'pot', '*.pot' );

    foreach my $lang ( sort( split( /,/, $langs ) ) ) {
        next if ( $lang eq $xml_lang );

        unless ( Publican::valid_lang($lang) ) {
            logger( maketext( "WARNING: Skipping invalid langauge: [_1]", $lang )
                    . "\n" );
            next;
        }

        # If asked to update a  non-existing language, create it
        mkdir $lang if ( !-d $lang );

        foreach my $pot_file ( sort(@pot_files) ) {
            my $po_file = $pot_file;
            chop($po_file);
            $po_file =~ s/^pot/$lang/;

            # handle nested directories
            $pot_file =~ m|^(.*)/[^/]+$|;
            my $path = $1;
            mkpath($path) if ( !-d $path );
            if ( !-f $po_file ) {
                fcopy( $pot_file, $po_file );
            }
            else {
                if (system(
                        "msgmerge --quiet --backup=none --update $po_file $pot_file"
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

            #            system("msgfmt -c -f --statistics $po_file");
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
    }

    return;
}

=head2 update_po_all

Update the PO files for all languages

=cut

sub update_po_all {
    my ( $self, $args ) = @_;

#    my $lang = delete( $args->{lang} ) || croak("lang is a mandatory argument");
#
#    if ( %{$args} ) {
#        croak( maketext("unknown arguments: [_1]", join( ", ", keys %{$args}) ));
#    }

    $self->update_po( { langs => get_all_langs() } );
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
            maketext( "unknown arguments: [_1]", join( ", ", keys %{$args} ) ) );
    }

    my $trans_tree = XML::TreeBuilder->new();

    my $trans_node;

    foreach my $child ( $doc->look_down( '_tag', qr/$TRANSTAGS/ ) ) {

        # lookdown matches the root node
        if ( $child->address() eq $trans_tree->address() ) {
            next;
        }

        $trans_node = XML::Element->new( $child->tag() );

        my @matches = $child->look_down( '_tag', qr/$TRANSTAGS/ );

        # No Nesting so push all of this nodes content on to the output trans_tree
        if ( !$#matches ) {
            $trans_node->push_content( $child->content_list() );
        }
        else {

            # Nesting, need to start a new output node
            $trans_tree->push_content($trans_node)
                if ( !$trans_node->is_empty );
            $trans_node = XML::Element->new( $child->tag() )
                ;    # Does this dupliacte new above?

            # Text nodes are not ref
            # any non-matching node should be pushed on to output with text
            # this catches inline tags
            foreach my $nested ( $child->content_list() ) {
                if ( ref $nested
                    && $nested->look_down( '_tag', qr/$TRANSTAGS/ ) )
                {
                    $trans_tree->push_content($trans_node);
                    $trans_node = XML::Element->new( $nested->tag() );
                    $trans_tree->push_content(
                        $self->get_msgs( { doc => $nested } )->content_list() );
                }
                else {
                    $trans_node->push_content($nested);
                }
            }

            $trans_tree->push_content($trans_node);
        }
        $trans_tree->push_content($trans_node);
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
            maketext( "unknown arguments: [_1]", join( ", ", keys %{$args} ) ) );
    }
    foreach my $child ( $out_doc->look_down( '_tag', qr/$TRANSTAGS/ ) ) {

        # lookdown matches the root node
        if ( $child->address() eq $out_doc->address() ) {
            next;
        }
        my @matches = $child->look_down( '_tag', qr/$TRANSTAGS/ );

        # No Nesting so push all of this nodes content on to the output trans_tree
        if ( !$#matches ) {
            $self->translate( { node => $child, msgids => $msgids } );
        }
        else {

            # have to recurse through children
            my $trans_node = XML::Element->new( $child->tag() );

            foreach my $nested ( $child->content_list() ) {
                if ( ref $nested
                    && $nested->look_down( '_tag', qr/$TRANSTAGS/ ) )
                {
                    if ( !$trans_node->is_empty ) {
                        $self->translate(
                            { node => $trans_node, msgids => $msgids } );
                    }
                    $self->merge_msgs(
                        { out_doc => $nested, msgids => $msgids } );

                }
                else {
                    $nested->detach() if ( ref $nested );
                    $trans_node->push_content($nested);
                }
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
    my $node = delete( $args->{node} ) || croak("node is a mandatory argument");
    my $msgids = delete( $args->{msgids} )
        || croak("msgids is a mandatory argument");

    if ( %{$args} ) {
        croak(
            maketext( "unknown arguments: [_1]", join( ", ", keys %{$args} ) ) );
    }

    my $msgid = $node->as_XML();
    my $tag   = $node->tag();
    $msgid = $self->normalise($msgid);
    $msgid = po_format( $msgid, $tag );
    if (   $msgid
        && defined $msgids->{ '"' . $msgid . '"' }
        && ( $msgids->{ '"' . $msgid . '"' }{msgstr} ne '""' ) )
    {
        my $repl = Encode::decode_utf8(
            po_unformat( $msgids->{ '"' . $msgid . '"' }{msgstr} ) );

        #debug_msg("is utf8: ".utf8::is_utf8($repl)."\n");
        my $dtd = Publican::Builder::dtd_string(
            { tag => $tag, dtdver => $self->{publican}->param('dtdver') } );
        my $new_tree = Publican::Builder::new_tree();
        $new_tree->parse(qq|$dtd<$tag>$repl</$tag>|);
        $node->delete_content();
        $node->push_content( $new_tree->content_list() );
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
            maketext( "unknown arguments: [_1]", join( ", ", keys %{$args} ) ) );
    }

    my $fh;

    open( $fh, ">:utf8", $pot_file )
        or croak(
        maketext( "Failed to open output file [_1]. Error: [_2]", $pot_file, $@ )
        );

    print( $fh $self->header() );

    my %msgs = ();

    foreach my $child ( $msg_list->content_list() ) {
        my $msg_id = $child->as_XML();
        $msg_id = po_format( $self->normalise($msg_id), $child->tag() );
        next unless $msg_id;
        $msg_id = qq|"$msg_id"|;
        next if ( defined $msgs{$msg_id} );
        $msgs{$msg_id} = 1;
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

    debug_msg("TODO: header: confirm this doesn't break on update\n");

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

Remove extranious white space.

=cut

sub normalise {
    my $self = shift;
    my $norm = shift;
    my $name = shift;
    $norm =~ s/\n/ /g;     # CR
    $norm =~ s/^\s*//g;    # space at start of line
    $norm =~ s/\s*$//g;    # space at end of line
    $norm =~ s/\s+/ /g;    # colapse spacing
    return $norm;
}

=head2 po_format

Format a stirng for use in a PO file.

=cut

sub po_format {
    my $string = shift;
    my $name   = shift;
    $string =~ s/^<$name>\s*//s;     # remove start tag to reduce polution
    $string =~ s/\s*<\/$name>$//s;   # remove close tag to reduce polution
    $string =~ s/\\/\\\\/g;          # \ seen as control sequence by msg* programs
    $string =~ s/\"/\\"/g;           # " seen as special char by msg* programs
    return $string;
}

=head2 po_unformat

Remove PO formatting from a string.

=cut

sub po_unformat {
    my $string = shift;

    $string =~ s/^\"//msg;  # strip sol quotes added by msguniq etc
    $string =~ s/\"$//msg;  # strip sol quotes added by msguniq etc
    $string =~ s/\n//msg;   # strip eol quotes added by msguniq etc
    $string =~ s/^\s*//msg; # strip the leading spaces left from the msgid "" line
    $string =~ s/\\"/\"/msg;    # unescape quotes added by po_format
    $string =~ s/\\\\/\\/g;     # unescape backslash added by po_format
    return $string;
}

1;                              # Magic true value required at end of module
__END__

=head1 DIAGNOSTICS

=over

=item C<< unknown args %s >>

All subs with named parameters will return this error when unexpected anmed arguments are provided.

=item C<< %s is a required argument >>

Any sub with a mandadtory parameter will return this error if the parameter is undef.

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
L<https://bugzilla.redhat.com/bugzilla/enter_bug.cgi?product=Fedora&amp;version=rawhide&amp;component=publican>.


=head1 AUTHOR

Jeff Fearn  C<< <jfearn@redhat.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009 Jeff Fearn C<< <jfearn@redhat.com> >>. All rights reserved.

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

