package Publican::Builder;

use utf8;
use strict;
use warnings;
use Carp;
use Config::Simple;
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
use Term::ANSIColor qw(:constants);
use POSIX qw(floor :sys_wait_h);
use Locale::Language;
use List::Util qw(max);
use Text::Wrap qw(fill $columns);
use IO::String;

use vars qw(@ISA $VERSION @EXPORT @EXPORT_OK);

$VERSION = '0.2';
@ISA     = qw(Exporter AutoLoader);
@EXPORT  = qw(new_tree dtd_string);

my $INVALID = 1;

my $TEST_MML     = 0;
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

    my $self = bless {}, $class;

    $self->{publican}   = Publican->new();
    $self->{translator} = Publican::Translate->new();

    return $self;
}

=head2  build

Transform the source in to another format.

FORMATS eclipse epub html html-single html-desktop pdf txt

Valid formats: eclipse epub html html-single html-desktop pdf txt

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

    if ( $type eq 'Set' && $self->{publican}->{config}->param('scm') ) {
        $self->get_books();
        $self->build_set_books( { langs => $langs } );
    }

    if ( $langs =~ /^all$/i ) {
        $langs = get_all_langs();
    }
    $self->setup_xml(
        {   langs           => $langs,
            exlude_common   => ( $type eq 'brand' ),
            distributed_set => $distributed_set
        }
    );

    foreach my $lang ( sort( split( /,/, $langs ) ) ) {
        logger( maketext( "Beginning work on [_1]", $lang ) . "\n" );

        # hmmm can't validate brand XML as it's incomplete
        if (    ( $type ne 'brand' )
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

        foreach my $format ( split( /,/, $formats ) ) {
            logger( "\t" . maketext( "Starting [_1]", $format ) . "\n" );
            if ( $format eq 'test' ) {
                logger( "\t" . maketext( "Finished [_1]", $format ) . "\n" );
                next;
            }

            $self->transform(
                { format => $format, lang => $lang, embedtoc => $embedtoc } )
                unless ( $format eq 'xml' );
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
                        rcopy( "$tmp_dir/$lang/$format/*", "$path/." )
                            if ( -d "$tmp_dir/$lang/$format" );
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
    }
    debug_msg("end of build\n");
    return;
}

=head2 setup_xml

Create the proper directory structure for the XML, including copying in Brand files.

=cut

sub setup_xml {
    my ( $self, $args ) = @_;
    $File::Copy::Recursive::KeepMode = 1;
    my $xml_lang = $self->{publican}->param('xml_lang');
    my $tmp_dir  = $self->{publican}->param('tmp_dir');
    my $type     = $self->{publican}->param('type');

    my $exlude_common = delete( $args->{'exlude_common'} ) || undef;
    my $langs = delete( $args->{langs} )
        || croak( maketext("langs is a mandatory argument") );
    my $distributed_set = delete( $args->{distributed_set} ) || 0;

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

        if ( $lang eq $xml_lang ) {
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
        }

        # clean XML
        my $cleaner = Publican::XmlClean->new(
            {   lang            => $lang,
                donotset_lang   => $exlude_common,
                distributed_set => $distributed_set
            }
        );

        my @xml_files = dir_list( "$tmp_dir/$lang/xml_tmp", '*.xml' );

        # copy css for brand and default images for non-brand
        if ( $type eq 'brand' ) {
            dircopy( "$lang/css", "$tmp_dir/$lang/xml/css" )
                if ( -d "$lang/css" );
        }
        else {
            dircopy( "$xml_lang/images", "$tmp_dir/$lang/xml/images" )
                if ( -d "$xml_lang/images" );
        }

        dircopy( "$lang/images", "$tmp_dir/$lang/xml/images" )
            if ( -d "$lang/images" );

        unless ($exlude_common) {
            mkpath("$tmp_dir/$lang/xml/Common_Content");

            # copy common files
            my $common_content = $self->{publican}->param('common_content');
            my $brand          = $self->{publican}->param('brand');

            if ( $common_content =~ m/\"/ & $common_content !~ m/\s/ ) {
                $common_content =~ s/\"//g;
            }

            File::Copy::Recursive::rcopy_glob(
                $common_content . "/common/en-US/*",
                "$tmp_dir/$lang/xml/Common_Content"
            );
            File::Copy::Recursive::rcopy_glob(
                $common_content . "/common/$lang/*",
                "$tmp_dir/$lang/xml/Common_Content"
            ) if ( $lang ne 'en-US' );

            if ( $brand ne 'common' ) {
                my $brand_lang
                    = $self->{publican}->{brand_config}->param('xml_lang');

                my @files = File::Copy::Recursive::rcopy_glob(
                    $common_content . "/$brand/$brand_lang/*",
                    "$tmp_dir/$lang/xml/Common_Content"
                );

                croak(
                    maketext(
                        "Brand '[_1]' had no content to copy.", $brand
                    )
                ) if ( scalar(@files) == 0 );

                File::Copy::Recursive::rcopy_glob(
                    $common_content . "/$brand/$lang/*",
                    "$tmp_dir/$lang/xml/Common_Content"
                ) if ( $lang ne $brand_lang );
            }

            my $ent_file
                = "$xml_lang/" . $self->{publican}->param('docname') . ".ent";
            rcopy( $ent_file, "$tmp_dir/$lang/xml/." ) if ( -e $ent_file );

            $ent_file
                = $lang . "/" . $self->{publican}->param('docname') . ".ent";
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

    my $docname = $self->{publican}->param('docname');
    my $dtdver  = $self->{publican}->param('dtdver');

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

    croak( maketext( "Cannot locate main XML file: '[_1]'", "$docname.xml" ) )
        unless ( -f "$docname.xml" );

    my $source;
    eval { $source = $parser->parse_file("$docname.xml"); };

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

    if ( 0 && $TEST_MML ) {
        $dtd_type = '-//OASIS//DTD DocBook MathML Module V1.0//EN';
        $dtd_path
            = 'http://www.oasis-open.org/docbook/xml/mathml/1.0/dbmathml.dtd';
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
            $dtd_path = 'file:///D:/Data/temp/Redhat/DTD/docbookx.dtd';
        }
    }
    my $dtd = XML::LibXML::Dtd->new( $dtd_type, $dtd_path );

    unless ( $source->is_valid($dtd) ) {
        logger( maketext("Validation failed: ") . "\n", RED );
        croak( $source->validate($dtd) );
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

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    my $dir;

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
    my $type                = $self->{publican}->param('type');
    my $ec_name             = $self->{publican}->param('ec_name');
    my $ec_id               = $self->{publican}->param('ec_id');
    my $ec_provider         = $self->{publican}->param('ec_provider');

    my $TAR_NAME
        = $self->{publican}->param('product') . '-'
        . $self->{publican}->param('docname') . '-'
        . $self->{publican}->param('version');
    my $RPM_VERSION = $self->{publican}->param('edition');

    my $RPM_RELEASE = $self->{publican}->param('release');

    if ( $format eq 'txt' ) {
        if ( !-e "$tmp_dir/$lang/html-single" ) {
            $self->transform( { lang => $lang, format => 'html-single' } );
        }

        $dir = pushd("$tmp_dir/$lang");
        mkdir 'txt';
        my $TXT_FILE;
        open( $TXT_FILE, ">:utf8", "txt/$docname.txt" )
            || croak( maketext("Can't open file for text output!") );
        my $tree
            = HTML::TreeBuilder->new->parse_file("html-single/index.html");
        my $formatter
            = HTML::FormatText->new( leftmargin => 0, rightmargin => 72 );
        print( $TXT_FILE $formatter->format($tree) );
        close($TXT_FILE);
        $dir = undef;
        return;
    }

    my $xsl_file = $common_config . "/xsl/$format.xsl";
    $xsl_file = $common_content . "/$brand/xsl/$format.xsl"
        if ( -f $common_content . "/$brand/xsl/$format.xsl" );

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
    );

    mkdir "$tmp_dir/$lang/$format";

    my $toc_path = '../../../..';
    $toc_path = '.' if ( $self->{publican}->param('web_home') );

    if ( $format eq 'html-single' ) {

        $dir = pushd("$tmp_dir/$lang/$format");

        $xslt_opts{'doc.url'}  = "'$doc_url'";
        $xslt_opts{'prod.url'} = "'$prod_url'";
        $xslt_opts{'package'} = "'$TAR_NAME-$lang-$RPM_VERSION-$RPM_RELEASE'";
        $xslt_opts{'embedtoc'} = $embedtoc;
        $xslt_opts{'tocpath'}  = "'$toc_path'";
    }
    elsif ( $format eq 'html-desktop' ) {
        $xsl_file = $common_config . "/xsl/html-single.xsl";
        $xsl_file = $common_content . "/$brand/xsl/html-single.xsl"
            if ( -e $common_content . "/$brand/xsl/html-single.xsl" );
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
    XML::LibXSLT->max_depth(1000);

    my $security = XML::LibXSLT::Security->new();
    $security->register_callback( create_dir => sub { 1; } );

    #    $security->register_callback(read_net => sub { 0; });
    $xslt->security_callbacks($security);

    $parser->expand_xinclude(1);
    $parser->expand_entities(1);
    my $source    = $parser->parse_file("../xml/$docname.xml");
    my $style_doc = $parser->parse_file($xsl_file);

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

        my $new_href = 'file:///D:/Data/temp/Redhat/docbook-xsl-1.75.2';
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
    elsif ( $format =~ /^html-/ ) {    # html-single and html-desktop
        eval { $stylesheet->output_file( $results, "index.html" ) };
    }
    else {                             # html
        eval { $stylesheet->output_string($results) };
    }

    croak( maketext( "Transformation error '[_1]' : [_2]", $!, $@ ) ) if $@;

    if ( $format =~ /^pdf/ ) {
        my $pdf_name
            = $self->{publican}->param('product') . '-'
            . $self->{publican}->param('version') . '-'
            . $self->{publican}->param('docname') . '-'
            . "$lang.pdf";

        my $fop_command
            = qq|CLASSPATH="$classpath" fop -q -c $common_config/fop/fop.xconf -fo $docname.fo -pdf ../pdf/$pdf_name|;

## TODO find out if we need to set classpath on windows and how
        if ( $^O eq 'MSWin32' ) {
            $fop_command
                = qq|fop -q -c $common_config/fop/fop.xconf -fo $docname.fo -pdf ../pdf/$pdf_name|;
        }

        system($fop_command);

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
        dircopy( "$xml_lang/files", "$tmp_dir/$lang/$format/OEBPS/files" )
            if ( -e "$xml_lang/files" );
        dircopy( "$lang/files", "$tmp_dir/$lang/$format/OEBPS/files" )
            if ( -e "$lang/files" );

        # remove any RCS from the output
        finddepth( \&del_unwanted_dirs, "$tmp_dir/$lang/$format" );

        # remove any XML files from common
        finddepth( \&del_unwanted_xml,
            "$tmp_dir/$lang/$format/OEBPS/Common_Content" );

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
    else {
        $dir = undef;
        dircopy( "$tmp_dir/$lang/xml/images",
            "$tmp_dir/$lang/$format/images" );
        dircopy(
            "$tmp_dir/$lang/xml/Common_Content",
            "$tmp_dir/$lang/$format/Common_Content"
        );
        dircopy( "$xml_lang/files", "$tmp_dir/$lang/$format/files" )
            if ( -e "$xml_lang/files" );
        dircopy( "$lang/files", "$tmp_dir/$lang/$format/files" )
            if ( -e "$lang/files" );

        # remove any RCS from the output
        finddepth( \&del_unwanted_dirs, "$tmp_dir/$lang/$format" );

        # remove any XML files from common
        finddepth( \&del_unwanted_xml,
            "$tmp_dir/$lang/$format/Common_Content" );
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
                    if( $col =~ m/^(\d+)\s+(\d+)$/ ) {
                        $col = $1;
                        $pos = $2;
                    }

                    push( @{ $callout{$col}{lines} }, $index );
                    $callout{$col}{'pos'} = $pos ;
                }
            }
        }
        elsif ( $node->nodeName() eq 'area' ) {
            $index++;
            my $pos = 0;
            my $col = $node->getAttribute('coords')
                || carp( maketext("'area' requires a 'coords' attribute.") );

            if( $col =~ m/^(\d+)\s+(\d+)$/ ) {
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
            $pos = $position if($pos < $callout{$count}{'length'});

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
    my $os_ver  = $self->{publican}->param('os_ver');

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

    foreach my $dir ( split( /,/, $langs ), 'pot', 'xsl' ) {
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

    my $name_start = "$docname";
    my $tardir     = "$name_start-web-home-$edition";

    mkpath("$tmp_dir/tar/$tardir");
    mkpath("$tmp_dir/rpm");

    my $langs     = get_all_langs();
    my @file_list = ('publican.cfg');

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
    my $os_ver  = $self->{publican}->param('os_ver');
    my $search  = $self->{publican}->param('web_search');
    my $host    = $self->{publican}->param('web_host');
    my $log     = $self->change_log();

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
        web_search   => $search,
        web_host     => $host,
    );

    logger(
        "\t" . maketext( "Using XML::LibXSLT on [_1]", $xsl_file ) . "\n" );

    my $parser    = XML::LibXML->new();
    my $xslt      = XML::LibXSLT->new();
    my $source    = $parser->parse_file( "$xml_lang/$type" . '_Info.xml' );
    my $style_doc = $parser->parse_file($xsl_file);

    my $stylesheet = $xslt->parse_stylesheet($style_doc);

    my $results = $stylesheet->transform( $source,
        XML::LibXSLT::xpath_to_string(%xslt_opts) );

    my $outfile;
    my $spec_name = "$tmp_dir/rpm/$name_start-web-home.spec";

    open( $outfile, ">:utf8", "$spec_name" )
        || croak( maketext( "Can't open spec file: [_1]", $@ ) );
    print( $outfile $stylesheet->output_string($results) );
    close($outfile);

    $self->build_rpm(
        {   spec   => "$tmp_dir/rpm/$name_start-web-home.spec",
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

    if (system( $rpmbuild, "--define",
            "_sourcedir $dir", "--define",
            "_builddir $dir",  "--define",
            "_srcrpmdir $dir", "--define",
            "_rpmdir $dir", ( $binary ? "-ba" : ( "-bs", "--nodeps" ) ),
            "--define", "dist $os_ver",
            $spec
        ) != 0
        )
    {
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

    my $tmp_dir    = $self->{publican}->param('tmp_dir');
    my $product    = $self->{publican}->param('product');
    my $version    = $self->{publican}->param('version');
    my $docname    = $self->{publican}->param('docname');
    my $edition    = $self->{publican}->param('edition');
    my $configfile = $self->{publican}->param('configfile');
    my $release    = $self->{publican}->param('release');
    my $xml_lang   = $self->{publican}->param('xml_lang');
    my $type       = $self->{publican}->param('type');

    if ( $lang ne $xml_lang ) {
        $release = undef;
        my $po_file = "$lang/$type" . '_Info.po';

        if ( -f $po_file ) {
            my $PO;
            open( $PO, "<:utf8", $po_file )
                || croak( maketext( "Can't open PO file: [_1]", $po_file ) );
            while (<$PO>) {
                if (/"Project-Id-Version:\s*(\d*).*"$/) {
                    $release = $1;
                    last;
                }
            }
            close($PO);

            croak(
                maketext(
                    "Project-Id-Version in [_1] is not a valid release value.",
                    $po_file
                )
            ) unless defined $release;
        }
        else {
            croak(
                maketext(
                    "Required PO file missing. Could not locate [_1].",
                    $po_file
                )
            );
        }

    }

    my $name_start = "$product-$docname-$version";
    $name_start = "$product-$docname" if ($short_sighted);

    my $tardir = "$name_start-web-$lang-$edition";
    $tardir = "$name_start-$lang-$edition" if ($desktop);
    $tardir = "$name_start-$lang-$edition" if ($short_sighted);

    # distributed sets need to be collected before packaging
    if ( $type eq 'Set' ) {
        $self->get_books();
        $self->build_set_books( { langs => $lang } );
    }

    $self->setup_xml( { langs => $lang } );

    mkpath("$tmp_dir/tar/$tardir");
    dircopy( "$tmp_dir/$lang/xml", "$tmp_dir/tar/$tardir/$lang" );
    rmtree("$tmp_dir/tar/$tardir/$lang/Common_Content");
    mkpath("$tmp_dir/rpm");

    dircopy( "$xml_lang/icons", "$tmp_dir/tar/$tardir/icons" )
        if ( -e "$xml_lang/icons" );
    dircopy( "$lang/icons", "$tmp_dir/tar/$tardir/icons" )
        if ( -e "$lang/icons" );
    finddepth( \&del_unwanted_dirs, "$tmp_dir/tar/$tardir/icons" )
        if ( -e "$tmp_dir/tar/$tardir/icons" );

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

    $self->{publican}->{config}->param( 'release', $release );

    $self->{publican}->{config}->write("$tmp_dir/tar/$tardir/publican.cfg");
    $self->{publican}->{config}->delete('release');
    $self->{publican}->{config}->param( 'xml_lang', $xml_lang );
    $self->{publican}->{config}->param( 'scm', $tmp_scm ) if ($tmp_scm);

    my $dir = pushd("$tmp_dir/tar");
    my @files = dir_list( $tardir, '*' );
    Archive::Tar->create_archive( "../rpm/$tardir-$release.tgz", 9, @files );

    $dir = undef;

    my $common_config = $self->{publican}->param('common_config');
    my $xsl_file      = $common_config . "/xsl/web-spec.xsl";
    $xsl_file = $common_config . "/xsl/dt_htmlsingle_spec.xsl" if ($desktop);
    $xsl_file =~ s/"//g;    # windows
    my $license       = $self->{publican}->param('license');
    my $brand         = lc( $self->{publican}->param('brand') );
    my $doc_url       = $self->{publican}->param('doc_url');
    my $src_url       = $self->{publican}->param('src_url');
    my $dt_obsoletes  = $self->{publican}->param('dt_obsoletes') || "";
    my $web_obsoletes = $self->{publican}->param('web_obsoletes') || "";
    my $os_ver        = $self->{publican}->param('os_ver');
    my $translation   = ( $lang ne $xml_lang );
    my $language      = code2language( substr( $lang, 0, 2 ) );

    my $log = $self->change_log();
    my $abstract = $self->abstract( { lang => $lang } );

    my %xslt_opts = (
        'book-title'  => $name_start,
        'lang'        => $lang,
        'prod'        => $product,
        'prodver'     => $version,
        'rpmver'      => $edition,
        'rpmrel'      => $release,
        'docname'     => $docname,
        'license'     => $license,
        'brand'       => "publican-$brand",
        'url'         => $doc_url,
        'src_url'     => $src_url,
        'log'         => $log,
        dt_obsoletes  => $dt_obsoletes,
        web_obsoletes => $web_obsoletes,
        translation   => $translation,
        language      => $language,
        abstract      => $abstract,
        tmpdir        => $tmp_dir,
        ICONS         => ( -e "$xml_lang/icons" ? 1 : 0 ),
    );

    logger(
        "\t" . maketext( "Using XML::LibXSLT on [_1]", $xsl_file ) . "\n" );

    my $parser = XML::LibXML->new();
    my $xslt   = XML::LibXSLT->new();
    my $source
        = $parser->parse_file( "$tmp_dir/$lang/xml/$type" . '_Info.xml' );
    my $style_doc = $parser->parse_file($xsl_file);

    my $stylesheet = $xslt->parse_stylesheet($style_doc);

    my $results = $stylesheet->transform( $source,
        XML::LibXSLT::xpath_to_string(%xslt_opts) );

    my $outfile;
    my $spec_name = "$tmp_dir/rpm/$name_start-web-$lang.spec";
    $spec_name = "$tmp_dir/rpm/$name_start-$lang.spec"
        if ( $desktop or $short_sighted );

    open( $outfile, ">:utf8", "$spec_name" )
        || croak( maketext( "Can't open spec file: [_1]", $@ ) );
    print( $outfile $stylesheet->output_string($results) );
    close($outfile);

    $self->build_rpm( { spec => $spec_name, binary => $binary } );

    return;
}

=head2 change_log

Generate an RPM style change log from $xml_lang/Revision_History.xml

=cut

sub change_log {
    my ( $self, $args ) = @_;

#    my $lang = delete( $args->{lang} ) || croak("lang is a mandatory argument");
#
#    if ( %{$args} ) {
#        croak "unknown args: " . join( ", ", keys %{$args} );
#    }

    my $xml_lang = $self->{publican}->param('xml_lang');
    my $log      = "";

    my $xml_doc = XML::TreeBuilder->new();
    $xml_doc->parse_file("$xml_lang/Revision_History.xml");

    $xml_doc->root()->look_down( "_tag", "revision" ) || croak(
        maketext(
            "Missing mandatory field '[_1]' in revision histroy.", 'revision'
        )
    );

    foreach my $revision ( $xml_doc->root()->look_down( "_tag", "revision" ) )
    {

        my $node = $revision->look_down( '_tag', 'date' ) || croak(
            maketext(
                "Missing mandatory field '[_1]' in revision histroy.", 'date'
            )
        );
        my $in_date = $node->as_trimmed_text();
        my $dt      = DateTime::Format::DateParse->parse_datetime($in_date)
            || croak(
            maketext( "Invalid date: '[_1]' in revision histroy.", $in_date )
            );
        my $date = $dt->strftime("%a %b %e %Y");

        $node = $revision->look_down( '_tag', 'firstname' ) || croak(
            maketext(
                "Missing mandatory field '[_1]' in revision histroy.",
                'firstname'
            )
        );
        my $firstname = $node->as_trimmed_text();

        $node = $revision->look_down( '_tag', 'surname' ) || croak(
            maketext(
                "Missing mandatory field '[_1]' in revision histroy.",
                'surname'
            )
        );
        my $surname = $node->as_trimmed_text();

        $node = $revision->look_down( '_tag', 'email' ) || croak(
            maketext(
                "Missing mandatory field '[_1]' in revision histroy.", 'email'
            )
        );
        my $email = $node->as_trimmed_text();

        $node = $revision->look_down( '_tag', 'revnumber' ) || croak(
            maketext(
                "Missing mandatory field '[_1]' in revision histroy.",
                'revnumber'
            )
        );
        my $revnumber = $node->as_trimmed_text();

        $log .= sprintf( "* %s %s %s <%s> %s\n",
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

=head2 abstract

Generate an RPM style description from $lang/$TYPE_Info.xml

=cut

sub abstract {
    my ( $self, $args ) = @_;

    my $lang = delete( $args->{lang} )
        || croak("lang is a mandatory argument");

    if ( %{$args} ) {
        croak "unknown args: " . join( ", ", keys %{$args} );
    }

    my $tmp_dir = $self->{publican}->param('tmp_dir');
    my $type    = $self->{publican}->param('type');

    my $xml_doc = XML::TreeBuilder->new();
    $xml_doc->parse_file( "$tmp_dir/$lang/xml/$type" . '_Info.xml' );

    my $abstract = $xml_doc->root()->look_down( "_tag", "abstract" )
        || croak( maketext( "Missing mandatory field '[_1]'.", 'abstract' ) );

    $columns = 68;
    my $text = fill( "", "", $abstract->as_text() );
    $columns = $DEFAULT_WRAP;
    $text =~ s/^\s*//s;
    return ($text);
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

=head2 new_tree

Create a new XML::TreeBuilder object with the required attributes for DocBook.

TODO: Make XmlClean use this.

=cut

sub new_tree {

    my $store_comments = ( shift() || 0 );

    my $xml_doc = XML::TreeBuilder->new(
        { 'NoExpand' => "1", 'ErrorContext' => "2" } );
    my $empty_element_map = $xml_doc->_empty_element_map;
    $empty_element_map->{'xref'}       = 1;
    $empty_element_map->{'index'}      = 1;
    $empty_element_map->{'imagedata'}  = 1;
    $empty_element_map->{'area'}       = 1;
    $empty_element_map->{'ulink'}      = 1;
    $empty_element_map->{'xi:include'} = 1;

    $xml_doc->store_comments(1) if ($store_comments);

    return ($xml_doc);
}

=head2 dtd_string

Returns a valid DTD for the DocBook tag supplied.

Parameters:
	tag	 The root tag for this file
	dtdver	 The DTD version
	ent_file An entity file to include (optional)

=cut

sub dtd_string {
    my ($args) = @_;
    my $tag = delete( $args->{tag} )
        || croak( maketext("tag is a mandatory argument") );
    my $dtdver = delete( $args->{dtdver} )
        || croak( maketext("dtdver is a mandatory argument") );
    my $ent_file = delete( $args->{ent_file} );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    my $uri = qq|http://www.oasis-open.org/docbook/xml/$dtdver/docbookx.dtd|;
    my $dtd_type = qq|-//OASIS//DTD DocBook XML V$dtdver//EN|;

    if ( 0 && $TEST_MML ) {
        $dtd_type = '-//OASIS//DTD DocBook MathML Module V1.0//EN';
        $uri
            = 'http://www.oasis-open.org/docbook/xml/mathml/1.0/dbmathml.dtd';
    }

    # TODO Maynot be necessary
    if ( $^O eq 'MSWin32' ) {
        eval { require Win32::TieRegistry; };
        croak(
            maketext(
                "Failed to load Win32::TieRegistry module. Error: [_1]", $@
            )
        ) if ($@);

        my $key = new Win32::TieRegistry( "LMachine\\Software\\Publican",
            { Delimiter => "\\" } );

        $uri = 'file:///D:/Data/temp/Redhat/DTD/docbookx.dtd';

        if ( $key and $key->GetValue("dtd_path") ) {
            $uri = 'file:///' . $key->GetValue("dtd_path") . '/docbookx.dtd';
        }

        $uri =~ s/ /%20/g;
        $uri =~ s/\\/\//g;
    }

    my $dtd = <<DTDHEAD;
<?xml version='1.0' encoding='utf-8' ?>
<!DOCTYPE $tag PUBLIC "$dtd_type" "$uri" [
DTDHEAD

    if ($TEST_MML) {
        $dtd .= <<MML;
<!ENTITY % MATHML.prefixed "INCLUDE">
<!ENTITY % MATHML.prefix "mml">
<!ENTITY % equation.content "(alt?, (graphic+|mediaobject+|mml:math))">
<!ENTITY % inlineequation.content
               "(alt?, (inlinegraphic+|inlinemediaobject+|mml:math))">
<!ENTITY % mathml PUBLIC "-//W3C//DTD MathML 2.0//EN"
       "http://www.w3.org/Math/DTD/mathml2/mathml2.dtd">
%mathml;
MML
    }

    # handle entity file
    if ($ent_file) {
        $dtd .= <<ENT;
<!ENTITY % BOOK_ENTITIES SYSTEM "$ent_file">
%BOOK_ENTITIES;
ENT
    }

    $dtd .= <<DTDTAIL;
]>
DTDTAIL

    return ($dtd);
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
L<https://bugzilla.redhat.com/bugzilla/enter_bug.cgi?product=Fedora&amp;version=rawhide&amp;component=publican>.


=head1 AUTHOR

Jeff Fearn  C<< <jfearn@redhat.com> >>
