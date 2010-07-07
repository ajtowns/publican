package Publican;

use utf8;
use warnings;
use strict;
use Carp;
use Config::Simple;
use XML::TreeBuilder;
use I18N::LangTags::List;
use Term::ANSIColor qw(:constants uncolor);
use File::Find::Rule;
use Makefile::Parser;

use Publican::Localise;

use vars qw(@ISA $VERSION @EXPORT @EXPORT_OK $SINGLETON $LOCALISE);

$VERSION = '2.1';
@ISA     = qw(Exporter AutoLoader);

@EXPORT
    = qw(dir_list debug_msg get_all_langs logger help_config maketext old2new);

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
    STRICT                     => 'strict',
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
    brand => {
        descr   => maketext('The brand to use when building this package.'),
        default => 'common',

    },
    brew_dist => {
        descr => maketext(
            'The brew dist to use for building the standalone desktop rpm.'),
        default => 'docs-5E',

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
        descr   => maketext('The text used to indicate content is confidential.'),
        default => maketext('CONFIDENTIAL'),
    },
    cvs_root => {
        descr => maketext(
            'CVS root to import SRPM into. e.g. :ext:@cvs.fedoraproject.org:/cvs/pkgs'
        ),
    },
    cvs_pkg    => { descr => maketext('The name of the package in CVS.'), },
    cvs_branch => { descr => maketext('The Branch of the package in CVS.'), },
    debug      => {
        descr   => maketext('Print out extra messages?'),
        default => 0,

    },
    docname => {
        descr => maketext(
            'Name of this package. Fetched from title tag in xml_lang/TYPE_Info.xml'
        ),
        constraint => '[^a-zA-Z_\-0-9.]',
    },
    doc_url => {
        descr => maketext(
            'URL for the documentation team for this package. Used for top right URL on HTML.'
        ),
        default => 'https://fedorahosted.org/publican',

    },
    dtdver => {
        descr => maketext(
            'Version of the DocBook DTD on which this project is based.'),
        default => '4.5',

    },
    dt_obsoletes => {
        descr => maketext('List of desktop packages this package obsoletes.'),

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
        descr =>
            maketext('Eclipse plugin provider. Defaults to "Publican-[_1]"', $VERSION),
    },
    edition => {
        descr => maketext(
            'Edition of this package. Fetched from edition tag in xml_lang/TYPE_Info.xml'
        ),
        constraint => '[^0-9.]',

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
    max_image_width => {
        descr   => maketext('The maximum pixel width an image can be before it will be scaled.'),
        default => '444',

    },
    os_ver => {
        descr   => maketext('The OS for which to to build packages.'),
        default => '.el5',

    },
    product => {
        descr => maketext(
            'Product this package covers. Fetched from productname tag in xml_lang/TYPE_Info.xml'
        ),
        constraint => '[^a-zA-Z_\-]',

    },
    prod_url => {
        descr =>
            maketext('URL for the product. Used in top left URL in HTML.'),
        default => 'https://fedorahosted.org/publican',

    },
    release => {
        descr => maketext(
            'Release of this package. For xml_lang fetched from title tag in xml_lang/TYPE_Info.xml. For translations it is fetched from Project-Id-Version in lang/TYPE_Info.po'
        ),
        constraint => '[^0-9.]',
    },
    repo => {
        descr => maketext('Repository from which to fetch remote set books.'),
    },
    scm => {
        descr => maketext(
            'Type of repository Remote Set Books are stored in. Supported types: SVN.'
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
    strict => {
        descr => maketext(
            'Use strict mode, which prevents the use of tags considered unusable for professional output and translation.'
        ),
        default => 0,

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
    version => {
        descr => maketext(
            'Version of this package. Fetched from productnumber tag in xml_lang/TYPE_Info.xml'
        ),
        constraint => '[^0-9.]',
    },
    web_brew_dist => {
        descr   => maketext('The brew dist to use for building the web rpm.'),
        default => 'docs-5E',
    },
    web_home => {
        descr => maketext(
            'This is a Publican Website home page, not a standard book.'),
    },
    web_host => {
        descr => maketext(
            'This is a Publican Website host name, used for searches and Sitemap.Be sure to include the full path to your document tree. e.g. if your documentas are in the docs directory: http://www.example.com/docs'
        ),
    },
    web_obsoletes =>
        { descr => maketext('Packages to obsolete in web RPM.'), },
    web_search => {
        descr => maketext(
            'Override the default search form for a Publican Website. By default this will use Gogle search and do a site search if web_host is set.'
        ),
    },
    web_name_label => {
        descr => maketext(
            'Override the book name, bottom level, menu label on a Publican Website.'
        ),
    },
    web_product_label => {
        descr => maketext(
            'Override the product, top level, menu label on a Publican Website.'
        ),
    },
    web_version_label => {
        descr => maketext(
            'Override the version, middle level, menu label on a Publican Website. To hide this meu item set this to: UNUSED'
        ),
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
                "Config file not found: [_1]. Perhaps you need to run 'publican old2new'",
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
        if ( defined $PARAMS{$def}->{default}
            and not defined( $config->param($def) ) )
        {
            $config->param( $def, $PARAMS{$def}->{default} );
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

        my $docname = $config->param('docname')
            || $xml_doc->root()->look_down( "_tag", "title" )->as_text();
        if ($@) {
            croak maketext("title not found in Info file");
        }
        $docname =~ s/\s/_/g;

        my $product = $config->param('product') || eval {
            $xml_doc->root()->look_down( "_tag", "productname" )->as_text();
        };
        if ($@) {
            croak maketext("productname not found in Info file");
        }
        $product =~ s/\s/_/g;

        my $version = $config->param('version') || eval {
            $xml_doc->root()->look_down( "_tag", "productnumber" )->as_text();
        };
        if ($@) {
            croak maketext("productnumber not found in Info file");
        }

        my $edition = $config->param('edition')
            || eval {
            $xml_doc->root()->look_down( "_tag", "edition" )->as_text();
            };
        if ($@) {
            croak maketext("edition not found in Info file");
        }

        my $release = $config->param('release') || eval {
            $xml_doc->root()->look_down( "_tag", "pubsnumber" )->as_text();
        };
        if ($@) {
            croak maketext("pubsnumber not found in Info file");
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
        logger(   "\t\t"
                . maketext( "Constraint: [_1]", $PARAMS{$param}->{constraint} )
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
    my ( $dir, $regex ) = @_;
    croak( maketext("dir is a required argument") ) unless ($dir);

    unless ( -d $dir ) {
        logger( maketext( "skiping non existant directory: [_1]", $dir ) );
        return;
    }

    croak( maketext("regex is a required argument") )
        if ( !$regex || $regex eq "" );

    my @filelist = File::Find::Rule->file->name($regex)->in($dir);

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

Log something, currently emits to STDERR

TODO: consider using Log::Dispatch or similar

=cut

sub logger {
    my ( $msg, $colour ) = @_;

    return if ($QUIET);

    if ( $colour && !$NOCOLOURS ) {
        print( STDERR $colour, $msg, RESET );
    }
    else {
        print( STDERR $msg );
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

=head2 old2new

Parse a publican 0.x Makefile and create a publican 1.x config file.

=cut

sub old2new {

    my $parser = Makefile::Parser->new();

    $parser->parse('Makefile') or croak( Makefile::Parser->error() );

    # get all the variable names defined in the Makefile:
    my @vars = $parser->vars();
    print( STDERR "found: " . join( ' ', sort @vars ) . "\n" );

    my $config = new Config::Simple();
    $config->syntax('http');

    foreach my $var (@vars) {
        if ( !defined $PARAM_OLD{$var} ) {
            logger( maketext( "[_1] is not handled yet.", $var ) . "\n" );
            next;
        }
        if ( $PARAM_OLD{$var} eq '' ) {
            logger( maketext( "[_1] is not used anymore.", $var ) . "\n" );
            next;
        }

        $config->param( $PARAM_OLD{$var}, $parser->var($var) );
    }

    $config->param( 'debug', '1' );

    $config->write('publican.cfg');

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

=item C<< edition not found in Info file >>

The <type>_Info.xml file does not contain a edition tag.

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
L<https://bugzilla.redhat.com/bugzilla/enter_bug.cgi?product=Fedora&amp;version=rawhide&amp;component=publican>.

=head1 AUTHOR

Jeff Fearn  C<< <jfearn@redhat.com> >>
