package Publican::WebSite;

use utf8;
use warnings;
use strict;
use 5.008;

use Carp qw(cluck croak);
use Config::Simple '-strict';
use DBI;
use Template;
use Template::Constants;
use Locale::Language;
use File::Find::Rule;
use DateTime;
use Publican;
use Encode qw(is_utf8 decode_utf8 encode_utf8);
use Time::localtime;
use XML::Simple;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

our $VERSION = '1.3';

my $DB_NAME             = 'books';
my $DEFAULT_LANG        = 'en-US';
my $DEFAULT_TMPL_PATH   = '/usr/share/publican/templates';
my $DEFAULT_CONFIG_FILE = '/etc/publican-website.cfg';
my $DEFAULT_DUMP_FILE   = '/var/www/html/DUMP.xml';

my %LANG_NAME = (
    'ar-SA'      => 'العربية',
    'as-IN'      => 'অসমীয়া',
    'ast-ES'     => 'Asturianu',
    'bg-BG'      => 'български',
    'bn-IN'      => 'বাংলা',
    'bs-BA'      => 'Bosanski',
    'ca-ES'      => 'Català',
    'cs-CZ'      => 'Čeština',
    'da-DK'      => 'Dansk',
    'de-CH'      => 'Schweizerdeutsch',
    'de-DE'      => 'Deutsch',
    'el-GR'      => 'Ελληνικά',
    'en-US'      => 'English',
    'es-ES'      => 'Español',
    'fa-IR'      => 'فارسی',
    'fi-FI'      => 'Suomi',
    'fr-FR'      => 'Français',
    'gu-IN'      => 'ગુજરાતી',
    'he-IL'      => 'עברית',
    'hi-IN'      => 'हिन्दी',
    'hr-HR'      => 'Hrvatski',
    'hu-HU'      => 'Magyar',
    'id-ID'      => 'Indonesia',
    'is-IS'      => 'Íslenska',
    'it-IT'      => 'Italiano',
    'ja-JP'      => '日本語',
    'kn-IN'      => 'ಕನ್ನಡ',
    'ko-KR'      => '한국어',
    'ml-IN'      => 'മലയാളം',
    'mr-IN'      => 'मराठी',
    'ms-MY'      => 'Melayu',
    'nb-NO'      => 'Norsk (bokmål)',
    'nds-DE'     => 'Plattdüütsch',
    'nl-NL'      => 'Nederlands',
    'or-IN'      => 'ଓଡ଼ିଆ',
    'pa-IN'      => 'ਪੰਜਾਬੀ',
    'pl-PL'      => 'Polski',
    'pt-BR'      => 'Português Brasileiro',
    'pt-PT'      => 'Português',
    'ru-RU'      => 'Русский',
    'si-LK'      => 'සිංහල',
    'sk-SK'      => 'Slovenščina',
    'sr-RS'      => 'Српски',
    'sr-Latn-RS' => 'Srpski (latinica)',
    'sv-SE'      => 'Svenska',
    'ta-IN'      => 'தமிழ்',
    'te-IN'      => 'తెలుగు',
    'uk-UA'      => 'Українська',
    'zh-CN'      => '简体中文',
    'zh-TW'      => '繁體中文',
);

# This is required to ensure that the correct localised strings are found when running
# the commands on an non en-US command line
my $locale = Publican::Localise->get_handle('en-US')
    || croak(
    "Could not create a Publican::Localise object for language: en-US");
$locale->encoding("UTF-8");
$locale->textdomain("publican");

my %tmpl_strings = (
    'toc_nav'      => $locale->maketext('toc nav'),
    'Welcome'      => $locale->maketext('Welcome'),
    'collapse_all' => $locale->maketext('collapse all'),
    'Language'     => $locale->maketext('Language'),
    'nocookie'     => $locale->maketext(
        'The Navigation Menu below will automatically collapse when pages are loaded. Enable cookies to fix the Navigation Menu functionality.'
    ),
    'nojs' => $locale->maketext(
        '<p>The Navigation Menu above requires JavaScript to function.</p><p>Enable JavaScript to allow the Navigation Menu to function.</p><p>Disable CSS to view the Navigation options without JavaScript enabled</p>'
    ),
    'iframe'          => $locale->maketext(
        'This is an iframe, to view it upgrade your browser or enable iframe display.'
    ),
    'Code'             => $locale->maketext('Code'),
    'Products'         => $locale->maketext('Products'),
    'Books'            => $locale->maketext('Books'),
    'Versions'         => $locale->maketext('Versions'),
    'Packages'         => $locale->maketext('Packages'),
    'Total_Languages'  => $locale->maketext('Total Languages'),
    'Total_Packages'   => $locale->maketext('Total Packages'),
    'Untranslated'     => $locale->maketext('Untranslated'),
    'index_javascript' => $locale->maketext(
        'This web site requires JavaScript and cookies to be enabled to function correctly.'
    ),
    'index_toc' =>
        $locale->maketext('Click here to view a static Table of Contents'),
    'ProductLinkTitle' => $locale->maketext('Information'),
    ProductList        => $locale->maketext('Product List'),
    'Hide_Menu'        => $locale->maketext('Hide Menu'),
    'Show_Menu'        => $locale->maketext('Show Menu'),
);

sub new {
    my ( $class, $arg ) = @_;

    my $create      = delete $arg->{create}      || undef;
    my $site_config = delete $arg->{site_config} || $DEFAULT_CONFIG_FILE;

    if ( %{$arg} ) {
        croak "unknown args: " . join( ", ", keys %{$arg} );
    }

    my $config = new Config::Simple();
    $config->syntax('http');
    $config->read($site_config)
        || croak("Failed to load config file: $site_config");

    my $toc_path = $config->param('toc_path') || croak(
        maketext(
            "[_1] is a mandatory field in a site configuration file",
            'toc_path'
        )
    );
    my $tmpl_path = $config->param('tmpl_path') || $DEFAULT_TMPL_PATH;
    my $def_lang  = $config->param('def_lang')  || $DEFAULT_LANG;
    my $db_file   = $config->param('db_file')   || croak(
        maketext(
            "[_1] is a mandatory field in a site configuration file. Check [_2] for validity.",
            'db_file',
            $site_config
        )
    );
    my $host      = $config->param('host')      || 'http://localhost/';
    my $search    = $config->param('search')    || undef;
    my $title     = $config->param('title')     || 'Documentation';
    my $dump      = $config->param('dump')      || undef;
    my $dump_file = $config->param('dump_file') || $DEFAULT_DUMP_FILE;
    my $zip_dump  = $config->param('zip_dump')  || undef;
    my $toc_type  = $config->param('toc_type')  || 'toc';

    my $self = bless { db_file => $db_file }, $class;

    if ($create) {
        $self->_create_db();
    }

    $self->_load_db;
    $self->{toc_path}  = $toc_path;
    $self->{tmpl_path} = $tmpl_path;
    $self->{def_lang}  = $def_lang;
    $self->{host}      = $host;
    $self->{search}    = $search;
    $self->{title}     = $title;
    $self->{dump}      = $dump;
    $self->{dump_file} = $dump_file;
    $self->{zip_dump}  = $zip_dump;
    $self->{toc_type}  = $toc_type;

    my $conf = { INCLUDE_PATH => $tmpl_path, };

    $conf->{DEBUG} = Template::Constants::DEBUG_ALL if ($Publican::DEBUG);

    # create Template object
    $self->{Template} = Template->new($conf) or croak( Template->error() );

    return $self;
}

sub _dbh {
    my $self = shift;

    return $self->{'dbh'} if $self->{'dbh'};

    my $db_file = $self->{'db_file'};
    my $attr = { AutoCommit => 1, RaiseError => 0, PrintError => 1 };

    my $dbh = DBI->connect( "dbi:SQLite:dbname=$db_file", "", "", $attr );

    if ( not( $dbh and ref $dbh ) ) {
        croak "Failed to load db file '$db_file'.";
    }

##    cluck("Connected to DB $db_file\n");

    $dbh->{sqlite_unicode} = 1;

    $self->{'dbh'} = $dbh;
}

sub toc_path {
    my $self = shift;
    return ( $self->{toc_path} );
}

sub _create_db {
    my $self = shift;

    my $db_file = $self->{'db_file'};

    if ( -f $db_file ) {
        print("DB file '$db_file' exists, skipping creation.");
        return;
    }

    $self->_dbh->do(<<CREATE_TABLE);
CREATE TABLE IF NOT EXISTS $DB_NAME (
	ID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	language text(255) NOT NULL,
	product text(255) NOT NULL,
	version text(255) NOT NULL,
	name text(255) NOT NULL,
	format text(31) NOT NULL,
	product_label text(255),
	version_label text(255),
	name_label text(255),
	update_date text(10),
	subtitle text,
	abstract text,
	UNIQUE(language, product, version, name, format)
)
CREATE_TABLE

    return;
}

sub _load_db {
    my $self = shift;

    my $db_file = $self->{'db_file'};

    if ( not -f $db_file ) {
        croak "DB file '$db_file' not found.";
    }

    $self->_dbh;

    return;
}

sub update_or_add_entry {
    my ( $self, $arg ) = @_;

    my $language = delete $arg->{language} || croak "language required";
    my $product  = delete $arg->{product}  || croak "product required";
    my $version  = delete $arg->{version}  || croak "version required";
    my $name     = delete $arg->{name}     || croak "name required";
    my $format   = delete $arg->{format}   || croak "format required";
    my $product_label = delete $arg->{product_label};
    my $version_label = delete $arg->{version_label};
    my $name_label    = delete $arg->{name_label};
    my $subtitle      = delete $arg->{subtitle};
    my $abstract      = delete $arg->{abstract};

    if ( %{$arg} ) {
        croak "unknown args: " . join( ", ", keys %{$arg} );
    }

    my $rc;

    my $id = $self->get_entry_id(
        {   language => $language,
            product  => $product,
            version  => $version,
            name     => $name,
            format   => $format
        }
    );

    if ($id) {
        $rc = $self->update_entry(
            {   ID            => $id,
                language      => $language,
                product       => $product,
                version       => $version,
                name          => $name,
                format        => $format,
                product_label => $product_label,
                version_label => $version_label,
                name_label    => $name_label,
                subtitle      => $subtitle,
                abstract      => $abstract,
            }
        );
    }
    else {
        $rc = $self->add_entry(
            {   language      => $language,
                product       => $product,
                version       => $version,
                name          => $name,
                format        => $format,
                product_label => $product_label,
                version_label => $version_label,
                name_label    => $name_label,
                subtitle      => $subtitle,
                abstract      => $abstract,
            }
        );
    }

    return ($rc);
}

sub add_entry {
    my ( $self, $arg ) = @_;

    my $language = delete $arg->{language} || croak "language required";
    my $product  = delete $arg->{product}  || croak "product required";
    my $version  = delete $arg->{version}  || croak "version required";
    my $name     = delete $arg->{name}     || croak "name required";
    my $format   = delete $arg->{format}   || croak "format required";
    my $product_label = delete $arg->{product_label};
    my $version_label = delete $arg->{version_label};
    my $name_label    = delete $arg->{name_label};
    my $subtitle      = delete $arg->{subtitle};
    my $abstract      = delete $arg->{abstract};

    if ( %{$arg} ) {
        croak "unknown args: " . join( ", ", keys %{$arg} );
    }

    my $update_date = DateTime->today()->ymd();

    $format = lc $format;
    $abstract =~ s/\n/ /gm;

    my $sql = <<INSERT_ENTRY;
        INSERT INTO $DB_NAME 
               (language, product, version, name, format, product_label, version_label, name_label, update_date, subtitle, abstract) 
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
INSERT_ENTRY

    return $self->_dbh->do(
        $sql,           undef,       $language,    $product,
        $version,       $name,       $format,      $product_label,
        $version_label, $name_label, $update_date, $subtitle,
        $abstract
    );
}

sub update_entry {
    my ( $self, $arg ) = @_;

    my $ID       = delete $arg->{ID}       || croak "ID required";
    my $language = delete $arg->{language} || croak "language required";
    my $product  = delete $arg->{product}  || croak "product required";
    my $version  = delete $arg->{version}  || croak "version required";
    my $name     = delete $arg->{name}     || croak "name required";
    my $format   = delete $arg->{format}   || croak "format required";
    my $product_label = delete $arg->{product_label};
    my $version_label = delete $arg->{version_label};
    my $name_label    = delete $arg->{name_label};
    my $subtitle      = delete $arg->{subtitle};
    my $abstract      = delete $arg->{abstract};

    if ( %{$arg} ) {
        croak "unknown args: " . join( ", ", keys %{$arg} );
    }

    my $update_date = DateTime->today()->ymd();

    $format = lc $format;
    $abstract =~ s/\n/ /gm;

    my $sql = <<INSERT_ENTRY;
        UPDATE $DB_NAME SET
               language = ?, product = ?, version = ?, name = ?, format = ?, product_label = ?, version_label = ?, name_label = ?, update_date = ?, subtitle = ?, abstract = ?
               WHERE ID = $ID
INSERT_ENTRY

    return $self->_dbh->do(
        $sql,           undef,       $language,    $product,
        $version,       $name,       $format,      $product_label,
        $version_label, $name_label, $update_date, $subtitle,
        $abstract
    );
}

sub del_entry {
    my ( $self, $arg ) = @_;

    my $language = delete $arg->{language} || croak "language required";
    my $product  = delete $arg->{product}  || croak "product required";
    my $version  = delete $arg->{version}  || croak "version required";
    my $name     = delete $arg->{name}     || croak "name required";
    my $format   = delete $arg->{format}   || croak "format required";

    if ( %{$arg} ) {
        croak "unknown args: " . join( ", ", keys %{$arg} );
    }

    my $sql = <<DELETE_ENTRY;
        DELETE FROM $DB_NAME 
         WHERE language = ?
           AND product = ?
           AND version = ?
           AND name = ?
           AND format = ?
DELETE_ENTRY

   #croak "\n\nvals: $sql, $language, $product, $version, $name, $format\n\n";

    return $self->_dbh->do( $sql, undef, $language, $product, $version, $name,
        $format );
}

sub get_entry_id {
    my ( $self, $arg ) = @_;

    my $language = delete $arg->{language} || croak "language required";
    my $product  = delete $arg->{product}  || croak "product required";
    my $version  = delete $arg->{version}  || croak "version required";
    my $name     = delete $arg->{name}     || croak "name required";
    my $format   = delete $arg->{format}   || croak "format required";

    if ( %{$arg} ) {
        croak "unknown args: " . join( ", ", keys %{$arg} );
    }

    my $sql = <<GET_ENTRY;
        SELECT ID FROM $DB_NAME 
         WHERE language = ?
           AND product = ?
           AND version = ?
           AND name = ?
           AND format = ?
GET_ENTRY

    my $sth = $self->_dbh->prepare($sql);

    $sth->execute( $language, $product, $version, $name, $format );
    my $result = $sth->fetchrow();

    return $result;
}

# return a hash of records
sub get_hash_ref {
    my ( $self, $arg ) = @_;

    my $language = delete $arg->{language}
        || croak "get_hash_ref: language required";

    if ( %{$arg} ) {
        croak "unknown args: " . join( ", ", keys %{$arg} );
    }

    my $def_lang  = $self->{def_lang};
    my $direction = 'DESC';
    $direction = 'ASC' if ( $def_lang gt $language );

    my $sql = <<GET_LIST;
        SELECT ID,
               language, 
               product, 
               version, 
               name, 
               format,
               product_label, 
               version_label, 
               name_label,
               update_date,
               subtitle,
               abstract
          FROM $DB_NAME 
         WHERE (language = ? or language = ?)
      GROUP BY language, product, version, name, format
      ORDER BY language $direction,
               product, 
               version DESC, 
               name, 
               format
GET_LIST

    my $sth = $self->_dbh->prepare($sql);
    $sth->execute( $language, $def_lang );

    my %list;

    while (
        my ($id,         $lang,        $product,       $version,
            $name,       $format,      $product_label, $version_label,
            $name_label, $update_date, $subtitle,      $abstract
        )
        = $sth->fetchrow()
        )
    {

        next
            if ( defined $list{$product}{$version}{$name}
            and $list{$product}{$version}{$name}{language} ne $lang );

        $list{$product}{$version}{$name}{formats}{$format} = 1;
        $list{$product}{$version}{$name}{language}         = $lang;
        $list{$product}{$version}{$name}{version_label}    = $version_label
            if $version_label;
        $list{$product}{$version}{$name}{name_label} = $name_label
            if $name_label;
        $list{$product}{$version}{$name}{product_label} = $product_label
            if $product_label;
        $list{$product}{$version}{$name}{update_date} = $update_date
            || '2000-01-01';
        $list{$product}{$version}{$name}{subtitle} = $subtitle;
        $list{$product}{$version}{$name}{abstract} = $abstract;
    }

    $sth->finish();

    return ( \%list );
}

sub get_lang_list {
    my ( $self, $arg ) = @_;

    if ( $arg && %{$arg} ) {
        croak "unknown args: " . join( ", ", keys %{$arg} );
    }

    my $langs;

    my $sql = qq|SELECT DISTINCT language FROM $DB_NAME ORDER BY language|;
    $langs = $self->_dbh->selectall_arrayref($sql);

    unless ( $langs->[0] ) {

        # No languages found, using default language: [_1]\n
        my @langs = ( $self->{def_lang} );
        $langs->[0] = \@langs;
    }

    return ($langs);
}

sub regen_all_toc {
    my ( $self, $arg ) = @_;
    my $OUT;

    if ( $arg && %{$arg} ) {
        croak "unknown args: " . join( ", ", keys %{$arg} );
    }

    my $langs = $self->get_lang_list();

    my @fulltoc        = ();
    my @toc_names      = ();
    my @urls           = ();
    my @opds_lang_list = ();

    foreach my $lang ( @{$langs} ) {
        my %toc;
        my @prods = ();

        my $products = $self->_regen_toc(
            { language => qq|$lang->[0]|, urls => \@urls } );

        # Remove untranslated content from map page.
        foreach my $product ( @{$products} ) {
            my @versions = ();

            foreach my $version ( @{ $product->{'versions'} } ) {
                delete( $version->{'untrans_books'} );
                push( @versions, $version )
                    if defined( $version->{'books'} )
                        && scalar @{ $version->{'books'} };
            }

            if ( scalar @versions ) {
                $product->{'versions'} = \@versions;
                push( @prods, $product );
            }
        }

        $toc{'products'} = \@prods;

        $lang->[0] =~ m/^([^-_]*)/;
        my $lang_name = code2language($1) || "unknown $1";
        if ( $LANG_NAME{ $lang->[0] } ) {
            $lang_name = $LANG_NAME{ $lang->[0] };
        }
        $toc{'name'}    = $lang_name;
        $toc{'langloc'} = $lang->[0];
        push( @fulltoc, \%toc );
        my %toc_name = ( 'toc_name' => $lang_name );
        push( @toc_names, \%toc_name );

        my %opds_lang = (
            url         => qq|$lang->[0]| . '/opds.xml',
            id          => $self->{host} . '/' . qq|$lang->[0]| . '/opds.xml',
            lang        => $lang->[0],
            title       => $lang_name,
            content     => "",
            img         => "",
            update_date => DateTime->now(),
        );

        $opds_lang{img}
            = $self->{host} . '/'
            . qq|$lang->[0]|
            . '/images/cover_thumbnail.png'
            if ( -f $self->{toc_path} . '/'
            . qq|$lang->[0]|
            . '/images/cover_thumbnail.png' );

        push( @opds_lang_list, \%opds_lang );

    }

    my $vars = {
        'static_langs'     => \@fulltoc,
        'static_langs_toc' => \@toc_names,
    };

    $self->{Template}->process(
        $self->{toc_type} . '.tmpl', $vars,
        $self->{toc_path} . '/toc.html',
        binmode => ':encoding(UTF-8)'
    ) or croak( $self->{Template}->error() );

    $vars = ();
    $vars = { urls => \@urls, };
    $self->{Template}->process(
        'Sitemap.tmpl', $vars,
        $self->{toc_path} . "/Sitemap",
        binmode => ':encoding(UTF-8)'
    ) or croak( $self->{Template}->error() );

    # regenerate main index.html
    $vars = ();
    my $locales = join( ",", map( qq|"$_->[0]"|, @{$langs} ) );
    $vars = {
        locales          => $locales,
        title            => $self->{title},
        def_lang         => $self->{def_lang},
        index_javascript => $tmpl_strings{'index_javascript'},
        index_toc        => $tmpl_strings{'index_toc'},
    };
    $self->{Template}->process(
        'index.tmpl', $vars,
        $self->{toc_path} . "/index.html",
        binmode => ':encoding(UTF-8)'
    ) or croak( $self->{Template}->error() );

    # This file contains all the langauges.
    my $opds_vars;
    $opds_vars->{langs}       = \@opds_lang_list;
    $opds_vars->{update_date} = DateTime->now();
    $opds_vars->{self}        = $self->{host} . "/opds.xml";
    $opds_vars->{id}          = $self->{host} . "/opds.xml";
    $opds_vars->{title}       = $self->{title};
##    $opds_vars->{} = ;

    $self->{Template}->process(
        'opds-langs.tmpl', $opds_vars,
        $self->{toc_path} . "/opds.xml",
        binmode => ':encoding(UTF-8)'
    ) or croak( $self->{Template}->error() );

    $self->xml_dump() if ( $self->{dump} );
    return;
}

sub version_sort {

    # X or X.Y
    if ( $a =~ /^(?:\d+|\d+\.\d+)$/ && $b =~ /^(?:\d+|\d+\.\d+)$/ ) {
        return $a <=> $b;
    }

    # X or X.Y Vs X.Y.Z
    elsif ( $a =~ /^(?:\d+|\d+\.\d+)$/ && $b =~ /^(\d+\.\d+)(.+)$/ ) {
        if ( $a gt $1 ) {
            return 1;
        }
        else {
            return -1;
        }
    }

    # X.Y.Z Vs X or X.Y
    elsif ( $b =~ /^(?:\d+|\d+\.\d+)$/ && $a =~ /^(\d+\.\d+)(.+)$/ ) {
        if ( $1 ge $b ) {
            return 1;
        }
        else {
            return -1;
        }
    }

    # X.Y.Z Vs X.Y.Z
    else {
        return $a cmp $b;
    }
}

sub _regen_toc {
    my ( $self, $arg ) = @_;

    my $language = delete $arg->{language}
        || croak "_regen_toc: language required";

    my $urls = delete $arg->{urls}
        || croak "_regen_toc: urls required";

    if ( %{$arg} ) {
        croak "unknown args: " . join( ", ", keys %{$arg} );
    }

    my $vars = {};

    my $default_search = <<SEARCH;
	<form target="_top" method="get" action="http://www.google.com/search">
		<div class="search">
			<input class="searchtxt" type="text" name="q" value="" />
			<input class="searchsub" type="submit" value="###Search###" />
SEARCH

    my $host = $self->{host};

    if ($host) {
        $default_search .= <<SEARCH;
			<input class="searchchk" type="hidden"  name="sitesearch" value="$host" />
SEARCH
    }
    else {
        $host = '.';
    }

    $default_search .= <<SEARCH;
		</div>
	</form>
SEARCH

    my $langs      = $self->get_lang_list();
    my @tmpl_langs = ();

    foreach my $lang ( @{$langs} ) {
        my %row_data;

        $lang->[0] =~ m/^([^-_]*)/;
        my $lang_name = code2language($1) || "unknown $1";
        my $selected = '';

        if ( $LANG_NAME{ $lang->[0] } ) {
            $lang_name = $LANG_NAME{ $lang->[0] };
        }
        if ( $language eq $lang->[0] ) {
            $selected = 'selected="selected"';
        }
        $row_data{'selected'}  = $selected;
        $row_data{'lang'}      = $lang->[0];
        $row_data{'lang_name'} = $lang_name;
        push( @tmpl_langs, \%row_data );
    }

    $vars->{'langs'} = \@tmpl_langs;

    my $list2 = $self->get_hash_ref( { language => "$language" } );
    my @products = ();

    my $lc_lang = $language;
    $lc_lang =~ s/-/_/g;
    my $locale = Publican::Localise->get_handle($lc_lang)
        || croak(
        "Could not create a Publican::Localise object for language: [_1]",
        $language );
    $locale->encoding("UTF-8");
    $locale->textdomain("publican");

    my $search = ( $self->{search} || $default_search );
    my $string = $locale->maketext("Search");
    $search =~ s/###Search###/$string/g;
    $vars->{'search'} = $search;

    foreach my $string ( sort( keys(%tmpl_strings) ) ) {
        $vars->{$string} = $locale->maketext( $tmpl_strings{$string} );
        $vars->{$string} = decode_utf8( $vars->{$string} )
            unless ( is_utf8( $vars->{$string} ) );
    }

    $vars->{untrans_lang} = $self->{def_lang};
    my @opds_prod_list;

    foreach my $product ( sort( keys( %{$list2} ) ) ) {
        my @opds_list;
        my $product_label = $product;
        my %prod_data;
        my @versions = ();

        if ( -f "$self->{toc_path}/$language/$product/index.html" ) {
            $prod_data{'product_icon'} = 1;
            my $url = {
                url         => qq|$host/$language/$product/index.html|,
                update_date => ctime(
                    (   stat(
                            "$self->{toc_path}/$language/$product/index.html")
                    )[9]
                ),
            };

            push( @{$urls}, $url );
        }
        else {
            $prod_data{'product_icon'} = 0;
        }

        foreach my $version (
            reverse( sort( version_sort keys( %{ $list2->{$product} } ) ) ) )
        {
            my $version_label = $version;
            my %ver_data;
            my @books         = ();
            my @untrans_books = ();
            my $category      = $version_label;

## BUGBUG TODO labels
## It makes more sense to do an SQL query here for the labels instead of
## doing it in the book loop.

            if ( -f "$self->{toc_path}/$language/$product/$version/index.html"
                )
            {
                $ver_data{'ver_icon'} = 1;
                my $url = {
                    url => qq|$host/$language/$product/$version/index.html|,
                    update_date => ctime(
                        (   stat(
                                "$self->{toc_path}/$language/$product/$version/index.html"
                            )
                        )[9]
                    ),
                };

                push( @{$urls}, $url );
            }

            foreach
                my $book ( sort( keys( %{ $list2->{$product}{$version} } ) ) )
            {
                my $book_label = $book;
                my %book_data;
                my @types = ();
                my $lang  = $list2->{$product}{$version}{$book}{language};

                foreach my $type (
                    sort
                    keys %{ $list2->{$product}{$version}{$book}{formats} }
                    )
                {

                    $book_label
                        = $list2->{$product}{$version}{$book}{name_label}
                        if ($list2->{$product}{$version}{$book}{name_label}
                        and $list2->{$product}{$version}{$book}{name_label} ne
                        $book );

                    $book_label = decode_utf8($book_label)
                        unless ( is_utf8($book_label) );

                    $version_label
                        = $list2->{$product}{$version}{$book}{version_label}
                        if (
                            $list2->{$product}{$version}{$book}{version_label}
                        and $list2->{$product}{$version}{$book}{version_label}
                        ne $version );

                    $version_label = decode_utf8($version_label)
                        unless ( is_utf8($version_label) );

                    $product_label
                        = $list2->{$product}{$version}{$book}{product_label}
                        if (
                            $list2->{$product}{$version}{$book}{product_label}
                        and $list2->{$product}{$version}{$book}{product_label}
                        ne $product );

                    $product_label = decode_utf8($product_label)
                        unless ( is_utf8($product_label) );

## debug_msg( "product: $product, version: $version, book: $book, book_label: $book_label, version_label: $version_label, product_label: $product_label \n" );

                    my %type_data;
                    $type_data{'type'}  = $type;
                    $type_data{prep}    = './';
                    $type_data{onclick} = 1;
                    $type_data{'ext'}   = 'index.html';
                    if ( $type eq 'pdf' ) {
                        my @filelist
                            = File::Find::Rule->file->relative()
                            ->name('*.pdf')
                            ->in(
                            "$self->{toc_path}/$lang/$product/$version/$type/$book"
                            );
                        $type_data{'ext'} = pop(@filelist);
                    }
                    elsif ( $type eq 'txt' ) {
                        my @filelist
                            = File::Find::Rule->file->relative()
                            ->name('*.txt')
                            ->in(
                            "$self->{toc_path}/$lang/$product/$version/$type/$book"
                            );
                        $type_data{'ext'} = pop(@filelist);
                    }
                    elsif ( $type eq 'epub' ) {
                        my @filelist
                            = File::Find::Rule->file->relative()
                            ->name('*.epub')
                            ->in(
                            "$self->{toc_path}/$lang/$product/$version/$type/$book"
                            );
                        $type_data{'ext'} = pop(@filelist);
                        if ( $type_data{'ext'} ) {
                            my %opds_url = (
                                title => "$book_label",
                                id =>
                                    "$host/$lang/$product/$version/$type/$book/"
                                    . $type_data{'ext'},
                                lang => $language,
                                update_date =>
                                    $list2->{$product}{$version}{$book}
                                    {update_date},
                                url =>
                                    "$host/$lang/$product/$version/$type/$book/"
                                    . $type_data{'ext'},
                                category => $category,
                                summary  => (
                                    $list2->{$product}{$version}{$book}
                                        {subtitle} || ""
                                ),
                                content => (
                                    $list2->{$product}{$version}{$book}
                                        {abstract} || ""
                                ),
                            );
                            $category = "";
                            $opds_url{title} =~ s/_/ /g;
                            my $img
                                = "/$lang/$product/$version/html/$book/images/cover_thumbnail.png";
                            $opds_url{img} = $self->{host} . $img
                                if ( -f $self->{toc_path} . $img );

                            push( @opds_list, \%opds_url );
                        }
## hmm epub link for safari ...
##                        $type_data{prep} = "epub://$host/docs/$lang/";
                        $type_data{onclick} = 0;
                    }

                    if ( defined $type_data{'ext'} and $type_data{'ext'} ) {
                        my $url = {
                            url =>
                                qq|$host/$lang/$product/$version/$type/$book/|
                                . $type_data{'ext'},
                            update_date => $list2->{$product}{$version}{$book}
                                {update_date},
                        };

                        push( @{$urls}, $url ) if ( $lang eq $language );
                    }
                    else {
                        print( STDERR
                                "ERROR: bogus entry found in DB: $lang/$product/$version/$type/$book\n"
                        );
                    }

                    push( @types, \%type_data );
                }

                $book_data{'book'}       = $book;
                $book_data{'book_clean'} = $book_label;
                $book_data{'book_clean'} =~ s/_/ /g;
                $book_data{'types'} = \@types;

                if ( $lang eq $language ) {
                    push( @books, \%book_data );
                }
                else {
                    push( @untrans_books, \%book_data );
                }
            }

            $ver_data{'version'}       = $version;
            $ver_data{'version_label'} = $version_label;
            $ver_data{'books'}         = \@books;
            $ver_data{'untrans_books'} = \@untrans_books
                if scalar @untrans_books;
            push( @versions, \%ver_data );
        }

        $prod_data{'prod_link_title'} = $tmpl_strings{'ProductLinkTitle'};
        $prod_data{'product'}         = $product;
        $prod_data{'product_clean'}   = $product_label;
        $prod_data{'product_clean'} =~ s/_/ /g;
        $prod_data{'versions'} = \@versions;
        push( @products, \%prod_data );

        # This file contains books for all versions of a product.
        my $opds_vars;
        $opds_vars->{urls}        = \@opds_list;
        $opds_vars->{update_date} = DateTime->now();
        $opds_vars->{self}        = "$host/$language/opds-$product.xml";
        $opds_vars->{id}          = "$host/$language/opds-$product.xml";
        $opds_vars->{title}       = $prod_data{'product_clean'};
##        $opds_vars->{} = ;

        $self->{Template}->process(
            'opds.tmpl', $opds_vars,
            $self->{toc_path} . "/$language/opds-$product.xml",
            binmode => ':encoding(UTF-8)'
        ) or croak( $self->{Template}->error() );

        my %opds_p_url = (
            title       => $prod_data{'product_clean'},
            id          => "$host/$language/$product/opds-$product.xml",
            lang        => $language,
            update_date => DateTime->now(),
            url         => "opds-$product.xml",
            content     => "",
        );
        my $img = "/$language/$product/images/cover_thumbnail.png";
        $opds_p_url{img} = $self->{host} . $img
            if ( -f $self->{toc_path} . $img );

        push( @opds_prod_list, \%opds_p_url );
    }

    $vars->{'products'} = \@products;

    $self->{Template}->process(
        'toc.tmpl', $vars,
        $self->{toc_path} . "/$language/toc.html",
        binmode => ':encoding(UTF-8)'
    ) or croak( $self->{Template}->error() );

    # This file contains all products for this langauge.
    my $opds_vars;
    $opds_vars->{products}    = \@opds_prod_list;
    $opds_vars->{update_date} = DateTime->now();
    $opds_vars->{self}        = "$host/$language/opds.xml";
    $opds_vars->{id}          = "$host/$language/opds.xml";
    $opds_vars->{title}       = $tmpl_strings{ProductList};
##    $opds_vars->{} = ;

    $self->{Template}->process(
        'opds-prods.tmpl', $opds_vars,
        $self->{toc_path} . "/$language/opds.xml",
        binmode => ':encoding(UTF-8)'
    ) or croak( $self->{Template}->error() );

    return \@products;
}

sub report {
    my ( $self, $arg ) = @_;

    if ( $arg && %{$arg} ) {
        croak "unknown args: " . join( ", ", keys %{$arg} );
    }

    my $sql = <<GET_COUNTS;
        SELECT COUNT(*), 
               count(DISTINCT language), 
               count(DISTINCT product), 
               count(DISTINCT format) 
          FROM $DB_NAME
GET_COUNTS
    my $counts = $self->_dbh->selectall_arrayref($sql)->[0];

    my $report = "\nThe database contains books that cover " . $counts->[2];
    $report .= " products, " . $counts->[1];
    $report .= " languages, " . $counts->[3];
    $report .= " formats, totaling " . $counts->[0] . " packages\n";

    return ($report);
}

sub validate {
    my ( $self, $arg ) = @_;

    if ( $arg && %{$arg} ) {
        croak "unknown args: " . join( ", ", keys %{$arg} );
    }

## Validate database entries have RPMs
    my $sql = <<GET_ALL;
select product,name,version,language from books where format = 'html' group by product,name,version,language
GET_ALL

    my $sth = $self->_dbh->prepare($sql);
    $sth->execute();

    while ( my ( $product, $name, $version, $language ) = $sth->fetchrow() ) {
        my $package = sprintf( '%s-%s-%s-web-%s', $product, $name, $version,
            $language );
        system( 'rpm', '-q', $package, '--queryformat=""' );
    }

## Validate RPMs have database entries
    my $command = 'rpm -q --whatrequires publican-website';

    foreach my $rpm (`$command`) {
        chomp($rpm);
        $rpm =~ /^([^-]*)-([^-]*)-([^-]*)-web-(..-..)/;
        my ( $product, $name, $version, $language );
        $product  = $1;
        $name     = $2;
        $version  = $3;
        $language = $4;

        my $sql = <<GET_COUNT;
        SELECT COUNT(*) 
          FROM $DB_NAME
         WHERE product =?
          AND  name = ?
          AND  version = ?
          AND  language = ?
          AND  format = 'html'
GET_COUNT

        my $sth = $self->_dbh->prepare($sql);
        $sth->execute( $product, $name, $version, $language );

        my $count = $sth->fetchrow();

        print "Missing database entry for $rpm\n" unless ($count);
    }

    return;
}

sub xml_dump {
    my ( $self, $arg ) = @_;

    if ( $arg && %{$arg} ) {
        croak "unknown args: " . join( ", ", keys %{$arg} );
    }

    my $results = $self->_dbh->selectall_arrayref( 'SELECT * FROM books',
        { Columns => {} } );

    my %site = (
        host     => $self->{host},
        def_lang => $self->{def_lang},
    );

    my $xml = XMLout( { site => \%site, record => $results }, NoAttr => 1 );

    my $OUT_FILE;
    open( $OUT_FILE, '>', $self->{dump_file} )
        || croak(
        maketext( "Could not open dump file for output: [_1]", $@ ) );

    print( $OUT_FILE "<?xml version='1.0' encoding='utf-8' ?>\n" );
    print( $OUT_FILE $xml );
    close($OUT_FILE);

    my $zip_file = $self->{dump_file} . '.zip';
    unlink $zip_file if ( -f $zip_file );

    if ( $self->{zip_dump} ) {
        my $zip    = Archive::Zip->new();
        my $member = $zip->addFile( $self->{dump_file} );
        $member->desiredCompressionLevel(9);
        $zip->writeToFileNamed($zip_file) == AZ_OK
            || croak( maketext("dump file zip creation failed.") );
    }

    return;
}

1;    # Magic true value required at end of module
__END__

=head1 NAME

Publican::WebSite - Manage a documentation website


=head1 VERSION

This document describes Publican::WebSite version 0.0.1


=head1 SYNOPSIS

    use Publican::WebSite;

=for author to fill in:
    Brief code example(s) here showing commonest usage(s).
    This section will be as far as many users bother reading
    so make it as educational and exeplary as possible.
  
    my $ws = Publican::WebSite::new();

	$ws->add($product, $version, $name, $format);

    foreach my $entry ($ws->list()) { ... }

    $ws->del($product, $version, $name, $format);

=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.


=head1 INTERFACE 

=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.

=head2  new

Create a Publican::WebSite object...

=head2 add_entry

Add an entry to the current Publican::WebSite DB...

Returns number of rows added. Should be 1 for success, 0 for failure.

=head2 update_entry

Update an existing entry in the current Publican::WebSite DB...

Returns number of rows added. Should be 1 for success, 0 for failure.

=head2 update_or_add_entry

Update an existing entry if it esists, else create a new entry.

=head2  del_entry

Delete an entry from the current Publican::WebSite DB...

Returns number of rows deleted. Should be 1 for success, 0 for failure.

=head2  get_entry_id

Get the ID of a book from the Publican::WebSite DB.

Returns the ID or NULL.

=head2 get_hash_ref

Returns a reference to a has of all books for the selected language.

=head2 get_lang_list

Returns an array ref of distinct, osrted, languages.

=head2 regen_all_toc

Update the toc html files for every language.

=head2 report

Returns a string containing the current database statistics.

=head2 validate

Validate the database entries against the RPM database.

TODO should also/instead compare entires aginst web site files?

=head2 version_sort

Sort version strings in to correct order, handles X, X.Y, and X.Y.Z formats.

=head2 toc_path

Return the full toc path.

=head2 xml_dump

Generate an XML dump, and a zip of the dump if required, of the Database.

=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
Publican::WebSite requires no configuration files or environment variables.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-documentation-website@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Jeff Fearn  C<< <jfearn@redhat.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Jeff Fearn C<< <jfearn@redhat.com> >>. All rights reserved.

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

