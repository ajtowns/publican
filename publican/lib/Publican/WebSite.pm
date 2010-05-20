package Publican::WebSite;

use warnings;
use strict;

use Carp qw(cluck croak);
use Config::Simple;
use DBI;
use Template;
use Template::Constants;
use Locale::Language;
use File::Find::Rule;
## BUGBUG This requires splitting publican into 3 rpms to
## allow translations to not conflict on systems
## with web and builder installed
use Publican;
#use Publican::Translate;

our $VERSION = '1.3';

my $DB_NAME             = 'books';
my $DEFAULT_LANG        = 'en-US';
my $DEFAULT_TOC_PATH    = "/var/www/html/docs";
my $DEFAULT_TMPL_PATH   = '/usr/share/publican-website/templates';
my $DEFAULT_DB_FILE     = '/usr/share/publican-website/default.db';
my $DEFAULT_CONFIG_FILE = '/etc/publican-website.cfg';

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

my %tmpl_strings = (
    'toc_nav'      => maketext('toc nav'),
    'Welcome'      => maketext('Welcome'),
    'collapse_all' => maketext('collapse all'),
    'Language'     => maketext('Language'),
    'nocookie'     => maketext(
        'The Navigation Menu below will automatically collapse when pages are loaded. Enable cookies to fix the Navigation Menu functionality.'
    ),
    'nojs' => maketext(
        '<p>The Navigation Menu above requires JavaScript to function.</p><p>Enable JavaScript to allow the Navigation Menu to function.</p><p>Disable CSS to view the Navigation options without JavaScript enabled</p>'
    ),
    'Site_Map'        => maketext('Site Map'),
    'Site_Statistics' => maketext('Site Statistics'),
    'Site_Tech'       => maketext('Site Tech'),
    'iframe'          => maketext(
        'This is an iframe, to view it upgrade your browser or enable iframe display.'
    ),
    'Code'            => maketext('Code'),
    'Products'        => maketext('Products'),
    'Books'           => maketext('Books'),
    'Versions'        => maketext('Versions'),
    'Packages'        => maketext('Packages'),
    'Total_Languages' => maketext('Total Languages'),
    'Total_Packages'  => maketext('Total Packages'),
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

    my $toc_path  = $config->param('toc_path')  || $DEFAULT_TOC_PATH;
    my $tmpl_path = $config->param('tmpl_path') || $DEFAULT_TMPL_PATH;
    my $db_file   = $config->param('db_file')   || $DEFAULT_DB_FILE;

    my $self = bless { db_file => $db_file }, $class;

    if ($create) {
        $self->_create_db();
    }

    $self->_load_db;
    $self->{toc_path}  = $toc_path;
    $self->{tmpl_path} = $tmpl_path;

    my $conf = {
        INCLUDE_PATH => $tmpl_path,
##        DEBUG => Template::Constants::DEBUG_ALL,
    };

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

    $dbh->{unicode} = 1;

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

    #TODO Table design
    # ID, product, version,name, format
    # ID unique key
    # unique "product, version,name, format"?

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
	UNIQUE(language, product, version, name, format)
)
CREATE_TABLE

    $self->_create_settings();

    return;
}

sub _create_settings {
    my ( $self, $args ) = @_;

    if ( $args && %{$args} ) {
        croak( "unknown args: " . join( ", ", keys %{$args} ) );
    }

    $self->_dbh->do(<<CREATE_TABLE);
CREATE TABLE IF NOT EXISTS settings (
	host text(255),
	search blob
)
CREATE_TABLE

    return;
}

sub update_settings {
    my ( $self, $args ) = @_;

    my $host   = delete $args->{host};
    my $search = delete $args->{search};

    if ( $args && %{$args} ) {
        croak( "unknown args: " . join( ", ", keys %{$args} ) );
    }

    $self->_create_settings();

    my $sql = 'delete from settings ';
    $self->_dbh()->do($sql);

    $sql = 'INSERT INTO settings ';

    my @cols;
    my @vals;

    if ($host) {
        push( @cols, 'host' );
        push( @vals, "'$host'" );
    }

    if ($search) {
        push( @cols, 'search' );
        push( @vals, "'$search'" );
    }
    $sql .= '(' . join( ',',        @cols ) . ') ';
    $sql .= 'values (' . join( ',', @vals ) . ') ';

    if ( $search || $host ) {
        $self->_dbh()->do($sql);
    }

    return;
}

sub get_settings {
    my ( $self, $args ) = @_;

    $self->_create_settings();

    my $hashref = $self->_dbh()->selectrow_hashref('SELECT * FROM settings');

    return ($hashref);
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

sub add_entry {
    my ( $self, $arg ) = @_;

    my $language = delete $arg->{language} || croak "language required";
    my $product  = delete $arg->{product}  || croak "product required";
    my $version  = delete $arg->{version}  || croak "version required";
    my $name     = delete $arg->{name}     || croak "name required";
    my $format   = delete $arg->{format}   || croak "format required";
    my $product_label  = delete $arg->{product_label};
    my $version_label  = delete $arg->{version_label};
    my $name_label     = delete $arg->{name_label};

    if ( %{$arg} ) {
        croak "unknown args: " . join( ", ", keys %{$arg} );
    }

    $format = lc $format;

    my $sql = <<INSERT_ENTRY;
        INSERT INTO $DB_NAME 
               (language, product, version, name, format, product_label, version_label, name_label) 
               VALUES (?, ?, ?, ?, ?, ?, ?, ?)
INSERT_ENTRY

    return $self->_dbh->do( $sql, undef, $language, $product, $version, $name, $format, $product_label, $version_label, $name_label );
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

# return a hash of records
sub get_hash_ref {
    my ( $self, $arg ) = @_;

    my $language = delete $arg->{language}
        || croak "get_hash_ref: language required";

    if ( %{$arg} ) {
        croak "unknown args: " . join( ", ", keys %{$arg} );
    }

    my $sql = <<GET_LIST;
        SELECT ID, 
               product, 
               version, 
               name, 
               format,
               product_label, 
               version_label, 
               name_label
          FROM $DB_NAME 
         WHERE language = ? 
      ORDER BY product, 
               version DESC, 
               name, 
               format
GET_LIST

    my $sth = $self->_dbh->prepare($sql);
    $sth->execute($language);

    my %list;

    while ( my ( $id, $product, $version, $name, $format, $product_label, $version_label, $name_label )
        = $sth->fetchrow() )
    {
        $list{$product}{$version}{$name}{'formats'}{$format} = 1;
        $list{$product}{$version}{$name}{product_label} = $product_label;
        $list{$product}{$version}{$name}{version_label} = $version_label;
        $list{$product}{$version}{$name}{name_label} = $name_label;
    }

    $sth->finish();

    return \%list;
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
        print("No langs found, using default langs\n");
        my @langs = ('en-US');
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

    my @fulltoc   = ();
    my @toc_names = ();

    foreach my $lang ( @{$langs} ) {
        my %toc;
        $toc{'products'}
            = $self->_regen_toc( { language => qq|$lang->[0]| } );
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
    }

    my $vars = {
        'static_langs'     => \@fulltoc,
        'static_langs_toc' => \@toc_names,
        'Site_Map'         => $tmpl_strings{'Site_Map'},
    };

    $self->{Template}->process( 'static_toc.tmpl', $vars,
        $self->{toc_path} . "/toc.html" )
        or croak( $self->{Template}->error() );

    $self->stats();

    return;
}

sub _regen_toc {
    my ( $self, $arg ) = @_;

    my $language = delete $arg->{language}
        || croak "_regen_toc: language required";

    if ( %{$arg} ) {
        croak "unknown args: " . join( ", ", keys %{$arg} );
    }

##    print("Processing lang: $language\n");

    my $vars = {};

    my $settings = $self->get_settings();

    my $default_search = <<SEARCH;
	<form target="_top" method="get" action="http://www.google.com/search">
		<div class="search">
			<input class="searchtxt" type="text" name="q" value="" />
			<input class="searchsub" type="submit" value="Search" />
SEARCH

    if ( $settings->{host} ) {
        $default_search .= <<SEARCH;
			<input class="searchchk" type="hidden"  name="sitesearch" value="$settings->{host}" />
SEARCH
    }

    $default_search .= <<SEARCH;
		</div>
	</form>
SEARCH

    $vars->{'search'} = ( $settings->{search} || $default_search );

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

    foreach my $string ( sort( keys(%tmpl_strings) ) ) {
        $vars->{$string} = $tmpl_strings{$string};
    }

    foreach my $product ( sort( keys( %{$list2} ) ) ) {
##        print("product: $product\n");
        my $product_label = $product;
        my %prod_data;
        my @versions = ();

        foreach
            my $version ( reverse( sort( keys( %{ $list2->{$product} } ) ) ) )
        {
            my $version_label = $version;
            my %ver_data;
            my @books = ();

            foreach
                my $book ( sort( { $a cmp $b } keys( %{ $list2->{$product}{$version} } ) ) )
            {
                my $book_label = $book;
                my %book_data;
                my @types = ();

                foreach my $type (
                    sort keys %{ $list2->{$product}{$version}{$book}{'formats'} } )
                {
                    $book_label = $list2->{$product}{$version}{$book}{name_label} if( $list2->{$product}{$version}{$book}{name_label} and $list2->{$product}{$version}{$book}{name_label} != $book);
                    $version_label = $list2->{$product}{$version}{$book}{version_label} if( $list2->{$product}{$version}{$book}{version_label} and $list2->{$product}{$version}{$book}{version_label} != $version);
                    $product_label = $list2->{$product}{$version}{$book}{product_label} if( $list2->{$product}{$version}{$book}{product_label} and $list2->{$product}{$version}{$book}{product_label} != $product);

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
                            "$self->{toc_path}/$language/$product/$version/$type/$book"
                            );
                        $type_data{'ext'} = pop(@filelist);
                    }
                    if ( $type eq 'epub' ) {
                        my @filelist
                            = File::Find::Rule->file->relative()
                            ->name('*.epub')
                            ->in(
                            "$self->{toc_path}/$language/$product/$version/$type/$book"
                            );
                        $type_data{'ext'} = pop(@filelist);
## hmm epub link for safari ...
##                        $type_data{prep} = "epub://$host/docs/$language/";
                        $type_data{onclick} = 0;
                    }

                    push( @types, \%type_data );
                }

                $book_data{'book'}       = $book;
                $book_data{'book_clean'} = $book_label;
                $book_data{'book_clean'} =~ s/_/ /g;
                $book_data{'types'} = \@types;
                push( @books, \%book_data );
            }

            $ver_data{'version'} = $version;
            $ver_data{'version_label'} = $version_label;
            $ver_data{'books'}   = \@books;
            push( @versions, \%ver_data );
        }

        $prod_data{'product'}       = $product;
        $prod_data{'product_clean'} = $product_label;
        $prod_data{'product_clean'} =~ s/_/ /g;
        $prod_data{'versions'} = \@versions;
        push( @products, \%prod_data );
    }

    $vars->{'products'} = \@products;

    $self->{Template}->process( 'toc.tmpl', $vars,
        $self->{toc_path} . "/$language/toc.html" )
        or croak( $self->{Template}->error() );

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

sub stats {
    my ( $self, $arg ) = @_;

    if ( $arg && %{$arg} ) {
        croak "unknown args: " . join( ", ", keys %{$arg} );
    }
    my $langs = $self->get_lang_list();

    my $sql = <<GET_COUNTS;
    SELECT COUNT(*) as total,
        count(DISTINCT name),
        count(DISTINCT product),
        count(DISTINCT version),
        language
    FROM $DB_NAME
    WHERE format = "html"
    GROUP BY language
    ORDER BY total desc, language
GET_COUNTS

    my %found_langs;
    my @lang_stats;
    my $total_langs    = 0;
    my $total_packages = 0;

    foreach my $counts ( @{ $self->_dbh->selectall_arrayref($sql) } ) {
        $total_langs++;
        $total_packages += $counts->[0];
        my %stats;
        my $lang = $counts->[4];
        $found_langs{$lang} = '1';
        $lang =~ m/^([^-_]*)/;
        my $lang_name = code2language($1) || "unknown $1";

        $stats{'language'} = $lang_name;
        $stats{'code'}     = $lang;
        $stats{'packages'} = $counts->[0];
        $stats{'books'}    = $counts->[1];
        $stats{'products'} = $counts->[2];
        $stats{'versions'} = $counts->[3];
        push( @lang_stats, \%stats );
    }

    foreach my $lang ( sort( keys(%LANG_NAME) ) ) {
        if ( !defined $found_langs{$lang} ) {
            $total_langs++;
            my %stats;
            $lang =~ m/^([^-_]*)/;
            my $lang_name = code2language($1) || "unknown $1";
            $stats{'language'} = $lang_name;
            $stats{'code'}     = $lang;
            $stats{'packages'} = 0;
            $stats{'books'}    = 0;
            $stats{'products'} = 0;
            $stats{'versions'} = 0;
            push( @lang_stats, \%stats );
        }
    }

    my $vars = {
        'stat_langs'     => \@lang_stats,
        'total_langs'    => $total_langs,
        'total_packages' => $total_packages
    };
    foreach my $string ( sort( keys(%tmpl_strings) ) ) {
        $vars->{$string} = $tmpl_strings{$string};
    }

    $self->{Template}->process( 'stats.tmpl', $vars,
        $self->{toc_path} . "/Site_Statistics.html" )
        or croak( $self->{Template}->error() );

    return;
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

=head2  del_entry

Delete an entry from the current Publican::WebSite DB...

Returns number of rows deleted. Should be 1 for success, 0 for failure.

=head2 get_hash_ref

Returns a reference to a has of all books for the selected language.

=head2 get_lang_list

Returns an array ref of distinct, osrted, languages.

=head2 regen_all_toc

Update the toc html files for every language.

=head2 report

Returns a string containing the current database statistics.

=head2 stats

Generate Site_Statistics.html containing the current database statistics.

=head2 get_settings

Get a reference to a hash for the settings for this site.

=head2 update_settings

Update the settings table in DB with supplied values.

Values:
	host   The host name
    search HTML to use for navigation search.

=head2 validate

Validate the database entries against the RPM database.

TODO should also/instead compare entires aginst web site files?

=head2 toc_path

Return the full toc path.

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

