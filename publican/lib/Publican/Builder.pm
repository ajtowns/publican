package Publican::Builder;

use utf8;
use strict;
use warnings;
use 5.008;
use Carp;
use Config::Simple '-strict';
use Publican;
use Publican::XmlClean;
use Publican::Translate;
use File::Copy::Recursive qw(fcopy rcopy dircopy fmove rmove dirmove);
use File::Path;
use File::pushd;
use File::Find;
use XML::LibXSLT;
use XML::LibXML;
use Cwd qw(abs_path);
use Archive::Tar;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use DateTime;
use DateTime::Format::DateParse;
use Syntax::Highlight::Engine::Kate;
use HTML::TreeBuilder;
use HTML::FormatText;
## BUGBUG test for BZ #697363
## BUGBUG HTML::FormatText::WithLinks::AndTables requires patches from
# https://rt.cpan.org/Public/Bug/Display.html?id=63555
# https://rt.cpan.org/Public/Bug/Display.html?id=55919
use HTML::FormatText::WithLinks::AndTables;
use HTML::FormatText::WithLinks;
use Term::ANSIColor qw(:constants);
use POSIX qw(floor :sys_wait_h);
use Locale::Language;
use List::Util qw(max);
use Text::Wrap qw(fill $columns);
use IO::String;
use File::Which;
use Text::CSV_XS;
use Publican::ConfigData;
use Sort::Versions;
use Template;
use Encode qw(is_utf8 decode_utf8 encode_utf8);

$File::Copy::Recursive::KeepMode = 0;

use vars qw(@ISA $VERSION @EXPORT @EXPORT_OK);

$VERSION = '0.2';
@ISA     = qw(Exporter);

my $INVALID = 1;

my $DEFAULT_WRAP = 82;
$columns = $DEFAULT_WRAP;

=head1 NAME

Publican::Builder - A module to Convert XML to various output formats


=head1 VERSION

This document describes Publican::Builder version 0.1

=head1 SYNOPSIS

    use Publican::Builder;
    my $builder = Publican::Builder->new();
    $builder->clean_ids();

=head1 DESCRIPTION

Manipulate XML and convert to other formats.

=head1 INTERFACE 

=cut

=head2  new

Create a new Publican::XmlBuilder object.

=cut

sub new {
    my ( $this, $args ) = @_;
    my $class = ref($this) || $this;

    my $novalid = delete( $args->{novalid} ) || 0;

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    my $self = bless {}, $class;

    $self->{publican}   = Publican->new();
    $self->{translator} = Publican::Translate->new();
    $self->{validate}   = !$novalid;

    return $self;
}

=head2  build

Transform the source in to another format.

Valid formats: eclipse epub html html-single html-desktop man pdf txt

=cut

sub build {
    my ( $self, $args ) = @_;

    my $langs = delete( $args->{langs} )
        || croak( maketext("langs is a mandatory argument") );
    my $formats = delete( $args->{formats} )
        || croak( maketext("formats is a mandatory argument") );
    my $publish         = delete( $args->{publish} )         || undef;
    my $embedtoc        = delete( $args->{embedtoc} )        || undef;
    my $distributed_set = delete( $args->{distributed_set} ) || 0;

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    my $product = $self->{publican}->param('product');
    my $version = $self->{publican}->param('version');
    my $docname = $self->{publican}->param('docname');
    my $tmp_dir = $self->{publican}->param('tmp_dir');
    my $type    = $self->{publican}->param('type');
    my $brand   = $self->{publican}->param('brand');

    if ( ( $type eq 'Set' ) && ( $self->{publican}->{config}->param('scm') ) )
    {
        $self->get_books();
        $self->build_set_books( { langs => $langs } );
    }

    if ( $langs =~ /^all$/i ) {
        $langs = get_all_langs();
    }

    my $drupal = 0;
    if ( $formats =~ /drupal-book/ ) {
        $drupal = 1;
    }

    $self->setup_xml(
        {   langs           => $langs,
            exlude_common   => ( $type eq 'brand' ),
            distributed_set => $distributed_set,
            drupal          => $drupal
        }
    );

    foreach my $lang ( sort( split( /,/, $langs ) ) ) {
        logger( maketext( "Beginning work on [_1]", $lang ) . "\n" );

        # hmmm can't validate brand XML as it's incomplete
        if (    ( $type ne 'brand' )
            and $self->{validate}
            and ( $self->validate_xml( { lang => $lang } ) == $INVALID ) )
        {
            logger(
                maketext(
                    "All build formats will be skipped for language: [_1]",
                    $lang )
                    . "\n",
                RED
            );
            next;
        }

        # catch txt not being rebuilt BZ #802576
        my $rebuild = 1;

        foreach my $format ( split( /,/, $formats ) ) {
            logger( "\t" . maketext( "Starting [_1]", $format ) . "\n" );
            if ( $format eq 'test' ) {
                logger( "\t" . maketext( "Finished [_1]", $format ) . "\n" );
                next;
            }

            $self->transform(
                {   format   => $format,
                    lang     => $lang,
                    embedtoc => $embedtoc,
                    rebuild  => $rebuild
                }
            ) unless ( $format eq 'xml' );

            $rebuild = 0 if ( $format eq 'txt' || $format eq 'html-single' );

            if ($publish) {
                if ( $type eq 'brand' ) {
                    my $path = "publish/$brand/$lang";
                    mkpath($path);
                    rcopy( "$tmp_dir/$lang/$format/*", "$path/." )
                        if ( -d "$tmp_dir/$lang/$format" );
                }
                else {
                    my $path
                        = "publish/$lang/$product/$version/$format/$docname";

                    # The basic layout is for the web system
                    # but these formats are used differently
                    if ( $self->{publican}->param('web_home') ) {
                        $path = "publish/home/$lang";
                    }
                    elsif ( $self->{publican}->param('web_type') ) {
                        my $web_type = $self->{publican}->param('web_type');
                        if ( $web_type =~ m/^home$/i ) {
                            $path = "publish/home/$lang";
                            fcopy( 'site_overrides.css',
                                'publish/home/site_overrides.css' )
                                if ( -f 'site_overrides.css' );

                            # Build ADs
                            if ( -f "$tmp_dir/$lang/xml/Ads.xml" ) {
                                mkpath($path);
                                my $common_config = $self->{publican}
                                    ->param('common_config');

                                my $xsl_file
                                    = $common_config . "/xsl/carousel.xsl";

                                # required for Windows
                                $xsl_file =~ s/"//g;
                                my $parser = XML::LibXML->new();
                                my $xslt   = XML::LibXSLT->new();
                                my $source;
                                eval {
                                    $source
                                        = $parser->parse_file(
                                        "$tmp_dir/$lang/xml/Ads.xml");
                                };
                                if ($@) {

                                    if ( ref($@) ) {

                       # handle a structured error (XML::LibXML::Error object)
                                        croak(
                                            maketext(
                                                "FATAL ERROR: [_1]:[_2] in [_3] on line [_4]: [_5]",
                                                $@->domain(),
                                                $@->code(),
                                                $@->file(),
                                                $@->line(),
                                                $@->message(),
                                            )
                                        );
                                    }
                                    else {
                                        croak(
                                            maketext(
                                                "FATAL ERROR: [_1]", $@
                                            )
                                        );
                                    }
                                }

                                my $style_doc
                                    = $parser->parse_file($xsl_file);
                                my $stylesheet
                                    = $xslt->parse_stylesheet($style_doc);
                                my $results = $stylesheet->transform($source);
                                my $outfile;
                                my $ad_file = "$path/carousel.html";

                                open( $outfile, ">:encoding(UTF-8)",
                                    "$ad_file" )
                                    || croak(
                                    maketext(
                                        "Can't open ad file: [_1]", $@
                                    )
                                    );
                                print( $outfile $stylesheet->output_string(
                                        $results) );
                                close($outfile);
                            }
                        }
                        elsif ( $web_type =~ m/^product$/i ) {
                            $path = "publish/home/$lang/$product";
                        }
                        elsif ( $web_type =~ m/^version$/i ) {
                            $path = "publish/home/$lang/$product/$version";
                        }
                    }
                    elsif ( $format eq 'html-desktop' ) {
                        $path = "publish/desktop/$lang";
                    }
                    elsif ( $format eq 'xml' ) {
                        $path = "publish/xml/$lang";
                    }
                    elsif ( $format eq 'eclipse' ) {
                        $path = "publish/eclipse/$lang";
                    }

                    mkpath($path);
                    if ( $format eq 'epub' ) {
                        fcopy( "$tmp_dir/$lang/" . $self->{epub_name},
                            "$path/." );
                    }
                    else {
## TODO BUGBUG BZ #648126
# for some reason the UTF8 file name is getting munged dep inside rcopy
# works from from the command line though O_O
# perl -e 'use File::Copy::Recursive qw(rcopy);rcopy("build/en-US/html", "test");'
#
## Work around BZ #648126 ... gonna need to do an UTF8 audit maybe ...
##  Check, UTF8 file names, UTF8 output from XmlClean, Translate, WebSite.
## however the work around blows up on Windows :(
                        if ( $^O eq 'MSWin32' ) {
                            rcopy( "$tmp_dir/$lang/$format/*", "$path/." )
                                if ( -d "$tmp_dir/$lang/$format" );
                        }
                        else {
                            system(
                                qq|perl -e 'use File::Copy::Recursive qw(rcopy);rcopy( "$tmp_dir/$lang/$format/*", "$path/." )'|
                            ) if ( -d "$tmp_dir/$lang/$format" );
                        }

             # for splash pages, we need to rename them if using a web style 2
                        if ($self->{publican}->param('web_type')
##                            && $self->{publican}->param('web_style') == 2
                            )
                        {
                            fmove( "$path/index.html", "$path/splash.html" );
                        }
                    }
                }
            }
            logger( "\t" . maketext( "Finished [_1]", $format ) . "\n" );
        }
    }

    if ($publish) {
        if ( $type eq 'brand' && -d 'xsl' ) {
            my $path = "publish/$brand/xsl";
            mkpath($path);
            rcopy( "xsl", "$path/." );
        }
        if ( $type eq 'brand' && -d 'book_templates' ) {
            my $path = "publish/$brand/book_templates";
            mkpath($path);
            rcopy( "book_templates", "$path/." );
        }
    }
    debug_msg("end of build\n");
    return;
}

=head2 setup_xml

Create the proper directory structure for the XML, including copying in Brand files.

=cut

sub setup_xml {
    my ( $self, $args ) = @_;
    my $xml_lang = $self->{publican}->param('xml_lang');
    my $tmp_dir  = $self->{publican}->param('tmp_dir');
    my $type     = $self->{publican}->param('type');

    my $exlude_common = delete( $args->{'exlude_common'} ) || undef;
    my $langs = delete( $args->{langs} )
        || croak( maketext("langs is a mandatory argument") );
    my $distributed_set = delete( $args->{distributed_set} ) || 0;
    my $drupal          = delete( $args->{drupal} )          || 0;
    my $cleaning        = delete( $args->{cleaning} )        || 0;

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    foreach my $lang ( split( /,/, $langs ) ) {
        logger( maketext( "Setting up [_1]", $lang ) . "\n" );

        croak(
            maketext(
                "Invalid build request: language directory [_1] does not exist.",
                $lang
            )
        ) if ( !-d $lang );

        mkpath("$tmp_dir/$lang/xml");

        my $lc_lang = $lang;
        $lc_lang =~ s/-/_/g;
        my $locale = Publican::Localise->get_handle($lc_lang)
            || croak(
            "Could not create a Publican::Localise object for language: [_1]",
            $lang
            );
        $locale->encoding("UTF-8");
        $locale->textdomain("publican");

        if ( $lang eq $xml_lang ) {

            if ($drupal) {

                # preprocess. set the unique id for every sections
                my $set_ids = Publican::XmlClean->new();

                logger( maketext("Preprocessing xml files...\n") );
                $set_ids->set_unique_ids();
                logger( maketext("Finish preprocess\n") );
            }

            dircopy( $lang, "$tmp_dir/$lang/xml_tmp" );
        }
        elsif ( ( $self->{publican}->param('ignored_translations') )
            && ($self->{publican}->param('ignored_translations') =~ m/$lang/ )
            )
        {
            logger(
                "\t"
                    . maketext( "Bypassing translation for [_1]", $lang )
                    . "\n",
                GREEN
            );
            dircopy( $self->{publican}->param('xml_lang'),
                "$tmp_dir/$lang/xml_tmp" );
        }
        else {
            my @po_files = dir_list( $lang, '*.po' );
            croak(
                maketext(
                    "Invalid build request: no PO files exist for language [_1]",
                    $lang
                )
            ) unless (@po_files);

            mkpath("$tmp_dir/$lang/xml_tmp");

            my @xml_files
                = dir_list( $self->{publican}->param('xml_lang'), '*.xml' );

            foreach my $xml_file ( sort(@xml_files) ) {
                my $po_file = $xml_file;
                $po_file =~ s/\.xml/\.po/;
                $po_file =~ s/$xml_lang/$lang/;

                my $out_file = $xml_file;
                $out_file =~ s/$xml_lang//;

                $out_file =~ m|^(.*)/[^/]+$|;
                my $path = ( $1 || undef );
                mkpath("$tmp_dir/$lang/xml_tmp/$path")
                    if ( $path && !-d $path );

                if ( !-f $po_file ) {
                    logger(
                        "\t"
                            . maketext(
                            "PO file '[_1]' not found! Using base XML!",
                            $po_file )
                            . "\n",
                        CYAN
                    );
                    rcopy( $xml_file, "$tmp_dir/$lang/xml_tmp/$out_file" );
                }
                else {
                    $self->{translator}->po2xml(
                        {   xml_file => $xml_file,
                            po_file  => $po_file,
                            out_file => "$tmp_dir/$lang/xml_tmp/$out_file"
                        }
                    );
                }
            }

            my $rev_file = "Revision_History.xml";
            $rev_file = $self->{publican}->param('rev_file')
                if ( $self->{publican}->param('rev_file') );

            if ( -f "$lang/$rev_file" ) {
                my $rev_tree       = $self->{publican}->new_tree();
                my $trans_rev_tree = $self->{publican}->new_tree();

                $rev_tree->parse_file("$tmp_dir/$lang/xml_tmp/$rev_file");
                $trans_rev_tree->parse_file("$lang/$rev_file");

                my $merged_rev_tree = XML::Element->new_from_lol(
                    [   'appendix',
                        [   'title',
                            decode_utf8(
                                $locale->maketext('Revision History')
                            )
                        ],
                        [ 'simpara', ['revhistory'], ],
                    ],
                );

                my $node
                    = $merged_rev_tree->look_down( '_tag', "revhistory" );

                my @revisions = sort {
                    versioncmp(
                        $b->look_down( '_tag', "revnumber" )->as_text(),
                        $a->look_down( '_tag', "revnumber" )->as_text()
                        )
                    } (
                    $rev_tree->look_down( '_tag', "revision" ),
                    $trans_rev_tree->look_down( '_tag', "revision" )
                    );

                $node->push_content(@revisions);
                my $OUTDOC;
                open( $OUTDOC, ">:encoding(UTF-8)",
                    "$tmp_dir/$lang/xml_tmp/$rev_file" )
                    || croak(
                    maketext(
                        "Could not open [_1] for output!",
                        "$tmp_dir/$lang/xml_tmp/$rev_file",
                        $@
                    )
                    );

                print( $OUTDOC Publican::Builder::dtd_string(
                        { tag => 'appendix', dtdver => '4.5', cleaning => 1 }
                    )
                );

                print( $OUTDOC $merged_rev_tree->as_XML() );
                close($OUTDOC);
            }

            my $trans_file = "$lang/Author_Group.xml";
            if ( -f $trans_file ) {
                my $auth_file = "$tmp_dir/$lang/xml_tmp/Author_Group.xml";

                my $auth_doc = XML::TreeBuilder->new(
                    { 'NoExpand' => "1", 'ErrorContext' => "2" } );
                $auth_doc->parse_file($auth_file);
                my $auth_node = eval {
                    $auth_doc->root()->look_down( "_tag", "authorgroup" );
                };
                if ($@) {
                    croak(
                        maketext(
                            "authorgroup not found in [_1]", $auth_file
                        )
                    );
                }
                my $trans_doc = XML::TreeBuilder->new(
                    { 'NoExpand' => "1", 'ErrorContext' => "2" } );
                $trans_doc->parse_file($trans_file);
                my $trans_node = eval {
                    $trans_doc->root()->look_down( "_tag", "authorgroup" );
                };
                if ($@) {
                    croak(
                        maketext(
                            "authorgroup not found in [_1]", $trans_file
                        )
                    );
                }

                $auth_doc->push_content( $trans_doc->detach_content() );
                my $text = $auth_doc->as_XML();

                my $OUTDOC;
                open( $OUTDOC, ">:encoding(UTF-8)", $auth_file )
                    || croak(
                    maketext( "Could not open [_1] for output!", $auth_file )
                    );
                print( $OUTDOC $text );
                close($OUTDOC);
                $auth_doc->root()->delete();
                $trans_node->root()->delete();
            }

        }

        # clean XML
        my $cleaner = Publican::XmlClean->new(
            {   lang            => $lang,
                donotset_lang   => $exlude_common,
                distributed_set => $distributed_set,
                cleaning        => $cleaning,
            }
        );

        my @xml_files = dir_list( "$tmp_dir/$lang/xml_tmp", '*.xml' );

        # copy css for brand and default images for non-brand
        if ( $type eq 'brand' ) {
            dircopy( "$xml_lang/css", "$tmp_dir/$lang/xml/css" )
                if ( -d "$xml_lang/css" );
            dircopy( "$lang/css", "$tmp_dir/$lang/xml/css" )
                if ( -d "$lang/css" );

            dircopy( "$xml_lang/scripts", "$tmp_dir/$lang/xml/scripts" )
                if ( -d "$xml_lang/scripts" );
            dircopy( "$lang/scripts", "$tmp_dir/$lang/xml/scripts" )
                if ( -d "$lang/scripts" );
        }

        dircopy( "$xml_lang/images", "$tmp_dir/$lang/xml/images" )
            if ( -d "$xml_lang/images" );

        dircopy( "$lang/images", "$tmp_dir/$lang/xml/images" )
            if ( -d "$lang/images" );

        unless ($exlude_common) {
            mkpath("$tmp_dir/$lang/xml/Common_Content");

            # copy common files
            my $common_content = $self->{publican}->param('common_content');
            my $brand          = $self->{publican}->param('brand');
            my $base_brand
                = ( $self->{publican}->{brand_config}->param('base_brand')
                    || 'common' );

            if ( $common_content =~ m/\"/ & $common_content !~ m/\s/ ) {
                $common_content =~ s/\"//g;
            }

            my $brand_path = $self->{publican}->param('brand_dir')
                || $common_content . "/$brand";

            File::Copy::Recursive::rcopy_glob(
                $common_content . "/$base_brand/en-US/*",
                "$tmp_dir/$lang/xml/Common_Content"
            );
            File::Copy::Recursive::rcopy_glob(
                $common_content . "/$base_brand/$lang/*",
                "$tmp_dir/$lang/xml/Common_Content"
            ) if ( $lang ne 'en-US' );

            if (   ( $brand ne $base_brand )
                || ( $brand_path ne $common_content . "/$brand" ) )
            {
                my $brand_lang
                    = $self->{publican}->{brand_config}->param('xml_lang');

                my @files = File::Copy::Recursive::rcopy_glob(
                    $brand_path . "/$brand_lang/*",
                    "$tmp_dir/$lang/xml/Common_Content"
                );

                croak(
                    maketext(
                        "Brand '[_1]' had no content to copy.", $brand
                    )
                ) if ( scalar(@files) == 0 );

                File::Copy::Recursive::rcopy_glob( "$brand_path/$lang/*",
                    "$tmp_dir/$lang/xml/Common_Content" )
                    if ( $lang ne $brand_lang );
            }

            my $main_file = $self->{publican}->param('mainfile');

            my $ent_file = "$xml_lang/$main_file.ent";
            rcopy( $ent_file, "$tmp_dir/$lang/xml/." ) if ( -e $ent_file );

            $ent_file = "$lang/$main_file.ent";
            rcopy( $ent_file, "$tmp_dir/$lang/xml/." ) if ( -e $ent_file );

            dircopy( "$xml_lang/extras", "$tmp_dir/$lang/xml/extras" )
                if ( -d "$xml_lang/extras" );
            dircopy( "$lang/extras", "$tmp_dir/$lang/xml/extras" )
                if ( -d "$lang/extras" );

            my @com_xml_files
                = dir_list( "$tmp_dir/$lang/xml/Common_Content", '*.xml' );

            $cleaner->{config}->param( 'common', 1 );
            foreach my $xml_file ( sort(@com_xml_files) ) {
                my $out_file = $xml_file;
                chmod( 0664, $out_file );
                $cleaner->process_file(
                    { file => $xml_file, out_file => $out_file } );
            }
        }

        if (    $type eq 'Set'
            and !defined( $self->{publican}->{config}->param('scm') )
            and defined( $self->{publican}->{config}->param('books') ) )
        {
            foreach my $xml_file ( sort(@xml_files) ) {
                my $out_file = $xml_file;
                $out_file =~ s/xml_tmp/xml/;
                rcopy( $xml_file, $out_file );
            }
            my @ent_files = dir_list( $lang, '*.ent' );
            foreach my $ent_file ( sort(@ent_files) ) {
                my $out_file = $ent_file;
                $out_file =~ s/$lang/$tmp_dir\/$lang\/xml/;
                rcopy( $ent_file, $out_file );
            }

        }
        else {
            foreach my $xml_file ( sort(@xml_files) ) {
                next if ( $xml_file =~ m{/extras/} );
                my $out_file = $xml_file;
                $out_file =~ s/xml_tmp/xml/;

                $cleaner->process_file(
                    { file => $xml_file, out_file => $out_file } );
            }
        }
        finddepth( \&del_unwanted_dirs, $tmp_dir );
    }

    return;

}

=head2 del_unwanted_dirs

Callback that deletes all unwanted directories from the given directory tree. Used to delete CVS and SVN files from the working directories.

=cut

sub del_unwanted_dirs {
    my $dir      = $_;
    my @unwanted = qw(  );

    if ( $dir =~ /^(CVS|\.svn|.*\.swp|.*\.xml~|.directory)$/ ) {
        rmtree($_)
            || croak(
            maketext(
                "couldn't remove unwanted dir '[_1]', error: [_2]",
                $_, $@
            )
            );
        return;
    }
    return;
}

=head2 del_unwanted_xml

Callback that deletes all unwanted xml from the given directory tree.

=cut

sub del_unwanted_xml {
    if ( $_ =~ /\.xml$/ ) {
        unlink($_)
            || croak(
            maketext(
                "couldn't unlink xml file '[_1]', error: [_2]", $_, $@
            )
            );
        return;
    }
    return;
}

=head2 validate_xml

Ensure the XML validates against the DTD.

To debug the XML catalogs

export XML_DEBUG_CATALOG=1

test...

unset XML_DEBUG_CATALOG

=cut

sub validate_xml {
    my ( $self, $args ) = @_;
    my $lang = delete( $args->{lang} )
        || croak( maketext("lang is a mandatory argument") );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    my $docname   = $self->{publican}->param('docname');
    my $dtdver    = $self->{publican}->param('dtdver');
    my $main_file = $self->{publican}->param('mainfile');

    if (   ( $self->{publican}->param('ignored_translations') )
        && ( $self->{publican}->param('ignored_translations') =~ m/$lang/ ) )
    {
        logger(
            maketext( "Bypassing test for language: [_1]", $lang ) . "\n" );
        return (0);
    }

    my $tmp_dir = $self->{publican}->param('tmp_dir');

    my $dir = pushd("$tmp_dir/$lang/xml");

    # 1.69 blows up if you pass some paramaters in
    my $parser;
    if ( $XML::LibXML::VERSION >= 1.70 ) {
        $parser = XML::LibXML->new(
            {   pedantic_parser   => 1,
                suppress_errors   => 0,
                suppress_warnings => 1,
                line_numbers      => 1,
                expand_xinclude   => 1
            }
        );
    }
    else {
        $parser = XML::LibXML->new();
        $parser->line_numbers(1);
        $parser->expand_xinclude(1);
    }

    croak(
        maketext( "Cannot locate main XML file: '[_1]'", "$main_file.xml" ) )
        unless ( -f "$main_file.xml" );

    my $source;
    eval { $source = $parser->parse_file("$main_file.xml"); };

    if ($@) {
        if ( ref($@) ) {

            # handle a structured error (XML::LibXML::Error object)
            croak(
                maketext(
                    "FATAL ERROR: [_1]:[_2] in [_3] on line [_4]: [_5]",
                    $@->domain(),
                    $@->code(),
                    $@->file(),
                    $@->line(),
                    $@->message(),
                )
            );
        }
        else {
            croak( maketext( "FATAL ERROR: [_1]", $@ ) );
        }
    }

## TODO should version be a variable?
    my $dtd_type = qq|-//OASIS//DTD DocBook XML V$dtdver//EN|;
    my $dtd_path
        = qq|http://www.oasis-open.org/docbook/xml/$dtdver/docbookx.dtd|;

    if ( $dtdver =~ m/^5/ ) {
        $dtd_type = qq|-//OASIS//DTD DocBook XML $dtdver//EN|;
        $dtd_path = qq|http://docbook.org/xml/$dtdver/rng/docbook.rng|;
    }

    if ( $^O eq 'MSWin32' ) {
        eval { require Win32::TieRegistry; };
        croak(
            maketext(
                "Failed to load Win32::TieRegistry module. Error: [_1]", $@
            )
        ) if ($@);

        my $key = new Win32::TieRegistry( "LMachine\\Software\\Publican",
            { Delimiter => "\\" } );
        if ( $key and $key->GetValue("dtd_path") ) {
            $dtd_path
                = 'file:///' . $key->GetValue("dtd_path") . '/docbookx.dtd';
            $dtd_path =~ s/ /%20/g;
            $dtd_path =~ s/\\/\//g;
        }
        else {
            $dtd_path = 'file:///C:/publican/DTD/docbookx.dtd';
        }
    }

    $dtd_type = $self->{publican}->param('dtd_type')
        if ( $self->{publican}->param('dtd_type') );
    $dtd_path = $self->{publican}->param('dtd_uri')
        if ( $self->{publican}->param('dtd_uri') );

    if ( $dtdver !~ m/^5/ ) {
        my $dtd = XML::LibXML::Dtd->new( $dtd_type, $dtd_path );

        unless ( $source->is_valid($dtd) ) {
            logger( maketext("DTD Validation failed: ") . "\n", RED );
            croak( $source->validate($dtd) );
        }
        logger("DTD Validation OK\n");
    }
    else {
## BUGBUG how does this get localised?
# e.g. even though /usr/share/xml/docbook5/schema/rng/5.0/catalog.xml contains a local link
# setting location = http://docbook.org/xml/5.0/rng/docbook.rng still does a web look up :(
## BUGBUG also need to change header ... entities?
# http://www.docbook.org/xml/5.1b2/rng/docbook.rng
# http://www.docbook.org/xml/5.0/rng/docbook.rng
# wget http://docbook.org/xml/5.1b2/tools/db4-upgrade.xsl
# for file in `ls *.xml`; do echo "$file"; xsltproc ../../db4-upgrade-publican.xsl $file > $file.tmp;mv $file.tmp $file; echo; done
        my $rngschema = XML::LibXML::RelaxNG->new(
            location => "http://docbook.org/xml/$dtdver/rng/docbook.rng" );
        eval { $rngschema->validate($source); };
        if ($@) {
            logger( maketext("RelaxNG Validation failed: ") . "\n", RED );
            croak($@);
        }
        logger("RelaxNG Validation OK\n");
    }

    $dir = undef;

    return (0);
}

=head2 transform

Run XSLT over XML

=cut

sub transform {
    my ( $self, $args ) = @_;

    my $lang = delete( $args->{lang} )
        || croak( maketext("lang is a mandatory argument") );
    my $format = delete( $args->{format} )
        || croak( maketext("format is a mandatory argument") );
    my $embedtoc = delete( $args->{embedtoc} ) || 0;
    my $rebuild  = delete( $args->{rebuild} )  || 0;

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    my $dir;
    my $lc_lang = $lang;
    $lc_lang =~ s/-/_/g;
    my $locale = Publican::Localise->get_handle($lc_lang)
        || croak(
        "Could not create a Publican::Localise object for language: [_1]",
        $lang );
    $locale->encoding("UTF-8");
    $locale->textdomain("publican");

## BUGBUG test an alternative to fop!
    my $wkhtmltopdf_cmd = which('wkhtmltopdf');
    my $diefopdie = ( $wkhtmltopdf_cmd && $wkhtmltopdf_cmd ne '' );

    my $tmp_dir           = $self->{publican}->param('tmp_dir');
    my $docname           = $self->{publican}->param('docname');
    my $common_config     = $self->{publican}->param('common_config');
    my $common_content    = $self->{publican}->param('common_content');
    my $brand             = $self->{publican}->param('brand');
    my $toc_section_depth = $self->{publican}->param('toc_section_depth');
    my $confidential      = $self->{publican}->param('confidential');
    my $confidential_text = $self->{publican}->param('confidential_text');
    my $show_remarks      = $self->{publican}->param('show_remarks');
    my $generate_section_toc_level
        = $self->{publican}->param('generate_section_toc_level');
    my $chunk_section_depth = $self->{publican}->param('chunk_section_depth');
    my $doc_url             = $self->{publican}->param('doc_url');
    my $prod_url            = $self->{publican}->param('prod_url');
    my $chunk_first         = $self->{publican}->param('chunk_first');
    my $xml_lang            = $self->{publican}->param('xml_lang');
    my $classpath           = $self->{publican}->param('classpath');
    my $type                = lc( $self->{publican}->param('type') );
    my $ec_name             = $self->{publican}->param('ec_name');
    my $ec_id               = $self->{publican}->param('ec_id');
    my $ec_provider         = $self->{publican}->param('ec_provider');
    my $product             = $self->{publican}->param('product');
    my $bridgehead_in_toc   = $self->{publican}->param('bridgehead_in_toc');
    my $main_file           = $self->{publican}->param('mainfile');
    my $brand_path          = $self->{publican}->param('brand_dir')
        || $common_content . "/$brand";
    my $web_type = $self->{publican}->param('web_type') || '';

    my $TAR_NAME
        = $self->{publican}->param('product') . '-'
        . $self->{publican}->param('docname') . '-'
        . $self->{publican}->param('version');
    my $RPM_VERSION = $self->{publican}->param('edition');

    my $RPM_RELEASE = $self->{publican}->param('release');

    my $pdf_name
        = $self->{publican}->param('product') . '-'
        . $self->{publican}->param('version') . '-'
        . $self->{publican}->param('docname') . '-'
        . "$lang.pdf";

    if ( $format eq 'txt' ) {
        if ( !-e "$tmp_dir/$lang/html-single" || $rebuild ) {
            $self->transform( { lang => $lang, format => 'html-single' } );
        }

        $dir = pushd("$tmp_dir/$lang");
        mkdir 'txt';
        my $TXT_FILE;
        open( $TXT_FILE, ">:encoding(UTF-8)", "txt/$docname.txt" )
            || croak( maketext("Can't open file for text output!") );
        my $tree = HTML::TreeBuilder->new();
        my $fh;
        open( $fh, "<:encoding(UTF-8)", "html-single/index.html" )
            || croak( maketext("Can't open file for html input!") );
        $tree->parse_file($fh);
## BZ #697363
        my $formatter = $self->{publican}->param('txt_formater') || '';

        if ( $formatter eq 'links' ) {
            my $f = HTML::FormatText::WithLinks->new();
            print( $TXT_FILE $f->parse( $tree->as_HTML() ) );

        }
        elsif ( $formatter eq 'tables' ) {
            print( $TXT_FILE HTML::FormatText::WithLinks::AndTables->convert(
                    $tree->as_HTML,
                    {   leftmargin   => 0,
                        rightmargin  => 72,
                        anchor_links => 0,
                        before_link  => ' [%n] '
                    }
                )
            );
        }
        else {
            my $f
                = HTML::FormatText->new( leftmargin => 0, rightmargin => 72 );
            print( $TXT_FILE $f->format($tree) );
        }

        close($TXT_FILE);
        $dir = undef;
        return;
    }

    my ( $web_product_label, $web_version_label, $web_name_label )
        = $self->web_labels( { lang => $lang, xml_lang => $xml_lang } );

    if ( $format eq 'pdf' && $diefopdie ) {
        if ( -d "$tmp_dir/$lang/html-pdf" ) {
            rmtree("$tmp_dir/$lang/html-pdf");
        }

        $self->transform( { lang => $lang, format => 'html-pdf' } );

        mkdir "$tmp_dir/$lang/pdf";

        my $header = "$common_config/book_templates/header.html";
        $header = "$brand_path/book_templates/header.html"
            if ( -f "$brand_path/book_templates/header.html" );

        my $footer = "$common_config/book_templates/footer.html";
        $footer = "$brand_path/book_templates/footer.html"
            if ( -f "$brand_path/book_templates/footer.html" );

        my @wkhtmltopdf_args = (
            $wkhtmltopdf_cmd, '--javascript-delay',
            0,                '--header-spacing',
            5,                '--footer-spacing',
            5,                '--margin-top',
            20,               '--margin-bottom',
            20,               '--margin-left',
            '15mm',           '--margin-right',
            '15mm',           '--header-html',
            $header,          '--footer-html',
            $footer
        );

        my $tmpl_path = "$common_config/book_templates";
        $tmpl_path = "$brand_path/book_templates:$tmpl_path"
            if ( -d "$brand_path/book_templates" );

        my $tconf = { INCLUDE_PATH => $tmpl_path, };
        my $template = Template->new($tconf)
            or croak( Template->error() );

        my $subtitle = $self->{publican}->get_subtitle( { lang => $lang } );
        $subtitle =~ s/"/\\"/g;
        $subtitle =~ s/\p{Z}+/ /g;
        chomp($subtitle);

        my $prod
            = $web_product_label
            ? $web_product_label
            : $self->{publican}->param('product');
        $prod =~ s/_/ /g;

        my $ver
            = $web_version_label
            ? $web_version_label
            : $self->{publican}->param('version');
        $ver =~ s/_/ /g;

        my $name
            = $web_name_label
            ? $web_name_label
            : $self->{publican}->param('docname');
        $name =~ s/_/ /g;

        my @authors = $self->{publican}->get_author_list( { lang => $lang } );
        my $contributors
            = $self->{publican}->get_contributors( { lang => $lang } );
        my $legalnotice
            = $self->{publican}->get_legalnotice( { lang => $lang } );
        my $abstract = $self->{publican}->get_abstract( { lang => $lang } );
        $abstract =~ s/\p{Z}+/ /g;

        my @keywords = $self->{publican}->get_keywords( { lang => $lang } );
        my $draft = $self->{publican}->get_draft( { lang => $lang } );

        my $vars = {
            draft        => $draft,
            product      => decode_utf8($prod),
            docname      => decode_utf8($name),
            version      => decode_utf8($ver),
            edition      => decode_utf8($self->{publican}->param('edition')),
            release      => decode_utf8($self->{publican}->param('release')),
            subtitle     => decode_utf8($subtitle),
            authors      => \@authors,
            editorlabel  => decode_utf8( $locale->maketext("Edited by") ),
            contributors => $contributors,
            contriblabel =>
                decode_utf8( $locale->maketext("With contributions from") ),
            legalnotice   => $legalnotice,
            legaltitle    => decode_utf8( $locale->maketext("Legal Notice") ),
            abstract      => $abstract,
            abstracttitle => decode_utf8( $locale->maketext("Abstract") ),
            keywords      => \@keywords,
            keywordtitle  => decode_utf8( $locale->maketext("Keywords") ),
            toctitle => decode_utf8( $locale->maketext("Table of Contents") ),
        };

        $template->process(
            'cover.tmpl', $vars,
            "$tmp_dir/$lang/html-pdf/cover.html",
            binmode => ':encoding(UTF-8)'
        ) or croak( $template->error() );

        push( @wkhtmltopdf_args,
            'cover', "$tmp_dir/$lang/html-pdf/cover.html" );

        #        $template->process(
        #            'titlepage.tmpl', $vars,
        #            "$tmp_dir/$lang/html-pdf/titlepage.html",
        #            binmode => ':encoding(UTF-8)'
        #        ) or croak( $template->error() );

        #        push( @wkhtmltopdf_args,
        #            'cover', "$tmp_dir/$lang/html-pdf/titlepage.html" );

        my $toc_xsl = "$tmp_dir/$lang/html-pdf/toc.xsl";

        $template->process( 'toc-xsl.tmpl', $vars, $toc_xsl,
            binmode => ':encoding(UTF-8)' )
            or croak( $template->error() );

##        my $toc_xsl = "$common_config/book_templates/toc.xsl";
##        $toc_xsl = "$brand_path/book_templates/toc.xsl"
##            if ( -f "$brand_path/book_templates/toc.xsl" );

        push(
            @wkhtmltopdf_args,
            'toc',
            '--xsl-style-sheet',
            $toc_xsl,
##            '--toc-header-text',
##            decode_utf8( $locale->maketext("Table of Contents") ),
            "$tmp_dir/$lang/html-pdf/index.html",
            "$tmp_dir/$lang/pdf/$pdf_name"
        );

        logger( "Running: " . join( " ", @wkhtmltopdf_args ) . "\n" );
        my $result = system(@wkhtmltopdf_args);
        if ($result) {
            croak(
                "\n",
                maketext(
                    'wkhtmltopdf died, PDF generation failed. Check log for details.'
                ),
                "\n"
            );
        }
        return;
    }

    my $xsl_file = $common_config . "/xsl/$format.xsl";
    $xsl_file = "$brand_path/xsl/$format.xsl"
        if ( -f "$brand_path/xsl/$format.xsl" );

    # required for Windows
    $xsl_file =~ s/"//g;

    my %xslt_opts = (
        'toc.section.depth'          => $toc_section_depth,
        'confidential'               => $confidential,
        'confidential.text'          => "'$confidential_text'",
        'profile.lang'               => "'$lang'",
        'l10n.gentext.language'      => "'$lang'",
        'show.comments'              => $show_remarks,
        'generate.section.toc.level' => $generate_section_toc_level,
        'use.extensions'             => 1,
        'tablecolumns.extensions'    => 1,
        'publican.version'           => "'$Publican::VERSION'",
        'bridgehead.in.toc'          => $bridgehead_in_toc,
        'body.only'                  => 0,
        'brand'                      => "'$brand'",
        'langpath'                   => "'$lang'",
        'book.type'                  => "'$type'",
        'web.type'                   => "'$web_type'",
##        '' => ,
    );

    mkdir "$tmp_dir/$lang/$format";

    my $pop_prod = $self->{publican}->param('product');
    my $pop_ver  = $self->{publican}->param('version');
    my $pop_name = $self->{publican}->param('docname');

    my $toc_path = '../../../..';
    $toc_path = '.' if ( $self->{publican}->param('web_home') );

    if ( $self->{publican}->param('web_type') ) {
        if ( $web_type =~ m/^home$/i ) {
            $toc_path = '.';
            $pop_prod = undef;
            $pop_ver  = undef;
            $pop_name = undef;
        }
        elsif ( $web_type =~ m/^product$/i ) {
            $toc_path = '..';
            $pop_ver  = undef;
            $pop_name = undef;
        }
        elsif ( $web_type =~ m/^version$/i ) {
            $toc_path = '../..';
            $pop_name = undef;
        }
        if (   $self->{publican}->param('web_type')
            && $self->{publican}->param('web_style') == 2 )
        {

            #            $xslt_opts{'body.only'} = 1;
        }
    }

    $xslt_opts{clean_title}
        = $web_name_label
        ? $web_name_label
        : $pop_name;

    $xslt_opts{clean_title} = $self->{publican}->param('docname')
        unless ( $xslt_opts{clean_title} );
    $xslt_opts{clean_title} = '"' . $xslt_opts{clean_title} . '"';
    $xslt_opts{clean_title} =~ s/_/ /g;

    if ( $format eq 'html-single' ) {

        $dir = pushd("$tmp_dir/$lang/$format");

        $xslt_opts{'doc.url'}  = "'$doc_url'";
        $xslt_opts{'prod.url'} = "'$prod_url'";
        $xslt_opts{'package'} = "'$TAR_NAME-$lang-$RPM_VERSION-$RPM_RELEASE'";
        $xslt_opts{'embedtoc'} = $embedtoc;
        $xslt_opts{'tocpath'}  = "'$toc_path'";
        $xslt_opts{'pop_prod'} = "'$pop_prod'" if ($pop_prod);
        $xslt_opts{'pop_ver'}  = "'$pop_ver'" if ($pop_ver);
        $xslt_opts{'pop_name'} = "'$pop_name'" if ($pop_name);
    }
    elsif ( $format eq 'html-pdf' ) {
        $dir = pushd("$tmp_dir/$lang/$format");
        my $title;

        $title
            = $web_product_label
            ? $web_product_label
            : $self->{publican}->param('product');
        $title .= ' ';
        $title .=
              $web_version_label
            ? $web_version_label
            : $self->{publican}->param('version');
        $title .= ' ';

        $title =~ s/_/ /g;

        $xslt_opts{'product'}    = "'$title'";
        $xslt_opts{'svg.object'} = "0";
        $xslt_opts{'doc.url'}    = "'$doc_url'";
        $xslt_opts{'prod.url'}   = "'$prod_url'";
        $xslt_opts{'package'} = "'$TAR_NAME-$lang-$RPM_VERSION-$RPM_RELEASE'";
        $xslt_opts{'tocpath'} = "'$toc_path'";
        $xslt_opts{'pop_prod'} = "'$pop_prod'" if ($pop_prod);
        $xslt_opts{'pop_ver'}  = "'$pop_ver'" if ($pop_ver);
        $xslt_opts{'pop_name'} = "'$pop_name'" if ($pop_name);
    }
    elsif ( $format eq 'html-desktop' ) {
        $xsl_file = $common_config . "/xsl/html-single.xsl";
        $xsl_file = "$brand_path/xsl/html-single.xsl"
            if ( -e "$brand_path/xsl/html-single.xsl" );
        $dir = pushd("$tmp_dir/$lang/$format");

        $xslt_opts{'doc.url'}  = "'$doc_url'";
        $xslt_opts{'prod.url'} = "'$prod_url'";
        $xslt_opts{'package'} = "'$TAR_NAME-$lang-$RPM_VERSION-$RPM_RELEASE'";
        $xslt_opts{'desktop'} = 1;

    }
    elsif ( $format eq 'html' ) {
        $dir = pushd("$tmp_dir/$lang/$format");

        $xslt_opts{'doc.url'}  = "'$doc_url'";
        $xslt_opts{'prod.url'} = "'$prod_url'";
        $xslt_opts{'package'} = "'$TAR_NAME-$lang-$RPM_VERSION-$RPM_RELEASE'";
        $xslt_opts{'embedtoc'}             = $embedtoc;
        $xslt_opts{'tocpath'}              = "'$toc_path'";
        $xslt_opts{'chunk.first.sections'} = $chunk_first;
        $xslt_opts{'chunk.section.depth'}  = $chunk_section_depth;
        $xslt_opts{'pop_prod'}             = "'$pop_prod'" if ($pop_prod);
        $xslt_opts{'pop_ver'}              = "'$pop_ver'" if ($pop_ver);
        $xslt_opts{'pop_name'}             = "'$pop_name'" if ($pop_name);
    }
    elsif ( $format eq 'drupal-book' ) {
        $dir                               = pushd("$tmp_dir/$lang/$format");
        $xslt_opts{'chunk.first.sections'} = $chunk_first;
        $xslt_opts{'chunk.section.depth'}  = $chunk_section_depth;
        $xslt_opts{'doc.url'}              = "'$doc_url'";
        $xslt_opts{'prod.url'}             = "'$prod_url'";
    }
    elsif ( ( $format =~ /^pdf/ ) and ( -f $xsl_file ) ) {
        $dir = pushd("$tmp_dir/$lang/xml");
    }
    elsif ( $format eq 'epub' ) {
        $dir = pushd("$tmp_dir/$lang/$format");
    }
    elsif ( $format eq 'eclipse' ) {
        $xslt_opts{'eclipse.plugin.name'}     = "'$ec_name'";
        $xslt_opts{'eclipse.plugin.id'}       = "'$ec_id'";
        $xslt_opts{'eclipse.plugin.provider'} = "'$ec_provider'";
        $dir = pushd("$tmp_dir/$lang/$format");
    }
    elsif ( $format eq 'man' ) {
        $dir = pushd("$tmp_dir/$lang/$format");
    }
    else {
        croak( maketext( "Unknown format: [_1]", $format ) );
    }

    # required for Windows
    $xsl_file =~ s/"//g;

    logger(
        "\t" . maketext( "Using XML::LibXSLT on [_1]", $xsl_file ) . "\n" );
    my $parser = XML::LibXML->new();
    my $xslt   = XML::LibXSLT->new();
    XML::LibXSLT->register_function( 'urn:perl', 'adjustColumnWidths',
        \&adjustColumnWidths );
    XML::LibXSLT->register_function( 'urn:perl', 'highlight', \&highlight );
    XML::LibXSLT->register_function( 'urn:perl', 'insertCallouts',
        \&insertCallouts );
    XML::LibXSLT->register_function( 'urn:perl', 'numberLines',
        \&numberLines );
    XML::LibXSLT->max_depth(1000);

    my $security = XML::LibXSLT::Security->new();
    $security->register_callback( create_dir => sub { 1; } );

    #    $security->register_callback(read_net => sub { 0; });
    $xslt->security_callbacks($security);

    $parser->expand_xinclude(1);
    $parser->expand_entities(1);

    my $source;
    eval { $source = $parser->parse_file("../xml/$main_file.xml"); };

    if ($@) {
        if ( ref($@) ) {

            # handle a structured error (XML::LibXML::Error object)
            croak(
                maketext(
                    "FATAL ERROR: [_1]:[_2] in [_3] on line [_4]: [_5]",
                    $@->domain(),
                    $@->code(),
                    $@->file(),
                    $@->line(),
                    $@->message(),
                )
            );
        }
        else {
            croak( maketext( "FATAL ERROR: [_1]", $@ ) );
        }
    }

    my $style_doc = $parser->parse_file($xsl_file);

## BUGBUG get Win32 working with Publican::ConfigData
    if ( $^O eq 'MSWin32' ) {
        eval { require Win32::TieRegistry; };
        croak(
            maketext(
                "Failed to load Win32::TieRegistry module. Error: [_1]", $@
            )
        ) if ($@);

        my $defualt_href
            = 'http://docbook.sourceforge.net/release/xsl/current';
        my $key = new Win32::TieRegistry( "LMachine\\Software\\Publican",
            { Delimiter => "\\" } );

        my $new_href = 'file:///C:/publican/docbook-xsl-1.76.1';
        if ( $key and $key->GetValue("xsl_path") ) {
            $new_href = 'file:///' . $key->GetValue("xsl_path");
            $new_href =~ s/ /%20/g;
            $new_href =~ s/\\/\//g;
        }

        my @nodelist = $style_doc->getElementsByTagName('xsl:import');
        foreach my $node (@nodelist) {
            my $href = $node->getAttribute('href');
            debug_msg("changing $defualt_href to $new_href\n");
            $href =~ s|$defualt_href|$new_href|;
            $node->setAttribute( 'href', $href );
        }
    }

    my $stylesheet = $xslt->parse_stylesheet($style_doc);
    my $results = $stylesheet->transform( $source, %xslt_opts );

    if ( $format =~ /^pdf/ ) {
        eval { $stylesheet->output_file( $results, "$docname.fo" ) };
    }
    elsif ( $format =~ /^html-/ ) {    # html-single and html-desktop html-pdf
        eval { $stylesheet->output_file( $results, "index.html" ) };
    }
    else {                             # html
        eval { $stylesheet->output_string($results) };
    }

    croak( maketext( "Transformation error '[_1]' : [_2]", $!, $@ ) ) if $@;

    if ( $format =~ /^pdf/ ) {
        my $fop_command
            = qq|CLASSPATH="$classpath" fop -q -c $common_config/fop/fop.xconf -fo $docname.fo -pdf ../pdf/$pdf_name|;

## TODO find out if we need to set classpath on windows and how
        if ( $^O eq 'MSWin32' ) {
            $fop_command
                = qq|fop -q -c $common_config/fop/fop.xconf -fo $docname.fo -pdf ../pdf/$pdf_name|;
        }

        if ( system($fop_command) != 0 ) {
            croak(
                "\n",
                maketext(
                    "FOP error, PDF generation failed. Check log for details."
                ),
                "\n"
            );
        }

        $dir = undef;
    }
    elsif ( $format eq 'epub' ) {
        $dir = undef;
        dircopy( "$tmp_dir/$lang/xml/images",
            "$tmp_dir/$lang/$format/OEBPS/images" );
        dircopy(
            "$tmp_dir/$lang/xml/Common_Content",
            "$tmp_dir/$lang/$format/OEBPS/Common_Content"
        );
##        dircopy( "$xml_lang/files", "$tmp_dir/$lang/$format/OEBPS/files" )
##            if ( -e "$xml_lang/files" );
##        dircopy( "$lang/files", "$tmp_dir/$lang/$format/OEBPS/files" )
##            if ( -e "$lang/files" );

##        mkpath("$tmp_dir/$lang/$format/OEBPS/Common_Content/css");
##        fcopy(
##            "$tmp_dir/$lang/xml/Common_Content/css/print.css",
##            "$tmp_dir/$lang/$format/OEBPS/Common_Content/css/print.css"
##        );
##        mkpath("$tmp_dir/$lang/$format/OEBPS/Common_Content/images");
##        fcopy(
##            "$tmp_dir/$lang/xml/Common_Content/images/title_logo.svg",
##            "$tmp_dir/$lang/$format/OEBPS/Common_Content/images/title_logo.svg"
##        );
        unlink("$tmp_dir/$lang/$format/OEBPS/images/icon.svg");

        unless (
            -f "$tmp_dir/$lang/$format/OEBPS/Common_Content/css/lang.css" )
        {
            my $OUTDOC;
            open( $OUTDOC, ">:encoding(UTF-8)",
                "$tmp_dir/$lang/$format/OEBPS/Common_Content/css/lang.css" )
                || croak(
                maketext(
                    "Could not open [_1] for output!",
                    "\$tmp_dir/\$lang/\$format/OEBPS/Common_Content/css/lang.css"
                )
                );
            close($OUTDOC);
        }
        unless (
            -f "$tmp_dir/$lang/$format/OEBPS/Common_Content/css/overrides.css"
            )
        {
            my $OUTDOC;
            open( $OUTDOC, ">:encoding(UTF-8)",
                "$tmp_dir/$lang/$format/OEBPS/Common_Content/css/overrides.css"
                )
                || croak(
                maketext(
                    "Could not open [_1] for output!",
                    "\$tmp_dir/\$lang/\$format/OEBPS/Common_Content/css/lang.css"
                )
                );
            close($OUTDOC);
        }

        # remove any RCS from the output
        finddepth( \&del_unwanted_dirs, "$tmp_dir/$lang/$format" );

        # remove any XML files from common
        finddepth( \&del_unwanted_xml,
            "$tmp_dir/$lang/$format/OEBPS/Common_Content" );

        my @files
            = dir_list( "$tmp_dir/$lang/$format/OEBPS/Common_Content", '*' );
        my $content_file = "$tmp_dir/$lang/$format/OEBPS/content.opf";
        my $tree         = XML::TreeBuilder->new(
            { 'NoExpand' => "1", 'ErrorContext' => "2" } );
        $tree->parse_file("$content_file");
        my $node;
        eval { $node = $tree->look_down( '_tag', "manifest" ); };
        if ( $@ or !$node ) {
            croak( maketext("manifest not found") );
        }

        foreach my $file (@files) {
            next
                if ( $file =~ /title_logo.svg/
                || $file =~ /print.css/
                || $file =~ /default.css/ );
            $file =~ s/^.*OEBPS\///g;
            $file =~ /(...)$/;
            my $ext = $1;
            my $id  = $file;
            $id =~ s/\//-/g;
            $node->push_content(
                [   'item',
                    {   href         => "$file",
                        'media-type' => "image/$ext",
                        id           => $id
                    }
                ]
            );
        }

        my $OUTDOC;
        open( $OUTDOC, ">:encoding(UTF-8)", "$content_file" )
            || croak(
            maketext( "Could not open [_1] for output!", $content_file ) );
        my $text = $tree->as_XML();
        $text =~ s/&#34;/"/g;
        $text =~ s/&#39;/'/g;
        $text =~ s/&quot;/"/g;
        $text =~ s/&apos;/'/g;
        print( $OUTDOC $text );
        close($OUTDOC);

        my $MIME;
        open( $MIME, ">", "$tmp_dir/$lang/$format/mimetype" )
            || croak( maketext("Can't open mimetype file: ") );
        print( $MIME 'application/epub+zip' );
        close($MIME);

        $dir = pushd("$tmp_dir/$lang/$format");

        my $zip = Archive::Zip->new();

        my $mimetype = $zip->addFile("mimetype");
        $mimetype->desiredCompressionMethod(COMPRESSION_STORED);

        my $member = $zip->addDirectory("OEBPS/");
        $member = $zip->addDirectory("META-INF/");

        my @filelist = File::Find::Rule->file->not_name('mimetype')->in(".");
        foreach my $file (@filelist) {
            $member = $zip->addFile($file);
        }

        my $epub_name
            = $self->{publican}->param('product') . '-'
            . $self->{publican}->param('version') . '-'
            . $self->{publican}->param('docname') . '-'
            . "$lang.epub";
        $self->{epub_name} = $epub_name;
        $zip->writeToFileNamed("../$epub_name") == AZ_OK
            || croak( maketext("epub creation failed.") );
        logger(
            maketext( "Wrote epub archive: [_1]",
                "$tmp_dir/$lang/$epub_name" )
                . "\n"
        );
        $dir = undef;
    }
    elsif ( $format eq 'man' ) {

        # NO-OP?
    }
    elsif ( $format eq 'drupal-book' ) {
        $dir = undef;

        my $docname = $self->{publican}->param('docname');
        my $product = $self->{publican}->param('product');
        my $version = $self->{publican}->param('version');
        my $edition = $self->{publican}->param('edition');
        my $release = $self->{publican}->param('release');

        my $filename = "$product-$version-$docname-$lang-$edition-$release";
        my $content_dir = "$lang/$product/$version/$docname";

        $self->drupal_transform( { lang => $lang } );

        dircopy( "$tmp_dir/$lang/xml/images",
            "$tmp_dir/$lang/$format/$content_dir/images" );
        dircopy( "$tmp_dir/$lang/xml/Common_Content/images",
            "$tmp_dir/$lang/$format/$content_dir/Common_Content/images" )
            if ( $embedtoc == 0 );

        dircopy( "$xml_lang/files",
            "$tmp_dir/$lang/$format/$content_dir/files" )
            if ( -e "$xml_lang/files" );
        dircopy( "$lang/files", "$tmp_dir/$lang/$format/$content_dir/files" )
            if ( -e "$lang/files" );

        # remove any RCS from the output
        finddepth( \&del_unwanted_dirs, "$tmp_dir/$lang/$format" );

        $dir = pushd("$tmp_dir/$lang/$format");

        # remove all html files
        my @htmls = glob "*.html";
        foreach (@htmls) {
            unlink($_);
        }

        print "Zipping $filename.tar.gz\n";
        system("tar -czf $filename.tar.gz ./$filename.csv ./$lang")
            && croak( maketext("Failed to zip $filename.tar.gz\n") );

        $dir = undef;
    }
    else {
        $dir = undef;
        dircopy( "$tmp_dir/$lang/xml/images",
            "$tmp_dir/$lang/$format/images" );
        dircopy(
            "$tmp_dir/$lang/xml/Common_Content",
            "$tmp_dir/$lang/$format/Common_Content"
            )
            if ( $embedtoc == 0
            || $format eq 'html-desktop'
            || $format eq 'html-pdf' );
        dircopy( "$xml_lang/files", "$tmp_dir/$lang/$format/files" )
            if ( -e "$xml_lang/files" );
        dircopy( "$lang/files", "$tmp_dir/$lang/$format/files" )
            if ( -e "$lang/files" );

        # remove any RCS from the output
        finddepth( \&del_unwanted_dirs, "$tmp_dir/$lang/$format" );

        # remove any XML files from common
        finddepth( \&del_unwanted_xml,
            "$tmp_dir/$lang/$format/Common_Content" )
            if ( $embedtoc == 0
            || $format eq 'html-desktop'
            || $format eq 'html-pdf' );
    }

    $xslt       = undef;
    $source     = undef;
    $style_doc  = undef;
    $stylesheet = undef;
    $parser     = undef;

## TODO BUGBUG freeing $results goes BOOM on windows
## TODO requires testing since the other crashbug is resolved
    $results = undef;

    return;
}

=head2 drupal_transform

Write csv file for drupal node import

=cut

sub drupal_transform {
    my ( $self, $args ) = @_;

    my $lang = delete $args->{lang}
        || croak maketext(
        "lang is the mandatory argument for drupal_transform");

    my $tmp_dir    = $self->{publican}->param('tmp_dir');
    my $main_file  = $self->{publican}->param('mainfile');
    my $docname    = $self->{publican}->param('docname');
    my $product    = $self->{publican}->param('product');
    my $version    = $self->{publican}->param('version');
    my $edition    = $self->{publican}->param('edition');
    my $release    = $self->{publican}->param('release');
    my $xml_lang   = $self->{publican}->param('xml_lang');
    my $drupal_dir = "$tmp_dir/$lang/drupal-book";

    my $parser = XML::LibXML->new();
    $parser->expand_xinclude(1);
    $parser->expand_entities(1);

    my $source;
    eval {
        $source = $parser->parse_file("$tmp_dir/$lang/xml/$main_file.xml");
    };

    my %all_nodes;
    my %section_maps;
    my $nodes_order = $self->get_nodes_order(
        {   source       => $source,
            section_maps => \%section_maps,
            all_nodes    => \%all_nodes
        }
    );

    my @csv_headers = (
        "Title",
        "Book",
        "Parent item",
        "Weight",
        "Menu link title",
        "Alias for node which should be used as parent menu",
        "Body",
        "Input format",
        "Authored By",
        "Published",
        "URL path settings",
    );

    my $csv_file = "$product-$version-$docname-$lang-$edition-$release.csv";

    print "Writing $csv_file\n";

    my $xs
        = Text::CSV_XS->new( { binary => 1, always_quote => 1, eol => $/ } );

    open my $fh, ">:encoding(utf8)", "$drupal_dir/$csv_file"
        || croak "$drupal_dir/$csv_file: $!";

    $xs->combine(@csv_headers);
    $fh->print( $xs->string );

    my $outputs = $self->build_drupal_book(
        {   lang         => $lang,
            nodes_order  => $nodes_order,
            section_maps => \%section_maps,
            all_nodes    => \%all_nodes
        }
    );

    foreach my $row ( @{$outputs} ) {
        $xs->combine( @{$row} ) or $xs->error_diag;
        $fh->print( $xs->string );
    }

    $fh->close();
    $self->{dbh}->disconnect()
        if ( defined $self->{dbh} );

    return;
}

=head2 get_nodes_order

Get all nodes with id from xml files in order

=cut

sub get_nodes_order {
    my ( $self, $args ) = @_;

    my $source = delete( $args->{source} )
        || croak( maketext("source is a mandatory argument") );

    my $node         = delete( $args->{node} )         || undef;
    my $section_maps = delete( $args->{section_maps} ) || {};
    my $all_nodes    = delete( $args->{all_nodes} )    || {};
    my $check_dups   = delete( $args->{check_dups} )   || {};

    my %order;
    my @node_list;

    if ( !$node ) {
        @node_list = $source->getElementsByTagName('book')->[0]->childNodes();
    }
    else {
        @node_list = $node->childNodes();
    }

    my $count = 0;
    foreach my $cnode (@node_list) {
        if ( $cnode->nodeName() eq 'index' ) {
            $order{ ++$count }{'id'} = "ix01";
            $order{$count}{'type'} = "index";
        }

    # $cnode->attributes will return namespace too, so we need to skip it here
        next if ( !$cnode->hasAttributes() );

        my $unique_id = undef;
        foreach my $cnode_attr ( $cnode->attributes() ) {
            if ( $cnode_attr->name() eq "conformance" ) {
                $unique_id = $cnode_attr->getValue();

                #print "$unique_id\n";
            }

            if ( $cnode_attr && $cnode_attr->isId ) {
                my $value = $cnode_attr->getValue();
                $order{ ++$count }{'id'} = $value;
                $order{$count}{'type'} = $cnode->nodeName();
                $section_maps->{$value} = $unique_id || $value;

                if ( defined $unique_id ) {

                    croak(
                        maketext(
                            "Duplicate conformance value in section $value which value = $unique_id."
                        )
                    ) if ( defined $check_dups->{$unique_id} );

                    $check_dups->{$unique_id} = 1;
                }

#|| croak ( maketext("missing 'conformance' attribute in $order{$count}{type} where id is $value") );
                $all_nodes->{$value} = 1;
                my $child_nodes = $self->get_nodes_order(
                    {   source       => $source,
                        node         => $cnode,
                        section_maps => $section_maps,
                        all_nodes    => $all_nodes,
                        check_dups   => $check_dups,
                    }
                );
                $order{$count}{'childs'} = $child_nodes
                    if ( %{$child_nodes} );
            }
        }
    }
    return \%order;
}

=head2 build_drupal_book

Convert each html file into csv a row for drupal.

=cut

sub build_drupal_book {
    my ( $self, $args ) = @_;

    my $lang = delete( $args->{lang} )
        || croak(
        maketext("lang is a mandatory argument for build_drupal_book") );

    my $nodes_order = delete( $args->{nodes_order} )
        || croak(
        maketext("nodes_order is a mandatory argument for build_drupal_book")
        );

    my $section_maps = delete $args->{section_maps} || {};
    my $all_nodes    = delete $args->{all_nodes}    || {};

    my $parent       = delete $args->{parent}       || "";
    my $parent_alias = delete $args->{parent_alias} || "";

    my $tmp_dir    = $self->{publican}->param('tmp_dir');
    my $docname    = $self->{publican}->param('docname');
    my $product    = $self->{publican}->param('product');
    my $version    = $self->{publican}->param('version');
    my $author     = $self->{publican}->param('drupal_author');
    my $book_title = $self->{publican}->param('drupal_menu_title');
    my $menu_block = $self->{publican}->param('drupal_menu_block');
    my $img_path   = $self->{publican}->param('drupal_image_path');

    $menu_block = ($menu_block) ? "menu-$menu_block" : "";

    my $bookname     = "$product-$version-$docname-$lang";
    my $drupal_dir   = "$tmp_dir/$lang/drupal-book";
    my $resource_dir = "$lang/$product/$version/$docname";

    my @outputs;
    my $weight        = -16;
    my $previous_type = "";
    foreach my $order_num ( sort { $a <=> $b } keys %{$nodes_order} ) {

        my $page
            = ( $nodes_order->{$order_num}{'id'} =~ /^book\-/ )
            ? 'index'
            : $nodes_order->{$order_num}{'id'};
        my $file_name = "$drupal_dir/$page.html";

        if ( -e $file_name ) {
            my @csv_row;
            my $tree = HTML::TreeBuilder->new();

            open my $html_file, "<:encoding(utf8)", $file_name
                or croak "$file_name: $!";

            $tree->parse_file($html_file);
            $html_file->close();

            my $title_element = $tree->look_down( '_tag', 'title' );
            my $title = $title_element->as_trimmed_text;

            #delete html head
            my $head_element = $tree->look_down( '_tag', 'head' );
            $head_element->delete();

            my $delete_first_header = 1;
            my %header_tags = ( h1 => 1, h2 => 1, h3 => 1, h4 => 1, h5 => 1 );

            $tree->traverse(
                [    # Callbacks;
                        # pre-order callback:
                    sub {
                        my $node = $_[0];
                        my $tag  = $node->{'_tag'};

              # only delete the first header tag because it is already showing
              # in the drupal title
                        if ( defined $header_tags{$tag}
                            && $delete_first_header == 1 )
                        {
                            $node->delete();
                            $delete_first_header = 0;
                        }

                        if (   defined $node->attr('id')
                            && defined $section_maps->{ $node->attr('id') } )
                        {
                            my $id = $node->attr('id');
                            $node->attr( 'id', $section_maps->{$id} );
                        }

                        if ( $tag eq 'img' && defined $node->attr('src') ) {
                            my $old_value = $node->attr('src');
                            $node->attr( 'src',
                                "$img_path$resource_dir/" . $old_value )
                                if ($old_value);
                        }

                        if (   $tag eq 'object'
                            && defined $node->attr('type')
                            && $node->attr('type') eq 'image/svg+xml' )
                        {
                            my $old_value = $node->attr('data') || undef;
                            $node->attr( 'data',
                                "$img_path$resource_dir/" . $old_value )
                                if ($old_value);
                        }

                        if ( $tag eq 'a' && defined $node->attr('href') ) {
                            my $old_value = $node->attr('href');
                            if ($old_value) {
                                my @links;
                                my $update_link = 0;
                                @links = split( '#', $old_value );

                                for ( my $i = 0; $i < @links; $i++ ) {
                                    next if ( !$links[$i] );
                                    $links[$i] =~ s/\.html$//;
                                    if (defined $section_maps->{ $links[$i] }
                                        )
                                    {
                                        $links[$i]
                                            = $section_maps->{ $links[$i] };
                                        $update_link = 1;
                                    }

                                    unless ($update_link) {

                                        # check if it is internal page
                                        if (defined $all_nodes->{ $links[$i] }
                                            )
                                        {
                                            $update_link = 1;
                                        }
                                    }

                                    if ( $links[$i] eq 'ix01' ) {
                                        $links[$i] = 'index';
                                        $update_link = 1;
                                    }
                                }

                                if ($update_link) {
                                    $old_value = join( '#', @links );
                                    $node->attr( 'href',
                                        "?q=$bookname-" . $old_value );
                                    $update_link = 0;
                                }

                                #else {
                                #print ">>$old_value>> not found\n";
                                #}
                            }
                        }

                        return HTML::Element::OK;    # keep traversing
                    },

                    # post-order callback:
                    undef
                ],
                1,    # don't call the callbacks for text nodes
            );

            my $alias = "$bookname-$page";
            my $section_weight
                = { preface => 1, chapter => 2, appendix => 3 };

            #if ($previous_type ne $nodes_order->{$order_num}{'type'}) {
            if ( $weight < 30 ) {
                $weight++;
            }
            else {
                logger(
                    maketext(
                        "Reached the maximum page ordering weight(30) that drupal can support. The rest of the pages will be ordered in alphabetical order\n"
                    ),
                    RED
                );
            }

            #}

            my $menu_link  = "";
            my $menu_title = "";
            my $book
                = ($book_title) ? $book_title : "$product $version $docname";
            if ( $page eq 'index' ) {
                $alias      = $bookname;
                $title      = $book;
                $menu_title = $book;
                $menu_link  = $menu_block;
                $book       = "";
            }
            elsif ( $page eq 'ix01' ) {
                $alias = "$bookname-index";
            }
            else {
                $alias = "$bookname-$section_maps->{$page}"
                    || croak( maketext("Fail to get the mapping for $page") );
            }

            $title =~ s/\s+/ /g;
            my $html_string = $tree->as_HTML;
            $html_string
                =~ s/^\<\!DOCTYPE html PUBLIC \"\-\/\/W3C\/\/DTD.*\.dtd\"\>\n*//;
            $html_string =~ s/\<html.*\>\s*\<body\>//;
            $html_string =~ s/\<\/body\>//;
            $html_string =~ s/\<\/html\>//;

            push @csv_row, $title;
            push @csv_row, $book;
            push @csv_row, $parent;
            push @csv_row, $weight;
            push @csv_row, $menu_title;
            push @csv_row, $menu_link;
            push @csv_row, $html_string;
            push @csv_row, 2;
            push @csv_row, $author;
            push @csv_row, 'TRUE';
            push @csv_row, $alias;

            push @outputs, \@csv_row;

            if ( defined $nodes_order->{$order_num}{'childs'} ) {
                my $child_outputs = $self->build_drupal_book(
                    {   lang         => $lang,
                        nodes_order  => $nodes_order->{$order_num}{'childs'},
                        section_maps => $section_maps,
                        parent       => $title,
                        parent_alias => $alias,
                    }
                );
                push @outputs, @{$child_outputs};
            }

            $previous_type = $nodes_order->{$order_num}{'type'};
        }
    }

    return \@outputs;
}

=head2 clean_ids

Travers over the source XML and update the id's to match the standard format.

Updates all existing PO files with the new xref links.

=cut

sub clean_ids {
    my ( $self, $args ) = @_;

    #    if ( %{$args} ) {
    #        croak "unknown args: " . join( ", ", keys %{$args} );
    #    }

    my @xml_files = dir_list( $self->{publican}->param('xml_lang'), '*.xml' );
    my $cleaner = Publican::XmlClean->new( { clean_id => 1 } );

    foreach my $xml_file ( sort(@xml_files) ) {
        next if ( $xml_file =~ m{/extras/} );
        $cleaner->process_file(
            { file => $xml_file, out_file => $xml_file } );
    }

    return;
}

=head2  adjustColumnWidths

Adjust column widths for XML Tables. Converts hard coded and relative withs to percentages.

Based on xsl-stylesheets-1.74.3/html/dtbl.xsl

 Get all the colwidth, NULL == * == 1*
 Convert $table_width to pt
 Convert all hard coded widths to pt
 $total_relative_width = $table_width
 subtract hard coded widths from $total_relative_width
 convert hard coded withs to a % of $table_width
 total all relative widths
 convert relative widths to a proportion of $total_relative_width
 convert relative widths to a % of $table_width

FO input:

"<?xml version=\"1.0\"?>\n<fo:table-column xmlns:fo=\"http://www.w3.org/1999/XSL/Format\" column-number=\"1\" column-width=\"1*\"/>\n<fo:table-column xmlns:fo=\"http://www.w3.org/1999/XSL/Format\" column-number=\"2\" column-width=\"2*\"/>\n<fo:table-column xmlns:fo=\"http://www.w3.org/1999/XSL/Format\" column-number=\"3\" column-width=\"1*\"/>\n<fo:table-column xmlns:fo=\"http://www.w3.org/1999/XSL/Format\" column-number=\"4\" column-width=\"3*\"/>\n"


HTML input:

"<?xml version=\"1.0\"?>\n<colgroup xmlns=\"http://www.w3.org/1999/xhtml\"><col width=\"1*\"/><col width=\"2*\"/><col width=\"1*\"/><col width=\"3*\"/></colgroup>\n"

Returns: modified input tree which is XHTML or XML:FO

=cut

sub adjustColumnWidths {

    my $width   = shift();
    my $content = shift();

    my $table_width = $width->string_value();

    debug_msg(
        "TODO: adjustColumnWidths function is not fully implemented!\n");

    # XML::LibXML::Document
    my $doc       = $content->get_node(1);
    my $childnode = $doc->firstChild;

    # HTML
    my $tagname        = 'col';
    my $width_tag      = 'width';
    my $perc_remaining = 100;

    # PDF
    if ( $childnode->nodeName() eq 'fo:table-column' ) {
        $tagname   = 'fo:table-column';
        $width_tag = 'column-width';
    }

    my @widths = ();
    my ( $prop, $perc, $exact, $total_prop ) = ( 0, 0, 0, 0 );

    # $node is XML::LibXML::Element
    foreach my $node ( $doc->getElementsByTagName($tagname) ) {

        # $width is XML::LibXML::Attr
        my $width = $node->getAttribute($width_tag) || '1*';
        if ( $width =~ m/^(\d+)\*$/ ) {
            $prop++;
            $total_prop += $1;
        }
        elsif ( $width =~ m/^(\d+)\%$/ ) {
            $perc++;
            $perc_remaining -= $1;
        }
        elsif ( $width =~ m/^(\d+)(cm|mm|in|pc|pt|px)$/ ) {
            logger( "TODO: convert exact to % of table_width", RED );
            debug_msg(
                "TODO: consider limiting this to matching same units as table_width"
            );
            $exact++;
        }
        else {
            logger(
                maketext( "Unknown width format will be ignored: [_1]",
                    $width )
                    . "\n",
                RED
            );
            $width = '1*';
            $prop++;
            $total_prop += 1;
        }

        push( @widths, "$width" );
    }

    for ( my $i = 0; $i < @widths; $i++ ) {
        my $width = $widths[$i];

        if ( $width =~ m/^(\d+)\*$/ ) {
            $width
                = floor(
                ( ( $1 / $total_prop ) * ( $perc_remaining / 100 ) * 100 )
                + 0.5 )
                . '%';

        }
        elsif ( $width =~ m/^(\d+)(pt)$/ ) {
            debug_msg("TODO: convert exact to %");
        }

        $widths[$i] = $width;
    }

    my $i = 0;
    foreach my $node ( $doc->getElementsByTagName($tagname) ) {
        $node->setAttribute( $width_tag, $widths[$i] );
        $i++;
    }

    return ($content);
}

=head2  highlight

perl_highlight syntax highlighting

Edit highlight_color template in pdf.xsl and .perl_XXX in CSS to change highlight colours

Returns: Modified input tree, which is DocBook XML.

=cut

sub highlight {
    my $lang    = shift();
    my $content = shift();

    my $language = $lang->string_value();

##debug_msg("Highlighting $language\n");

    my $hl = new Syntax::Highlight::Engine::Kate(
        substitutions => {
            "<" => "&lt;",
            ">" => "&gt;",
            "&" => "&amp;",
        },
        format_table => {
            Alert        => [ "<perl_Alert>",        "</perl_Alert>" ],
            BaseN        => [ "<perl_BaseN>",        "</perl_BaseN>" ],
            BString      => [ "<perl_BString>",      "</perl_BString>" ],
            Char         => [ "<perl_Char>",         "</perl_Char>" ],
            Comment      => [ "<perl_Comment>",      "</perl_Comment>" ],
            DataType     => [ "<perl_DataType>",     "</perl_DataType>" ],
            DecVal       => [ "<perl_DecVal>",       "</perl_DecVal>" ],
            Error        => [ "<perl_Error>",        "</perl_Error>" ],
            Float        => [ "<perl_Float>",        "</perl_Float>" ],
            Function     => [ "<perl_Function>",     "</perl_Function>" ],
            IString      => [ "<perl_IString>",      "</perl_IString>" ],
            Keyword      => [ "<perl_Keyword>",      "</perl_Keyword>" ],
            Normal       => [ "",                    "" ],
            Operator     => [ "<perl_Operator>",     "</perl_Operator>" ],
            Others       => [ "<perl_Others>",       "</perl_Others>" ],
            RegionMarker => [ "<perl_RegionMarker>", "</perl_RegionMarker>" ],
            Reserved     => [ "<perl_Reserved>",     "</perl_Reserved>" ],
            String       => [ "<perl_String>",       "</perl_String>" ],
            Variable     => [ "<perl_Variable>",     "</perl_Variable>" ],
            Warning      => [ "<perl_Warning>",      "</perl_Warning>" ],
        },
    );

    my $tmp = $hl->languagePlug($language) || croak(
        "\n\t"
            . maketext(
            "'[_1]' is not a valid language for highlighting. Language names are case sensitive.",
            $language
            )
            . "\n"
    );
    $hl->language($language);

    my $parser = XML::LibXML->new();

## BUGBUG testing https://bugzilla.redhat.com/show_bug.cgi?id=604255
##    my $test = $content->get_node(1);
##    my $in_string = $test->toString();
##    $in_string =~ s/^<\?xml version="1.0"\?>\n//gm;
##debug_msg("Highlighting: " . $in_string . "\n") if $language eq 'C++';

    $parser->expand_entities(0);
    my $out_string = $hl->highlightText( $content->string_value() );

##debug_msg("Highlighting: $out_string\n");

    # this gives an XML::LibXML::DocumentFragment
    my $list = $parser->parse_balanced_chunk($out_string);

    # remove the input node
    $content->shift;

    # append the marked-up nodes
    foreach my $node ( $list->childNodes() ) {
        $content->push($node);
    }

    return ($content);
}

=head2 insertCallouts

XSLT callout function for inserting Callout markup in to verbatim text.

Parameters:
	areaspec: the DocBook areaspec node set
	verbatim: the XHTML/XML:FO tree to place gfx in

Returns: modified $verbatim

BUGBUG: BZ #561618
BUGBUG: The approach taken here does not work for tagged content in the verbatim.
BUGBUG: Need to walk the node tree in childnode instead of using it as a string.
BUGBUG: make sure class is being set

=cut

sub insertCallouts {
    my $areaspec = shift();
    my $verbatim = shift();

    # XML::LibXML::Document
    my $doc = $areaspec->get_node(1);

    my $verb      = $verbatim->get_node(1);
    my $childnode = $verb->firstChild;

    my $mode   = 'gfx';
    my $format = 'HTML';
    my $tag    = $childnode->nodeName();

    # PDF
    if ( $tag eq 'fo:block' ) {
        $format = 'PDF';
    }

# This is a hash of arrays, key is line number, array contains indexes on that line.
    my %callout;

    my $index = 0;

    # $node is XML::LibXML::Element
    foreach my $node ( $doc->childNodes() ) {
        if ( $node->nodeName() eq 'areaset' ) {
            $index++;
            foreach my $child ( $node->childNodes() ) {
                if ( $child->nodeName() eq 'area' ) {
                    my $pos = 0;
                    my $col = $child->getAttribute('coords')
                        || carp(
                        maketext("'area' requires a 'coords' attribute.") );
                    if ( $col =~ m/^(\d+)\s+(\d+)$/ ) {
                        $col = $1;
                        $pos = $2;
                    }

                    push( @{ $callout{$col}{lines} }, $index );
                    $callout{$col}{'pos'} = $pos;
                }
            }
        }
        elsif ( $node->nodeName() eq 'area' ) {
            $index++;
            my $pos = 0;
            my $col = $node->getAttribute('coords')
                || carp( maketext("'area' requires a 'coords' attribute.") );

            if ( $col =~ m/^(\d+)\s+(\d+)$/ ) {
                $col = $1;
                $pos = $2;
            }

            push( @{ $callout{$col}{lines} }, $index );
            $callout{$col}{'pos'} = $pos;
        }
    }

    my $in_string = $childnode->string_value();
    my $out_node  = XML::LibXML::Element->new( $childnode->nodeName() );

    my $out_string = '';
    my $count      = 0;
    my $position   = 40;

    my $parser = XML::LibXML->new();
    $parser->expand_entities(0);

    my $test       = $verb->toString();
    my $line_count = 0;

    # calculate numer of lines
    my $io = IO::String->new($test);
    while (<$io>) {
        $line_count++;
    }

    # calculate longest line
    $io    = IO::String->new($test);
    $count = -1;
    while (<$io>) {
        $count++;
        my $line = $_;
        chomp($line);

        # skip first line, which has xml decl
        if ( $count == 0 ) { next; }

        # skip last line, which is close tag
        if ( $count == $line_count - 1 ) { next; }

        my $fline = "";

        if ( $line !~ /^$/ ) {

            # for first node add close tag
## BUGBUG this will break if there are nested block tags
            my $node;
            if ( $count == 1 ) {
                $node = $parser->parse_xml_chunk( $line . "</$tag>" );
            }
            else {

                # FO needs a wrapper to set the namespace
                if ( $format eq 'PDF' ) {
                    $node
                        = $parser->parse_xml_chunk(
                        qq|<$tag xmlns:fo="http://www.w3.org/1999/XSL/Format">|
                            . $line
                            . "</$tag>" );
                }
                else {
                    $node = $parser->parse_xml_chunk($line);
                }
            }

            # calculate unformated line length
            $fline = $node->string_value();
        }

        $position = max( $position, length($fline) + 4 );
        if ( defined( $callout{$count} ) ) {
            $callout{$count}{'length'} = length($fline);
        }
    }

    # add callout numbers
    $io    = IO::String->new($test);
    $count = -1;
    while (<$io>) {
        my $line = $_;
        $count++;

        # skip first line, which has xml decl
        if ( $count == 0 ) { next; }
        $out_string .= $line;

        if ( defined( $callout{$count} ) ) {
            chomp($out_string);

            # if the position requested is less than the line length,
            # use the calculated position instead
            my $pos = $callout{$count}{'pos'};
            $pos = $position if ( $pos < $callout{$count}{'length'} );

            my $padding = $pos - ( $callout{$count}{'length'} || 0 );
            $out_string .= " " x $padding;

            foreach my $index (
                sort( { $a <=> $b } @{ $callout{$count}{lines} } ) )
            {
                if ( $mode eq 'gfx' ) {
                    my $gfx_node;

                    if ( $format eq 'HTML' ) {
                        $gfx_node = XML::LibXML::Element->new('img');
                        $gfx_node->setAttribute( 'class',  'callout' );
                        $gfx_node->setAttribute( 'alt',    $index );
                        $gfx_node->setAttribute( 'border', '0' );
                        $gfx_node->setAttribute( 'src',
                            "Common_Content/images/$index.png" );
                    }
                    elsif ( $format eq 'PDF' ) {
                        $gfx_node = XML::LibXML::Element->new(
                            'fo:external-graphic');
                        $gfx_node->setAttribute( 'src',
                            "url(Common_Content/images/$index.svg)" );
                        $gfx_node->setAttribute( 'content-width',  '10pt' );
                        $gfx_node->setAttribute( 'content-height', '10pt' );
                        $gfx_node->setAttribute( 'content-type',
                            'content-type:image/svg+xml' );
                        $gfx_node->setNamespace(
                            'http://www.w3.org/1999/XSL/Format', 'fo' );
                    }
                    $out_string .= $gfx_node->toString();
                }
                else {    # numeric
                    $out_string .= "$index ";
                }
            }
            $out_string .= "\n";
        }

    }

    $childnode->replaceNode( $parser->parse_xml_chunk($out_string) );
    return ($verbatim);
}

=head2  numberLines

perl_numberLines XSL function for numbering lines.

Returns: Modified input tree, which is DocBook XML.

=cut

sub numberLines {

    # BUGBUG testing BZ #653432
    my $count   = shift()->string_value();
    my $content = shift();

    my $parser = XML::LibXML->new();
    $parser->expand_entities(0);

    my $text      = $content->string_value();
    my $num_lines = () = ( $text =~ /^/mg );
    my $format    = '%' . length("$num_lines") . 's:' . chr(160);

    my $out_string = $text;
    $out_string =~ s/^/sprintf("$format",$count++)/egm;

    # this gives an XML::LibXML::DocumentFragment
    # BUGBUG testing BZ #653432
    # my $list = $parser->parse_balanced_chunk($out_string);
    my $list = XML::LibXML::Text->new($out_string);

    # remove the input node
    $content->shift;

    # BUGBUG testing BZ #653432
    $content->push($list);

    # append the marked-up nodes
    #    foreach my $node ( $list->childNodes() ) {
    #        $content->push($node);
    #    }

    return ($content);
}

=head2 package_brand

Create the structure for the distributed files and save it as a tar.gz file

=cut

sub package_brand {
    my ( $self, $args ) = @_;
    my $binary = delete( $args->{binary} );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    my $tmp_dir = $self->{publican}->param('tmp_dir');
    my $name    = lc( $self->{publican}->param('brand') );
    my $version = $self->{publican}->param('version');
    my $release = $self->{publican}->param('release');

    my $tardir = "publican-$name-$version";
    mkpath("$tmp_dir/tar/$tardir");
    mkpath("$tmp_dir/rpm");

    my $langs     = get_all_langs();
    my @file_list = (
        'publican.cfg', "publican-$name.spec",
        'README',       'COPYING',
        'defaults.cfg', 'overrides.cfg'
    );

    foreach my $file (@file_list) {
        rcopy( $file, "$tmp_dir/tar/$tardir/." ) if ( -f $file );
    }

    foreach my $dir ( split( /,/, $langs ), 'pot', 'xsl', 'book_templates' ) {
        dircopy( "$dir", "$tmp_dir/tar/$tardir/$dir" ) if ( -d $dir );
    }

    my $dir = pushd("$tmp_dir/tar");
    finddepth( \&del_unwanted_dirs, $tardir );
    my @files = dir_list( $tardir, '*' );
    Archive::Tar->create_archive( "$tardir.tgz", 9, @files );
    $dir = undef;

    fmove( "$tmp_dir/tar/$tardir.tgz", "$tmp_dir/rpm/." );

    $self->build_rpm( { spec => "publican-$name.spec", binary => $binary } );

    return;
}

=head2 package_home

Package a book for use as a Publican Website home page.

=cut

sub package_home {
    my ( $self, $args ) = @_;

    my $binary = delete( $args->{binary} );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    my $tmp_dir    = $self->{publican}->param('tmp_dir');
    my $product    = $self->{publican}->param('product');
    my $version    = $self->{publican}->param('version');
    my $docname    = $self->{publican}->param('docname');
    my $edition    = $self->{publican}->param('edition');
    my $configfile = $self->{publican}->param('configfile');
    my $release    = $self->{publican}->param('release');
    my $xml_lang   = $self->{publican}->param('xml_lang');
    my $type       = $self->{publican}->param('type');
    my $web_type   = $self->{publican}->param('web_type') || 'home';

    my $name_start = "$docname";
    $name_start = "$product-$docname"          if ( $web_type eq 'product' );
    $name_start = "$product-$docname-$version" if ( $web_type eq 'version' );

    my $tardir = "$name_start-web-$web_type-$edition";

    mkpath("$tmp_dir/tar/$tardir");
    mkpath("$tmp_dir/rpm");

    my $langs     = get_all_langs();
    my @file_list = qw(publican.cfg site_overrides.css);

    foreach my $file (@file_list) {
        rcopy( $file, "$tmp_dir/tar/$tardir/." ) if ( -f $file );
    }

    foreach my $dir ( split( /,/, $langs ), 'pot' ) {
        dircopy( "$dir", "$tmp_dir/tar/$tardir/$dir" ) if ( -d $dir );
    }

    my $dir = pushd("$tmp_dir/tar");
    finddepth( \&del_unwanted_dirs, $tardir );
    my @files = dir_list( $tardir, '*' );
    Archive::Tar->create_archive( "$tardir-$release.tgz", 9, @files );
    $dir = undef;

    fmove( "$tmp_dir/tar/$tardir-$release.tgz", "$tmp_dir/rpm/." );

    my $common_config = $self->{publican}->param('common_config');
    my $xsl_file      = $common_config . "/xsl/web-home-spec.xsl";
    $xsl_file =~ s/"//g;    # windows

    my $license = $self->{publican}->param('license');
    my $brand   = 'publican-' . lc( $self->{publican}->param('brand') );
    my $doc_url = $self->{publican}->param('doc_url');
    my $src_url = $self->{publican}->param('src_url');
## BUGBUG for home pages we need to use $xml_lang/Rev... NOT $tmp/$lang/...
    my $log = $self->change_log( { lang => $xml_lang } );
    my $embedtoc = '--embedtoc';

    $embedtoc = "" if ( $self->{publican}->param('no_embedtoc') );

    my %xslt_opts = (
        'book-title' => $name_start,
        'brand'      => $brand,
        'prod'       => $product,
        'prodver'    => $version,
        'rpmver'     => $edition,
        'rpmrel'     => $release,
        'docname'    => $docname,
        'license'    => $license,
        'url'        => $doc_url,
        'src_url'    => $src_url,
        'log'        => $log,
        tmpdir       => $tmp_dir,
        web_type     => $web_type,
        spec_version => $Publican::SPEC_VERSION,
        embedtoc     => $embedtoc,
    );

    logger(
        "\t" . maketext( "Using XML::LibXSLT on [_1]", $xsl_file ) . "\n" );

    my $parser    = XML::LibXML->new();
    my $xslt      = XML::LibXSLT->new();
    my $info_file = "$xml_lang/$type" . '_Info.xml';
    $info_file = "$xml_lang/" . $self->{publican}->param('info_file')
        if ( $self->{publican}->param('info_file') );

    my $source    = $parser->parse_file($info_file);
    my $style_doc = $parser->parse_file($xsl_file);

    my $stylesheet = $xslt->parse_stylesheet($style_doc);

    my $results = $stylesheet->transform( $source,
        XML::LibXSLT::xpath_to_string(%xslt_opts) );

    my $outfile;
    my $spec_name = "$tmp_dir/rpm/$name_start-web-$web_type.spec";

    open( $outfile, ">:encoding(UTF-8)", "$spec_name" )
        || croak( maketext( "Can't open spec file: [_1]", $@ ) );
    print( $outfile $stylesheet->output_string($results) );
    close($outfile);

    $self->build_rpm(
        {   spec   => "$tmp_dir/rpm/$name_start-web-$web_type.spec",
            binary => $binary
        }
    );

    return;
}

=head2 build_rpm

Build an srpm for books and brands.

=cut

sub build_rpm {
    my ( $self, $args ) = @_;

    my $spec = delete( $args->{spec} )
        || croak( maketext("spec is a mandatory argument") );
    my $binary = delete( $args->{binary} );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    my $tmp_dir = $self->{publican}->param('tmp_dir');
    my $os_ver  = $self->{publican}->param('os_ver');

    my $dir = abs_path("$tmp_dir/rpm");

    # From cspanspec and Fedora Makefile.common
    my $rpmbuild
        = ( -x "/usr/bin/rpmbuild" ? "/usr/bin/rpmbuild" : "/bin/rpm" );

    unless ( -x $rpmbuild ) {
        logger( maketext("rpmbuild not found, rpm creation aborted.") . "\n",
            RED );
        return;
    }

    debug_msg(
        maketext( "Building rpms from [_1] using [_2] in [_3]",
            $spec, $rpmbuild, $dir )
            . "\n"
    );

    my @rpm_args = (
        "--define", "_sourcedir $dir", "--define", "_builddir $dir",
        "--define", "_srcrpmdir $dir", "--define", "_rpmdir $dir"
    );

    if ($binary) {
        push( @rpm_args, "-ba" );
    }
    else {
        push( @rpm_args, "-bs", "--nodeps" );
    }

    if ($os_ver) {
        $os_ver = ".$os_ver" unless ( $os_ver =~ m/^\./ );
        push( @rpm_args, "--define", "dist $os_ver" );
    }

    push( @rpm_args, $spec );

    if ( system( $rpmbuild, @rpm_args ) != 0 ) {
        if ( $? == -1 ) {
            croak maketext( "Failed to execute [_1], error number: [_2]",
                $rpmbuild, $! )
                . "\n";
        }
        elsif ( WIFSIGNALED($?) ) {
            croak maketext( "[_1] died with signal [_2]",
                $rpmbuild, WTERMSIG($?) )
                . "\n";
        }
        else {
            croak maketext( "[_1] exited with value [_2]",
                $rpmbuild, WEXITSTATUS($?) )
                . "\n";
        }
    }

    return;
}

=head2 package

Create the structure for the distributed files and save it as a tar.gz file

Creates RPM Specfile and build SRPM.

TODO: Consider handling other package formats, deb etc.

=cut

sub package {
    my ( $self, $args ) = @_;

    my $lang = delete( $args->{lang} )
        || croak( maketext("lang is a mandatory argument") );
    my $desktop       = delete( $args->{desktop} )       || 0;
    my $short_sighted = delete( $args->{short_sighted} ) || 0;
    my $binary        = delete( $args->{binary} );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    croak(
        maketext(
            "Short-sighted packages can only be used to make desktop rpms. Add --desktop to your argument list."
        )
    ) if ( $short_sighted and not $desktop );

    my $tmp_dir           = $self->{publican}->param('tmp_dir');
    my $product           = $self->{publican}->param('product');
    my $version           = $self->{publican}->param('version');
    my $docname           = $self->{publican}->param('docname');
    my $edition           = $self->{publican}->param('edition');
    my $configfile        = $self->{publican}->param('configfile');
    my $release           = $self->{publican}->param('release');
    my $xml_lang          = $self->{publican}->param('xml_lang');
    my $type              = $self->{publican}->param('type');
    my $web_formats_comma = $self->{publican}->param('web_formats');
    my $web_formats       = $web_formats_comma;
    my $embedtoc          = '--embedtoc';

    $embedtoc = "" if ( $self->{publican}->param('no_embedtoc') );

    $web_formats =~ s/,/ /g;

    # No PDF for Indic packages. BZ #655713
##    if (   $lang =~ /(?:IN|ar-SA|fa-IR|he-IL)/
##        || $xml_lang =~ /(?:IN|ar-SA|fa-IR|he-IL)/ )
##    {
##        $web_formats_comma =~ s/pdf,//g;
##        $web_formats_comma =~ s/,pdf//g;
##        $web_formats       =~ s/\s*pdf\s*/ /g;
##    }

    if ( $lang ne $xml_lang ) {
        $release = undef;

        my $rev_file = "$lang/Revision_History.xml";
        $rev_file = "$lang/" . $self->{publican}->param('rev_file')
            if ( $self->{publican}->param('rev_file') );

        croak( maketext( "Can't locate required file: [_1]", $rev_file ) )
            if ( !-f $rev_file );

        my $rev_doc = XML::TreeBuilder->new(
            { 'NoExpand' => "1", 'ErrorContext' => "2" } );
        $rev_doc->parse_file($rev_file);
        my $VR = eval {
            $rev_doc->root()->look_down( "_tag", "revnumber" )->as_text();
        };
        if ($@) {
            croak( maketext( "revnumber not found in [_1]", $rev_file ) );
        }

        $VR =~ /^([0-9.]*)-([0-9.]*)$/ || croak(
            maketext(
                "revnumber ([_1]) does not match the required format of '[_2]'",
                $VR,
                '^([0-9.]*)-([0-9.]*)$/'
            )
        );

        $edition = $1;
        $release = $2;
    }

    my $name_start = "$product-$docname-$version";
    $name_start = "$product-$docname" if ($short_sighted);

    my $tardir = "$name_start-web-$lang-$edition";
    $tardir = "$name_start-$lang-$edition" if ($desktop);
    $tardir = "$name_start-$lang-$edition" if ($short_sighted);

    # distributed sets need to be collected before packaging
    if ( ( $type eq 'Set' ) && ( $self->{publican}->{config}->param('scm') ) )
    {
        $self->get_books();
        $self->build_set_books( { langs => $lang } );
    }

    $self->setup_xml( { langs => $lang, cleaning => 1 } );

    mkpath("$tmp_dir/tar/$tardir");
    dircopy( "$tmp_dir/$lang/xml", "$tmp_dir/tar/$tardir/$lang" );
    rmtree("$tmp_dir/tar/$tardir/$lang/Common_Content");
    mkpath("$tmp_dir/rpm");

    dircopy( "$xml_lang/icons", "$tmp_dir/tar/$tardir/$lang/icons" )
        if ( -e "$xml_lang/icons" );
    dircopy( "$lang/icons", "$tmp_dir/tar/$tardir/$lang/icons" )
        if ( -e "$lang/icons" );
    finddepth( \&del_unwanted_dirs, "$tmp_dir/tar/$tardir/$lang/icons" )
        if ( -e "$tmp_dir/tar/$tardir/$lang/icons" );

    dircopy( "$xml_lang/files", "$tmp_dir/tar/$tardir/$lang/files" )
        if ( -e "$xml_lang/files" );
    dircopy( "$lang/files", "$tmp_dir/tar/$tardir/$lang/files" )
        if ( -e "$lang/files" );
    finddepth( \&del_unwanted_dirs, "$tmp_dir/tar/$tardir/$lang/files" )
        if ( -e "$tmp_dir/tar/$tardir/files" );

    $self->{publican}->{config}->param( 'xml_lang', $lang );

    # Need to remove scm from packaged set to avoid fetching from repo
    my $tmp_scm = undef;

    if ( $type eq 'Set' && $self->{publican}->{config}->param('scm') ) {
        $tmp_scm = $self->{publican}->{config}->param('scm');
        $self->{publican}->{config}->delete('scm');
    }

    my $common_config = $self->{publican}->param('common_config');
    my $xsl_file      = $common_config . "/xsl/web-spec.xsl";
    $xsl_file = $common_config . "/xsl/dt_htmlsingle_spec.xsl" if ($desktop);
    $xsl_file =~ s/"//g;    # windows
    my $license       = $self->{publican}->param('license');
    my $brand         = lc( $self->{publican}->param('brand') );
    my $doc_url       = $self->{publican}->param('doc_url');
    my $src_url       = $self->{publican}->param('src_url');
    my $dt_obsoletes  = $self->{publican}->param('dt_obsoletes') || "";
    my $dt_requires   = $self->{publican}->param('dt_requires') || "";
    my $web_obsoletes = $self->{publican}->param('web_obsoletes') || "";
    my $translation   = ( $lang ne $xml_lang );
    my $language      = code2language( substr( $lang, 0, 2 ) );

    my ( $web_product_label, $web_version_label, $web_name_label )
        = $self->web_labels( { lang => $lang, xml_lang => $xml_lang } );

    my $web_dir = $self->{publican}->param('web_dir')
        || '%{_localstatedir}/www/html/docs';
    my $web_cfg = $self->{publican}->param('web_cfg')
        || Publican::ConfigData->config('etc') . '/publican-website.cfg';
    my $web_req    = $self->{publican}->param('web_req')    || '';
    my $sort_order = $self->{publican}->param('sort_order') || '';

    my $menu_category = $self->{publican}->param('menu_category')
        || "X-Red-Hat-Base;";
    $menu_category =~ s/__LANG__/$lang/g;
    $menu_category .= ';' if ( $menu_category !~ /;\s*$/ );

    # store lables for rebuilding translated content
    $self->{publican}->{config}
        ->param( 'web_product_label', $web_product_label )
        if ($web_product_label);
    $self->{publican}->{config}
        ->param( 'web_version_label', $web_version_label )
        if ($web_version_label);
    $self->{publican}->{config}->param( 'web_name_label', $web_name_label )
        if ($web_name_label);

    $self->{publican}->{config}->param( 'release', $release );

    # don't override these
    $self->{publican}->{config}->delete('common_config');
    my $common_content = $self->{publican}->param('common_content');
    $self->{publican}->{config}->delete('common_content');
    $self->{publican}->{config}->delete('strict');
    $self->{publican}->{config}->delete('release');
    $self->{publican}->{config}->delete('edition');
    $self->{publican}->{config}->delete('brand_dir');
    $self->{publican}->{config}->delete('cover_image');

    $self->{publican}->{config}->write("$tmp_dir/tar/$tardir/publican.cfg");

    $self->{publican}->{config}->param( 'common_config',  $common_config );
    $self->{publican}->{config}->param( 'common_content', $common_content );
    $self->{publican}->{config}->param( 'xml_lang',       $xml_lang );
    $self->{publican}->{config}->param( 'scm',     $tmp_scm ) if ($tmp_scm);
    $self->{publican}->{config}->param( 'release', $release );
    $self->{publican}->{config}->param( 'edition', $edition );

    my $dir = pushd("$tmp_dir/tar");
    my @files = dir_list( $tardir, '*' );
    Archive::Tar->create_archive( "../rpm/$tardir-$release.tgz", 9, @files );

    $dir = undef;

    my $log = $self->change_log( { lang => $lang } );

    my $full_abstract = $self->{publican}->get_abstract( { lang => $lang } );
    $full_abstract =~ s/\p{Z}+/ /g;

    # Wrap description for RPM style requirements
    $columns = 68;
    my $abstract = fill( "", "", $full_abstract );
    $columns = $DEFAULT_WRAP;

    # Escape single quotes to prevent bash breaking
    $full_abstract =~ s/"/\\"/g;

    my $full_subtitle = $self->{publican}->get_subtitle( { lang => $lang } );
    $full_subtitle =~ s/"/\\"/g;
    $full_subtitle =~ s/\p{Z}+/ /g;
    chomp($full_subtitle);

    my %xslt_opts = (
        'book-title'      => $name_start,
        lang              => $lang,
        prod              => $product,
        prodver           => $version,
        rpmver            => $edition,
        rpmrel            => $release,
        docname           => $docname,
        license           => $license,
        brand             => "publican-$brand",
        url               => $doc_url,
        src_url           => $src_url,
        'log'             => $log,
        dt_obsoletes      => $dt_obsoletes,
        dt_requires       => $dt_requires,
        web_obsoletes     => $web_obsoletes,
        translation       => $translation,
        language          => $language,
        abstract          => $abstract,
        tmpdir            => $tmp_dir,
        ICONS             => ( -e "$xml_lang/icons" ? 1 : 0 ),
        product_label     => $web_product_label,
        version_label     => $web_version_label,
        name_label        => $web_name_label,
        web_dir           => $web_dir,
        web_cfg           => $web_cfg,
        web_req           => $web_req,
        full_abstract     => $full_abstract,
        full_subtitle     => $full_subtitle,
        web_formats       => $web_formats,
        web_formats_comma => $web_formats_comma,
        menu_category     => $menu_category,
        spec_version      => $Publican::SPEC_VERSION,
        embedtoc          => $embedtoc,
        sort_order        => $sort_order,
    );

    # \p{Z} is unicode white space, which is a super set of ascii white space.
    if ( $full_abstract !~ /[^\p{Z}]/ ) {
        logger(
            maketext(
                "WARNING: You can not create RPM packages with a blank abstract. Skipping RPM creation.\n"
            ),
            RED
        );
        return;
    }

    if ( $full_subtitle !~ /[^\p{Z}]/ ) {
        logger(
            maketext(
                "WARNING: You can not create RPM packages with a blank subtitle. Skipping RPM creation.\n"
            ),
            RED
        );
        return;
    }

    logger(
        "\t" . maketext( "Using XML::LibXSLT on [_1]", $xsl_file ) . "\n" );

    my $parser    = XML::LibXML->new();
    my $xslt      = XML::LibXSLT->new();
    my $info_file = "$tmp_dir/$lang/xml/$type" . '_Info.xml';
    $info_file = "$tmp_dir/$lang/xml/" . $self->{publican}->param('info_file')
        if ( $self->{publican}->param('info_file') );

    my $source    = $parser->parse_file($info_file);
    my $style_doc = $parser->parse_file($xsl_file);

    my $stylesheet = $xslt->parse_stylesheet($style_doc);

    my $results = $stylesheet->transform( $source,
        XML::LibXSLT::xpath_to_string(%xslt_opts) );

    my $outfile;
    my $spec_name = "$tmp_dir/rpm/$name_start-web-$lang.spec";
    $spec_name = "$tmp_dir/rpm/$name_start-$lang.spec"
        if ( $desktop or $short_sighted );

    open( $outfile, ">:encoding(UTF-8)", "$spec_name" )
        || croak( maketext( "Can't open spec file: [_1]", $@ ) );
    print( $outfile $stylesheet->output_string($results) );
    close($outfile);

    $self->build_rpm( { spec => $spec_name, binary => $binary } );

    return;
}

=head2 web_labels

Determine if the labels use in the web navigation are different from the names used for packaging.

=cut

sub web_labels {
    my ( $self, $args ) = @_;

    my $lang = delete( $args->{lang} )
        || croak( maketext("lang is a mandatory argument") );
    my $xml_lang = delete( $args->{xml_lang} )
        || croak( maketext("xml_lang is a mandatory argument") );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    my $tmp_dir = $self->{publican}->param('tmp_dir');
    my $type    = $self->{publican}->param('type');
    my $docname = $self->{publican}->param('docname');
    my $product = $self->{publican}->param('product');
    my $version = $self->{publican}->param('version');

    my $web_product_label = $self->{publican}->param('web_product_label')
        || undef;
    my $web_version_label = $self->{publican}->param('web_version_label')
        || undef;
    my $web_name_label = $self->{publican}->param('web_name_label') || undef;

    #    if ( $lang ne $xml_lang ) {
    my $xml_file = "$tmp_dir/$lang/xml/$type" . '_Info.xml';
    $xml_file = "$tmp_dir/$lang/xml/" . $self->{publican}->param('info_file')
        if ( $self->{publican}->param('info_file') );
    croak( maketext( "Can't locate required file: [_1]", $xml_file ) )
        if ( !-f $xml_file );

    my $xml_doc = XML::TreeBuilder->new();
    $xml_doc->parse_file($xml_file);

    # BUGBUG can't translate overridden labels :(
    unless ($web_product_label) {
        $web_product_label = eval {
            $xml_doc->root()->look_down( "_tag", "productname" )->as_text();
        };
        if ($@) {

            #            croak maketext("productname not found in Info file");
        }
        else {
            $web_product_label =~ s/\s/_/g;
        }
    }
    unless ($web_name_label) {
        $web_name_label = eval {
            $xml_doc->root()->look_down( "_tag", "title" )->as_text();
        };
        if ($@) {

            #           croak maketext("title not found in Info file");
        }
        else {
            $web_name_label =~ s/\s/_/g;
        }
    }

    #    }

    $web_product_label =~ s/"/\\"/g if ($web_product_label);
    $web_name_label    =~ s/"/\\"/g if ($web_name_label);
    $web_version_label =~ s/"/\\"/g if ($web_version_label);

    if ( $web_name_label && $web_name_label eq $docname ) {
        $web_name_label = undef;
    }

    if ( $web_version_label && $web_version_label eq $version ) {
        $web_version_label = undef;
    }

    if ( $web_product_label && $web_product_label eq $product ) {
        $web_product_label = undef;
    }

    return ( $web_product_label, $web_version_label, $web_name_label );
}

=head2 change_log

Generate an RPM style change log from $xml_lang/Revision_History.xml

=cut

sub change_log {
    my ( $self, $args ) = @_;

    my $lang = delete( $args->{lang} )
        || croak("lang is a mandatory argument");

    if ( %{$args} ) {
        croak "unknown args: " . join( ", ", keys %{$args} );
    }

    my $log     = "";
    my $tmp_dir = $self->{publican}->param('tmp_dir');

    my $xml_doc = XML::TreeBuilder->new(
        { 'NoExpand' => "0", 'ErrorContext' => "2" } );

    my $rev_file = "Revision_History.xml";
    $rev_file = $self->{publican}->param('rev_file')
        if ( $self->{publican}->param('rev_file') );

    my $path = "$tmp_dir/$lang/xml/$rev_file";
    $path = "$lang/$rev_file"
        if ( $self->{publican}->param('web_home')
        || $self->{publican}->param('web_type') );

    $xml_doc->parse_file("$path");

    $xml_doc->root()->look_down( "_tag", "revision" )
        || croak(
        maketext(
            "Missing mandatory field '[_1]' in revision history.", 'revision'
        )
        );

    foreach my $revision ( $xml_doc->root()->look_down( "_tag", "revision" ) )
    {

        my $node = $revision->look_down( '_tag', 'date' )
            || croak(
            maketext(
                "Missing mandatory field '[_1]' in revision history.", 'date'
            )
            );
        my $in_date = $node->as_trimmed_text();
        my $dt      = DateTime::Format::DateParse->parse_datetime($in_date)
            || croak(
            maketext( "Invalid date: '[_1]' in revision history.", $in_date )
            );
        my $date = $dt->strftime("%a %b %e %Y");

        $node = $revision->look_down( '_tag', 'firstname' )
            || croak(
            maketext(
                "Missing mandatory field '[_1]' in revision history.",
                'firstname'
            )
            );
        my $firstname = $node->as_trimmed_text();

        $node = $revision->look_down( '_tag', 'surname' )
            || croak(
            maketext(
                "Missing mandatory field '[_1]' in revision history.",
                'surname'
            )
            );
        my $surname = $node->as_trimmed_text();

        $node = $revision->look_down( '_tag', 'email' )
            || croak(
            maketext(
                "Missing mandatory field '[_1]' in revision history.", 'email'
            )
            );
        my $email = $node->as_trimmed_text();

        $node = $revision->look_down( '_tag', 'revnumber' )
            || croak(
            maketext(
                "Missing mandatory field '[_1]' in revision history.",
                'revnumber'
            )
            );

        my $revnumber = $node->as_trimmed_text();

        unless ( $revnumber =~ m/\d[0-9.]*-\d[0-9.]*/ ) {
            croak(
                maketext(
                    "ERROR: revnumber '[_1]' does not match required format [_2]. e.g. '1-1'.\n",
                    $revnumber,
                    q|\d[0-9.]*-\d[0-9.]*|
                )
            );
        }

        $log .= sprintf( "* %s %s %s <%s> - %s\n",
            $date, $firstname, $surname, $email, $revnumber );

        $revision->look_down( '_tag', 'member' )
            || croak(
            maketext(
                "Missing mandatory field '[_1]' in revision.", 'member'
            )
            );
        foreach my $member ( $revision->look_down( '_tag', 'member' ) ) {
            $log .= sprintf( "- %s \n", $member->as_trimmed_text() );
        }

        $log .= "\n";
    }

    return ($log);
}

=head2 get_books

Fetch all the books for a set from a repo.

Supported Repos: SVN

=cut

sub get_books {
    my ( $self, $args ) = @_;

    my $scm = ( lc( $self->{publican}->param('scm') ) || "" );

    unless ($scm) {
        logger(
            maketext(
                "Config parameter 'scm' not found; treating set as standalone."
                )
                . "\n",
            RED
        );
        return;
    }

    croak( maketext( "Unknown set SCM: [_1]", $scm ) )
        unless ( $scm =~ /^(svn|svn)$/ );

    my $books = $self->{publican}->param('books')
        || croak(
        maketext(
            "'books' is a required configuration parameter for a remote set")
            . "\n"
        );
    my $repo = $self->{publican}->param('repo')
        || croak(
        maketext(
            "'repo' is a required configuration parameter for a remote set")
            . "\n"
        );

    foreach my $book ( split( " ", $books ) ) {
        if ( !-d $book ) {
            logger( maketext( "Fetching [_1] from scm", $book ) . "\n" );
            if ( $scm eq 'svn' ) {
                debug_msg(
                    "TODO: should be using Alien::SVN or similar to access SVN!\n"
                );
                if ( system("svn export --quiet $repo/$book $book") != 0 ) {
                    croak(
                        maketext(
                            "Fatal Error: SVN export failed. Book: [_1]. Error Number: [_2]",
                            $book,
                            $?
                        )
                    );
                }
            }
        }
    }

    return;
}

=head2 build_set_books

Prepare XML from sub books for Remote Sets

=cut

sub build_set_books {
    my ( $self, $args ) = @_;

    my $langs = delete( $args->{langs} )
        || croak( maketext("langs is a mandatory argument") );

    if ( %{$args} ) {
        croak( maketext( "unknown args: " . join( ", ", keys %{$args} ) ) );
    }

    my $books = $self->{publican}->param('books')
        || croak(
        maketext(
            "'books' is a required configuration parameter for a remote set")
        );
    my $tmp_dir = $self->{publican}->param('tmp_dir');

    foreach my $book ( split( " ", $books ) ) {
        logger( maketext( "Start building [_1]", $book ) . "\n" );
        my $dir = pushd($book);

        logger(
            maketext("Running clean_ids to prevent inter-book ID clashes.")
                . "\n" );

        if ( system("publican clean_ids") != 0 ) {
            croak(
                maketext(
                    "Fatal error: Book failed to run clean_ids! Book: [_1]. Error Number: [_2]",
                    $book,
                    $?
                )
            );
        }

        if (system(
                "publican build --formats=xml --langs=$langs --distributed_set"
            ) != 0
            )
        {

            # build failed
            croak(
                maketext(
                    "Fatal error: Book failed to build! Book: [_1]. Error Number: [_2]",
                    $book,
                    $?
                )
            );
        }

        $dir = undef;

        foreach my $lang ( split( /,/, $langs ) ) {
            dirmove(
                "$book/$tmp_dir/$lang/xml/images",
                "$tmp_dir/$lang/xml/images/$book/images"
            );
            dircopy( "$book/$tmp_dir/$lang/xml", "$tmp_dir/$lang/xml/$book" );
        }
        logger( maketext( "Finish building [_1]", $book ) . "\n" );
    }

    return;
}

=head2  NAME

Description

=cut

=for
sub NAME {
    my ( $self, $args ) = @_;

#    my $lang = delete( $args->{lang} ) || croak(maketext("lang is a mandatory argument"));
#
#    if ( %{$args} ) {
#        croak( maketext("unknown arguments: [_1]", join( ", ", keys %{$arg}) ));
#    }

    return;
}
=cut

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
Config::Simple
Publican
Publican::XmlClean
Publican::Translate
File::Copy::Recursive
File::Path
File::pushd
File::Find
XML::LibXSLT
XML::LibXML
Cwd
Archive::Tar
DateTime
DateTime::Format::DateParse
Syntax::Highlight::Engine::Kate
HTML::TreeBuilder
HTML::FormatText
Term::ANSIColor
POSIX

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<publican-list@redhat.com>, or through the web interface at
L<https://bugzilla.redhat.com/bugzilla/enter_bug.cgi?product=Publican&component=publican>.

=head1 AUTHOR

Jeff Fearn  C<< <jfearn@redhat.com> >>
