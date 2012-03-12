package Publican;

use utf8;
use warnings;
use strict;
use Carp;
use Config::Simple '-strict';
use XML::TreeBuilder;
use I18N::LangTags::List;
use Term::ANSIColor qw(:constants uncolor);
use File::Find::Rule;
use XML::LibXSLT;
use XML::LibXML;
use File::HomeDir;
use Publican::Localise;

use vars
    qw(@ISA $VERSION @EXPORT @EXPORT_OK $SINGLETON $LOCALISE $SPEC_VERSION);

$VERSION = '3.0';
@ISA     = qw(Exporter AutoLoader);

@EXPORT
    = qw(dir_list debug_msg get_all_langs logger help_config maketext new_tree);

# Track when the SPEC file generation is incompatible.
$SPEC_VERSION = '3.0';

my $DEFAULT_CONFIG_FILE = 'publican.cfg';
my $DEBUG               = undef;
my $NOCOLOURS           = undef;
my $QUIET               = undef;

my %PARAM_OLD = (
    ARCH                       => 'arch',
    BOOKS                      => 'books',
    BRAND                      => 'brand',
    BREW_DIST                  => 'brew_dist',
    CHUNK_FIRST                => 'chunk_first',
    CHUNK_SECTION_DEPTH        => 'chunk_section_depth',
    CLASSPATH                  => 'classpath',
    COMMON_CONFIG              => '',
    COMMON_CONTENT             => '',
    CONDITION                  => 'condition',
    CONFIDENTIAL               => 'confidential',
    DEFAULT_LANGS              => '',
    DOCNAME                    => '',
    DOC_TYPE                   => 'type',
    DOC_URL                    => 'doc_url',
    DTD_VER                    => 'dtdver',
    DT_OBSOLETES               => 'dt_obsoletes',
    GENERATE_SECTION_TOC_LEVEL => 'generate_section_toc_level',
    IGNORED_TRANSLATIONS       => 'ignored_translations',
    LICENSE                    => 'license',
    OS_VER                     => 'os_ver',
    PRODUCT                    => '',
    PROD_URL                   => 'prod_url',
    PROD_VERSION               => '',
    PROGNAME                   => '',                             # l10n
    SET_REPO                   => 'repo',
    SET_REPO_TYPE              => 'scm',
    SHOW_REMARKS               => 'show_remarks',
    SOURCE                     => '',                             # l10n
    SRC_URL                    => 'src_url',
    TRANSLATIONS               => '',
    TOC_SECTION_DEPTH          => 'toc_section_depth',
    WEB_BREW_DIST              => 'web_brew_dist',
    WEB_OBSOLETES              => 'web_obsoletes',
    XMLFILE                    => '',
    XML_LANG                   => 'xml_lang',
);

# All the valid fields in the publican.cfg file
# constraint: a regex to validate the content
my %PARAMS = (

    arch => {
        descr => maketext('Arch to filter output on.'),

    },
    books => {
        descr => maketext(
            'A space-separated list of books used in this remote set.'),

    },
    banned_attrs => {
        descr => maketext(
            'A comma-separated list of XML attributes that are not permitted in the source.'
        ),
        limit_to => 'brand',
    },
    banned_tags => {
        descr => maketext(
            'A comma-separated list of XML tags that are not permitted in the source.'
        ),
        limit_to => 'brand',
    },
    base_brand => {
        descr    => maketext('The base brand to use for this brand.'),
        default  => 'common',
        limit_to => 'brand',
    },
    brand => {
        descr   => maketext('The brand to use when building this package.'),
        default => 'common',

    },
    brew_dist => {
        descr => maketext(
            'The brew dist to use for building the standalone desktop rpm.'),
        default => 'docs-5E',

    },
    bridgehead_in_toc => {
        descr   => maketext('Display bridge head elements in the TOCs?'),
        default => 0,
    },
    chunk_first => {
        descr => maketext(
            'For HTML, should the first section be on the same page as its parent?'
        ),
        default => 0,

    },
    chunk_section_depth => {
        descr => maketext(
            'For HTML, what is the deepest level of nesting at which a section should be split onto its own page?'
        ),
        default => 4,
    },
    classpath => {
        descr => maketext('Path to jar files for FOP.'),
        default =>
            '/usr/share/java/ant/ant-trax-1.7.0.jar:/usr/share/java/xmlgraphics-commons.jar:/usr/share/java/batik-all.jar:/usr/share/java/xml-commons-apis.jar:/usr/share/java/xml-commons-apis-ext.jar',
    },
    common_config => {
        descr   => maketext('Path to publican content.'),
        default => '/usr/share/publican',

    },
    common_content => {
        descr   => maketext('Path to publican common content.'),
        default => '/usr/share/publican/Common_Content',

    },
    condition => {
        descr => maketext(
            'Conditions on which to prune XML before transformation.'),

    },
    confidential => {
        descr   => maketext('Is the content confidential?'),
        default => 0,
    },
    confidential_text => {
        descr =>
            maketext('The text used to indicate content is confidential.'),
        default => maketext('CONFIDENTIAL'),
    },
    debug => {
        descr   => maketext('Print out extra messages?'),
        default => 0,

    },
    docname => {
        descr => maketext(
            'Name of this package. Fetched from title tag in xml_lang/TYPE_Info.xml if not set in cfg file.'
        ),
        constraint => '[^0-9a-zA-Z_\-\.\+]',
    },
    doc_url => {
        descr => maketext(
            'URL for the documentation team for this package. Used for top right URL on HTML.'
        ),
        default => 'https://fedorahosted.org/publican',

    },
## BUGBUG this should be ripped from file header
    dtdver => {
        descr => maketext(
            'Version of the DocBook DTD on which this project is based.'),
        default => '4.5',
#        default => '5.1b4',

    },
    dt_obsoletes => {
        descr => maketext(
            'Space-separated list of packages the desktop package obsoletes.'
        ),

    },
    dt_requires => {
        descr => maketext(
            'Space-separated list of packages the desktop package requires.'),

    },
    'ec_id' => {
        descr =>
            maketext('Eclipse plugin ID. Defaults to "$product.$docname"'),
    },
    'ec_name' => {
        descr =>
            maketext('Eclipse plugin name. Defaults to "$product $docname"'),
    },
    'ec_provider' => {
        descr => maketext(
            'Eclipse plugin provider. Defaults to "Publican-[_1]"', $VERSION
        ),
    },
    generate_section_toc_level => {
        descr => maketext(
            'Generate table of contents down to the given section depth.'),
        default => 0,

    },
    ignored_translations => {
        descr => maketext(
            'Languages to replace with xml_lang regardless of translation status.'
        ),

    },
    license => {
        descr   => maketext('License this package uses.'),
        default => 'GFDL',

    },
    mainfile => {
        descr => maketext(
            'The name of the main xml and ent files for this books, sans file extension and language. Fetched from docname if not set.'
        ),
    },
    menu_category => {
        descr => maketext(
            'Semicolon-separated list of menu categories for the desktop package.'
        ),
    },
    no_embedtoc => {
        descr => maketext(
            'Brand option to disable embedding the navigational toc in web packages'
        ),
        limit_to => 'brand',
    },
    os_ver  => { descr => maketext('The OS for which to build packages.'), },
    product => {
        descr => maketext(
            'Product this package covers. Fetched from productname tag in xml_lang/TYPE_Info.xml'
        ),
        constraint => '[^0-9a-zA-Z_\-\.\+]',

    },
    prod_url => {
        descr =>
            maketext('URL for the product. Used in top left URL in HTML.'),
        default => 'https://fedorahosted.org/publican',

    },
    repo => {
        descr => maketext('Repository from which to fetch remote set books.'),
    },
    scm => {
        descr => maketext(
            'Type of repository in which books that form part of a remote set are stored. Supported types: SVN.'
        ),
    },
    show_remarks => {
        descr   => maketext('Display remarks in transformed output.'),
        default => 0,

    },
    show_unknown => {
        descr   => maketext('Report unknown tags when processing XML.'),
        default => 1,

    },
    src_url => {
        descr => maketext(
            'URL to find tar of source files. Used in RPM Spec files.'),
    },
    tmp_dir => {
        descr   => maketext('Directory to use for building.'),
        default => 'tmp',

    },
    toc_section_depth => {
        descr => maketext(
            'Depth of sections to include in the main table of contents.'),
        default => 2,

    },
    type => {
        descr => maketext(
            'Type of content this package contains. Supported: set, book, article, brand'
        ),
        default => 'Book',

    },
    txt_formater => {
        descr => maketext(
            'Choose the formatter to use when creating txt output.'
        ),
        constraint => '(?:links|tables|)',
    },
    version => {
        descr => maketext(
            'Version of this package. Fetched from productnumber tag in xml_lang/TYPE_Info.xml'
        ),
        constraint => '^[^0-9]',
    },
    web_brew_dist => {
        descr   => maketext('The brew dist to use for building the web rpm.'),
        default => 'docs-5E',
    },
    web_formats => {
        descr => maketext(
            'A comma-separated list of the formats to use for the web packages.'
        ),
        default => 'html,html-single,pdf,epub',
    },
    web_home => {
        descr => maketext(
            'This is a home page for a Publican-generated website, not a standard book.'
        ),
        alert =>
            'web_home is deprecated and will be removed from Publican in the future. Use "web_type: home" instead.',
    },
    web_style => {
        descr => maketext(
            'Splash pages should be generated to be comaptible with this web style. Valid values are 1 and 2.'
        ),
        constraint => '[^1-2]',
        default    => '1',
    },
    web_type => {
        descr => maketext(
            'This is a special page for a Publican-generated website, not a standard book. Valid types are home, product, and version.'
        ),
    },
    web_host => {
        descr => maketext(
            'This is a host name for a Publican-generated website, used for searches and the Sitemap. Be sure to include the full path to your document tree. E.g. if your documents are in the docs directory: http://www.example.com/docs'
        ),
        alert =>
            'web_host is deprecated and will be removed from Publican in the future. Use "host" in the web site configuration file instead.',
    },
    web_obsoletes =>
        { descr => maketext('Packages to obsolete in web RPM.'), },
    web_search => {
        descr => maketext(
            'Override the default search form for a Publican website. By default this will use Google search and do a site search if web_host is set.'
        ),
        alert =>
            'web_search is deprecated and will be removed from Publican in the future. Use "search" in the web site configuration file instead.',
    },
    web_name_label => {
        descr => maketext(
            'Override the book name, bottom level, menu label on a Publican website.'
        ),
    },
    web_product_label => {
        descr => maketext(
            'Override the product, top level, menu label on a Publican website.'
        ),
    },
    web_version_label => {
        descr => maketext(
            'Override the version, middle level, menu label on a Publican website. To hide this menu item set this to: UNUSED'
        ),
    },
    web_cfg => {
        descr => maketext(
            'Full path for the publican site configuration file for non standard RPM websites.'
        ),
        limit_to => 'brand',
    },
    web_dir => {
        descr    => maketext('Install path for non standard RPM websites.'),
        limit_to => 'brand',
    },
    web_req => {
        descr => maketext(
            'Name of site package for non standard RPM websites. Required to ensure the site is installed.'
        ),
        limit_to => 'brand',
    },
    xml_lang => {
        descr   => maketext('Language in which XML is authored.'),
        default => 'en-US',
    },

);

# Setup localisation ASAP
BEGIN {
    if ( !$LOCALISE ) {
        $LOCALISE = Publican::Localise->get_handle()
            || croak("Could not create a Publican::Localise object");
        $LOCALISE->encoding("UTF-8");
        $LOCALISE->textdomain("publican");
    }
}

=head1 NAME

Publican - Used to control settings for sub modules.


=head1 VERSION

This document describes Publican version $VERSION


=head1 SYNOPSIS

    use Publican;

    my $publican = Publican->new({DEBUG => 1});

=head1 DESCRIPTION

Handles general configuration of all sub modules.

=head1 INTERFACE 

=cut

# Module implementation here

=head2 _load_config

Private method for loading a config file

=cut

sub _load_config {
    my ( $self, $args ) = @_;

    my $configfile = ( delete( $args->{configfile} )
            || croak( maketext("configfile is a mandatory argument") ) );
    my $common_config  = delete( $args->{common_config} );
    my $common_content = delete( $args->{common_content} );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }
    if ( not -f $configfile ) {

        croak(
            maketext(
                "Config file not found: [_1].",
                $configfile
            )
        );
    }

    my $config = new Config::Simple();
    $config->syntax('http');
    $config->read($configfile)
        || croak(
        maketext( "Failed to load config file: [_1]", $configfile ) );

    foreach my $def ( keys(%PARAMS) ) {
        if (defined $PARAMS{$def}->{limit_to}
            && (defined $PARAMS{$def}->{limit_to}
                && (lc( ( $config->param('type') || 'book' ) ) ne
                    lc( $PARAMS{$def}->{limit_to} ) )
            )
            )
        {
            $config->delete($def);
            next;
        }

        if ( defined $PARAMS{$def}->{default}
            and not defined( $config->param($def) ) )
        {
            $config->param( $def, $PARAMS{$def}->{default} );
        }

        # Output alerts about a parameter
        if (    defined $PARAMS{$def}->{alert}
            and defined( $config->param($def) ) )
        {
            _alert( $PARAMS{$def}->{alert} . "\n" );
        }

        # delete any bogus empty fields
        my $tmp = $config->param($def);
        if (   ( not defined $tmp )
            or ( $tmp eq "" )
            or ( ref $tmp eq "ARRAY" and $#{$tmp} == -1 ) )
        {
            $config->delete($def);
        }
    }

    $config->param( 'common_config',  $common_config )  if $common_config;
    $config->param( 'common_content', $common_content ) if $common_content;

    $self->{configfile} = $configfile;
    $self->{config}     = $config;

    my $type     = $config->param('type');
    my $xml_lang = $config->param('xml_lang');
    my $brand    = $config->param('brand');

    # don't try and load version info for brand files
    if ( $type ne 'brand' ) {
        croak(
            maketext(
                "Can't locate required file: [_1]",
                "$xml_lang/$type" . '_Info.xml'
            )
        ) if ( !-f "$xml_lang/$type" . '_Info.xml' );

        my $xml_doc = XML::TreeBuilder->new();
        $xml_doc->parse_file( "$xml_lang/$type" . '_Info.xml' );

        my $docname = $config->param('docname');

        eval { $docname = $xml_doc->root()->look_down( "_tag", "title" )->as_text(); }
            unless defined($docname);
        if ($@) {
            croak maketext("title not found in Info file");
        }
        $docname =~ s/\s/_/g;

        my $product = $config->param('product');

        eval {
            $product = $xml_doc->root()->look_down( "_tag", "productname" )->as_text();
        } unless defined($product);
        if ($@) {
            croak maketext("productname not found in Info file");
        }
        $product =~ s/\s/_/g;

        my $version = $config->param('version');
        eval {
            $version = $xml_doc->root()->look_down( "_tag", "productnumber" )->as_text();
        } unless defined($version);
        if ($@) {
            croak maketext("productnumber not found in Info file");
        }

        my ( $edition, $release )
            = $self->get_ed_rev( { lang => $xml_lang } );

        if ( not defined( $self->{config}->param('mainfile') ) ) {
            $self->{config}->param( 'mainfile', $docname );
        }

        $self->{config}->param( 'docname', $docname );
        $self->{config}->param( 'product', $product );
        $self->{config}->param( 'version', $version );
        $self->{config}->param( 'release', $release );
        $self->{config}->param( 'edition', $edition );

        my $path = $self->{config}->param('common_content') . "/$brand";
        $path =~ s/\"//g;

        # Override publican defaults with brand defaults
        if ( -f "$path/defaults.cfg" ) {
            my $tmp_cfg = new Config::Simple("$path/defaults.cfg")
                || croak(
                maketext("Failed to load brand defaults.cfg file") );
            my %Config = $tmp_cfg->vars();
            foreach my $cfg ( keys(%Config) ) {

          # If a book key is unset or equals the publican default, Override it
                if (   ( !$self->{config}->param($cfg) )
                    or ( !defined( $PARAMS{$cfg}->{default} ) )
                    or ( $self->{config}->param($cfg) eq
                        $PARAMS{$cfg}->{default} )
                    )
                {
                    $self->{config}->param( $cfg, $Config{$cfg} );
                }
            }
        }

        # Enforce Brand Overrides
        if ( -f "$path/overrides.cfg" ) {
            my $tmp_cfg = new Config::Simple("$path/overrides.cfg")
                || croak(
                maketext("Failed to load brand overrides.cfg file") );
            my %Config = $tmp_cfg->vars();
            foreach my $cfg ( keys(%Config) ) {
                $config->param( $cfg, $Config{$cfg} );
            }
        }

        # Brand Settings
        my $brand_cfg = new Config::Simple("$path/publican.cfg")
            || croak(
            maketext(
                "Failed to load brand file: [_1]",
                "$path/publican.cfg"
            )
            );

        $self->{brand_config} = $brand_cfg;

        $config->param( 'ec_name', "$product $docname" )
            unless defined $config->param('ec_name');
        $config->param( 'ec_id', "org.$product.$docname" )
            unless defined $config->param('ec_id');
        $config->param( 'ec_provider', "Publican-$VERSION" )
            unless defined $config->param('ec_provider');
    }
    $DEBUG = $self->{config}->param('debug') if ( !$DEBUG );

    return;
}

=head2 _validate_config

Private method for validating configuration

=cut

sub _validate_config {
    my ( $self, $args ) = @_;

    foreach my $key ( keys(%PARAMS) ) {
        if ( defined $PARAMS{$key}->{constraint} ) {
            my $value      = $self->{config}->param($key);
            my $constraint = $PARAMS{$key}->{constraint};
            if ( $value && $value =~ /$constraint/ ) {
                croak(
                    maketext(
                        "Invalid format for [_1]. Value ([_2]) does not conform to constraint ([_3])",
                        $key, $value, $constraint
                    )
                );
            }
        }
    }

    return;
}

=head2  new

Create a Publican object.

my $publican = Publican->new({debug => 1});

=head3 Parameters:

   configfile       Override Configuration file to use.
   debug            Use debug mode for messages.
   common_config    Override path to coomo configuration files.
   common_content   Override path to common content files.

=cut

sub new {
    my ( $this, $args ) = @_;
    my $class = ref($this) || $this;

    my $self;
    if ($SINGLETON) {
        $self = $SINGLETON;
    }
    else {
        my $configfile
            = ( delete( $args->{configfile} ) || $DEFAULT_CONFIG_FILE );
        $DEBUG = ( delete( $args->{debug} ) || $DEBUG );
        my $common_config  = delete( $args->{common_config} );
        my $common_content = delete( $args->{common_content} );
        $QUIET     = delete( $args->{QUIET} );
        $NOCOLOURS = delete( $args->{NOCOLOURS} );

        if ( %{$args} ) {
            croak(
                maketext(
                    "unknown arguments: [_1]",
                    join( ", ", keys %{$args} )
                )
            );
        }

        $self = bless {}, $class;
        $SINGLETON = $self;

        if ( $^O eq 'MSWin32' ) {
            eval { require Win32::TieRegistry; };
            croak(
                maketext(
                    "Failed to load Win32::TieRegistry module. Error: [_1]",
                    $@
                )
            ) if ($@);

            $ENV{ANSI_COLORS_DISABLED} = 1;

            my $key = new Win32::TieRegistry( "LMachine\\Software\\Publican",
                { Delimiter => "\\" } );

            if ( $key and $key->GetValue("") ) {
                if ( !$common_config ) {
                    $common_config = $key->GetValue("");
                    $common_config =~ s/\\/\//g;
                }
                $common_content = "$common_config/Common_Content"
                    if ( !$common_content );
            }

            $common_config  = qq{"$common_config"}  if ($common_config);
            $common_content = qq{"$common_content"} if ($common_content);
        }
        elsif ( $^O eq 'darwin' ) {
            if ( !$common_config ) {
                $common_config = '/opt/local/share/publican';
            }
            if ( !$common_content ) {
                $common_content = "$common_config/Common_Content";
            }
        }

        $self->_load_config(
            {   configfile     => $configfile,
                common_config  => $common_config,
                common_content => $common_content
            }
        );

        debug_msg( maketext("config loaded") . "\n" );

        $self->_validate_config();
    }

    return $self;
}

=head2  debug_msg

Print out debugging information.

=cut

sub debug_msg {
    my ($arg) = @_;
    my ( $caller, $func, $line, @rest ) = caller(1);    # caller(0) eg
                                                        # Complete, caller(1)
                                                        # eg readline

    # bail ASAP if not debugging
    if ( !$DEBUG ) {
        return;
    }

    ($caller) = caller(0);

    #    $caller =~ s/.*:://;

    $arg  = "" unless defined $arg;
    $func = "" unless defined $func;
    $line = "" unless defined $line;

    my $rest = join "|", map { defined $_ ? $_ : "UNDEF" } @rest;

    logger( "\nDEBUG: ", RED );
    if ( 0 and $arg and ref $arg ) {
        eval { require Data::Dumper };
        if ($@) {
            logger( $arg->as_string, RED );
        }
        else {
            logger( Data::Dumper::Dumper($arg), RED );
        }
    }
    else {

        #        logger( "$caller: $func, $line\n\t$arg\n", RED );
        logger( "$caller: $arg", RED );
    }

    return;
}

sub _alert {
    my ($msg) = @_;
    logger( $msg, RED );

    return;
}

=head2 param

Return the current value of a configuration parameter

$publican->param('debug');

=cut

sub param {
    my ( $self, $name ) = @_;

    return $self->{config}->param($name)
        if defined( $self->{config}->param($name) );

    return $PARAMS{$name}->{default} if defined $PARAMS{$name}->{default};

    return;
}

=head2 help_config

Display a list of config file parameters and a short description of them.

=cut

sub help_config {
    my ( $self, $name ) = @_;
    logger( maketext("Parameters used in the config file:") . "\n" );

    foreach my $param ( sort( keys(%PARAMS) ) ) {
        logger( "\t$param:\n\t\t" . $PARAMS{$param}->{descr} . "\n" );
        logger(   "\t\t"
                . maketext( "Default: [_1]", $PARAMS{$param}->{default} )
                . "\n" )
            if ( defined( $PARAMS{$param}->{default} ) );
        logger( "\t\t"
                . maketext( "Constraint: [_1]",
                $PARAMS{$param}->{constraint} )
                . "\n" )
            if ( defined( $PARAMS{$param}->{constraint} ) );

        logger("\n");
    }

    return;
}

=head2 dir_list

list all the files in a directory, and its sub-directories, matching the supplied regex.

=cut

sub dir_list {
    my ( $dir, $regex, $clean_images ) = @_;
    croak( maketext("dir is a required argument") ) unless ($dir);

    unless ( -d $dir ) {
        logger( maketext( "skipping non existent directory: [_1]", $dir ) );
        return;
    }

    croak( maketext("regex is a required argument") )
        if ( !$regex || $regex eq "" );

    my @filelist;
    my $rule = File::Find::Rule->new;

    if ( $regex =~ m/[|()]/ ) {
        $rule->file->name(qr/$regex/);
    }
    else {
        $rule->file->name($regex);
    }

    $rule->start($dir);
    while ( my $file = $rule->match ) {
        push( @filelist, $file )
            unless ( $clean_images
            and $file =~ m{(/extras/|/icons/|images/icon.svg)} );
    }

    return @filelist;
}

=head2 get_all_langs

Get all valid language directories.

=cut

sub get_all_langs {

    my ( $handle, %filelist, @langs );
    my $tmp_dir = $SINGLETON->param('tmp_dir');

    opendir( $handle, '.' )
        || croak( maketext( "Can't open directory: [_1]", $@ ) );
    my @dirs = sort( readdir($handle) );
    closedir($handle);

    foreach my $dir (@dirs) {
        if ( -d $dir ) {
            next
                if (
                $dir =~ /^(\.|\.\.|pot|$tmp_dir|xsl|\..*|CVS|publish)$/ );

            if ( valid_lang($dir) ) {
                push( @langs, $dir );
            }
            else {
                logger( maketext( "Skipping unknown language: [_1]", $dir )
                        . "\n" );
            }
        }
    }

    return ( join( ',', @langs ) );
}

=head2 logger

Log something, currently emits to STDOUT

TODO: consider using Log::Dispatch or similar

=cut

sub logger {
    my ( $msg, $colour ) = @_;

    return if ($QUIET);

    if ( $colour && !$NOCOLOURS ) {
        print( STDOUT $colour, $msg, RESET );
    }
    else {
        print( STDOUT $msg );
    }

    return;
}

=head2 valid_lang

Is the requested language valid according to I18N::LangTags::List

=cut

sub valid_lang {
    my $lang = shift;
    my $name = ( I18N::LangTags::List::name($lang) || '' );

    return ( I18N::LangTags::List::is_decent($lang) && ( $name ne '' ) );
}

=head2 maketext

Get localised strings

=cut

sub maketext {
    my $string = shift();
    my @params = @_;

    if ($LOCALISE) {
        return ( $LOCALISE->maketext( $string, @params ) );
    }
    else {
        carp( RED, "Warning localisation not enabled!\n", RESET );
    }

    return ($string);
}

=head2 get_abstract

Return the abstract for the supplied langauge with all white space truncted.

=cut

sub get_abstract {
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

    my $tmp_dir = $self->param('tmp_dir');
    my $info_file
        = "$tmp_dir/$lang/xml/" . $self->param('type') . '_Info.xml';

    croak( maketext("abstract can not be calculated before building.") )
        unless ( -f $info_file );

    my $xsl_file = $self->param('common_config') . "/xsl/abstract.xsl";

    my $abstract = $self->run_xslt(
        { xml_file => $info_file, xsl_file => $xsl_file } );

    # tidy up white space
    $abstract =~ s/^[ \t]*//gm;
    $abstract =~ s/^\n\n+//;
    $abstract =~ s/\n\n+$//;
    $abstract =~ s/\n\n\n/\n\n/g;
    $abstract =~ s/[ \t][ \t]+/ /gm;

    # RPM doesn't like non-breaking-space
    $abstract =~ s/\x{A0}/ /gm;
    return ($abstract);
}

=head2 get_subtitle

Return the subtitle for the supplied langauge with white space truncted.

=cut

sub get_subtitle {
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

    my $tmp_dir = $self->param('tmp_dir');
    my $info_file
        = "$tmp_dir/$lang/xml/" . $self->param('type') . '_Info.xml';

    croak( maketext("subtitle can not be calculated before building.") )
        unless ( -f $info_file );

    my $xsl_file = $self->param('common_config') . "/xsl/subtitle.xsl";

    my $subtitle = $self->run_xslt(
        { xml_file => $info_file, xsl_file => $xsl_file } );

    # tidy up white space
    $subtitle =~ s/^\s*//gm;

    # RPM doesn't like non-breaking-space
    $subtitle =~ s/\x{A0}/ /gm;
    $subtitle =~ s/\s+/ /;

    return ($subtitle);
}

=head2 run_xslt

Apply the supplied xslt file to teh supplied XML and return a string of the output.

=cut

sub run_xslt {
    my ( $self, $args ) = @_;
    my $xml_file = delete( $args->{xml_file} )
        || croak( maketext("xml_file is a mandatory argument") );
    my $xsl_file = delete( $args->{xsl_file} )
        || croak( maketext("xsl_file is a mandatory argument") );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    my $parser = XML::LibXML->new();
    my $xslt   = XML::LibXSLT->new();
    $parser->expand_entities(1);
    my $source;
    eval { $source = $parser->parse_file($xml_file); };

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
    my $results    = $stylesheet->transform($source);
    my $value;
    eval { $value = $stylesheet->output_string($results) };

    return ($value);
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

=head2  print_banned_tags

Print a list of tags that are not supported.

=cut

sub print_banned_tags {
    my $self = shift();
    print "\n"
        . maketext(
        "NOTE: These lists of tags and attributes are brand specific and are not part of Publican itself."
        ) . "\n\n";

    print "\n" . maketext("Banned tags:") . "\n";
    foreach my $key (
        sort( split( /,/, ( $self->param('banned_tags') || "" ) ) ) )
    {
        print("\t$key\n");
    }

    print "\n" . maketext("Banned attributes:") . "\n";
    foreach my $attr (
        sort( split( /,/, ( $self->param('banned_attrs') || "" ) ) ) )
    {
        print("\t$attr\n");
    }
    print "\n";

    return;
}

=head2 add_revision

Add a full entry in to the revision history.

=cut

sub add_revision {
    my ( $self, $args ) = @_;
    my $lang = delete( $args->{lang} )
        || croak( maketext("lang is a required option for add_revision") );
    my $members = delete( $args->{members} )
        || croak( maketext("member is a required option for add_revision") );

    my $revnumber = delete( $args->{revnumber} );
    my $date      = delete( $args->{date} );
    my $firstname = delete( $args->{firstname} );
    my $surname   = delete( $args->{surname} );
    my $email     = delete( $args->{email} );

    unless ($revnumber) {
        my ( $edition, $release )
            = $self->get_ed_rev( { lang => $lang, bump => 1 } );
        $revnumber = "$edition-$release";
    }

    unless ($date) {
        $date = DateTime->now()->strftime("%a %b %e %Y");
    }

    my $configfile = File::HomeDir->my_home() . "/.publican.cfg";
    if ( -f $configfile ) {
        my $user_cfg = new Config::Simple();
        $user_cfg->syntax('http');
        $user_cfg->read($configfile)
            || croak(
            maketext( "Failed to load user config file: [_1]", $configfile )
            );

        $firstname = $user_cfg->param('firstname')
            || croak("firstname is a required field in the user config file")
            unless ($firstname);

        $surname = $user_cfg->param('surname')
            || croak("surname is a required field in the user config file")
            unless ($surname);

        $email = $user_cfg->param('email')
            || croak("email is a required field in the user config file")
            unless ($email);
    }

    croak("firstname is a required field")
        unless ($firstname);
    croak("surname is a required field")
        unless ($surname);
    croak("email is a required field") unless ($email);

    my $revision = XML::Element->new_from_lol(
        [   'revision',
            [ 'revnumber', $revnumber ],
            [ 'date',      $date ],
            [   'author',
                [ 'firstname', $firstname ],
                [ 'surname',   $surname ],
                [ 'email',     $email ],
            ],
            [   'revdescription',
                [ 'simplelist', map { [ 'member', $_ ] } @{$members}, ],
            ],
        ],
    );

    my $rev_file = "$lang/Revision_History.xml";
    my $node;
    my $rev_doc = new_tree();

    if ( -f $rev_file ) {
        $rev_doc->parse_file($rev_file);
    }
    else {
        $rev_doc->root()->tag('appendix');
        my $rev_hist
            = XML::Element->new_from_lol(
            [ 'title', maketext('Revision History') ],
            );

        $rev_doc->root()->push_content($rev_hist);

        $rev_hist
            = XML::Element->new_from_lol( [ 'simpara', ['revhistory'], ], );

        $rev_doc->root()->push_content($rev_hist);
    }

    eval { $node = $rev_doc->root()->look_down( "_tag", "revhistory" ); };
    if ($@) {
        croak( maketext( "revhistory not found in [_1]", $rev_file ) );
    }

    $node->unshift_content($revision);

    my $OUTDOC;
    open( $OUTDOC, ">:encoding(UTF-8)", "$rev_file" )
        || croak( maketext( "Could not open [_1] for output!", $rev_file ) );
    print( $OUTDOC $rev_doc->root()->as_XML() );
    close($OUTDOC);
    $rev_doc->root()->delete();

    my $cleaner = Publican::XmlClean->new( { exclude_ent => 1 } );
    $cleaner->process_file( { file => $rev_file, out_file => $rev_file } );

    return;
}

=head2 get_ed_rev

Get the current edition (version) and release from the Revision History file.

Parameters: language, bump.

If bump is set the returned revision will increment before it's returned.

=cut

sub get_ed_rev {
    my ( $self, $args ) = @_;

    my $lang = delete( $args->{lang} )
        || croak( maketext("'lang' is a required option for get_ed_rev") );
    my $bump = delete( $args->{bump} );

    my $rev_file = "$lang/Revision_History.xml";
    croak( maketext( "Can't locate required file: [_1]", $rev_file ) )
        if ( !-f $rev_file );

    my $rev_doc = XML::TreeBuilder->new();
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
            $VR, '^([0-9.]*)-([0-9.]*)$/'
        )
    );

    my $edition = $1;
    my $release = $2;
    $release =~ s/(\d+)$/(1+$1)/e if ($bump);

    return ( ( $edition, $release ) );
}

1;    # Magic true value required at end of module
__END__

=head1 DIAGNOSTICS

=over

=item C<< unknown args %s >>

All subs with named parameters will return this error when unexpected named arguments are provided.

=item C<< %s is a required argument >>

Any sub with a mandatory parameter will return this error if the parameter is undef.

=item C<< Config file not found: %s >>

publican can not find the named configuration file.

=item C<< Failed to load config file: %s >>

The named configuration file could not be loaded.

=item C<< Can't locate required file: %s >>

A file required for processing could not be found.

=item C<< title not found in Info file >>

The <type>_Info.xml file does not contain a title tag.

=item C<< productname not found in Info file >>

The <type>_Info.xml file does not contain a productname tag.

=item C<< productnumber not found in Info file >>

The <type>_Info.xml file does not contain a productnumber tag.

=item C<< pubsnumber not found in Info file >>

The <type>_Info.xml file does not contain a pubsnumber tag.

=item C<< Failed to load brand default config file >>

A detected defaults.cfg for the current brand could not be loaded.

=item C<< Failed to load brand overrides config file >>

A detected overrides.cfg for the current brand could not be loaded.

=item C<< Could not create a Publican::Localise object >>

Could not create a Publican::Localise object

=item C<< Can't open directory >>

=back


=head1 CONFIGURATION AND ENVIRONMENT

Publican requires no configuration files or environment variables.

=head1 DEPENDENCIES

Carp
version
Config::Simple
XML::TreeBuilder
I18N::LangTags::List
Term::ANSIColor
File::Find::Rule;
Publican::Localise;


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<publican-list@redhat.com>, or through the web interface at
L<https://bugzilla.redhat.com/bugzilla/enter_bug.cgi?product=Publican&amp;component=publican>.

=head1 AUTHOR

Jeff Fearn  C<< <jfearn@redhat.com> >>
