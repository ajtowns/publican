use strict;
use warnings;

use Test::More tests => 5;
use File::pushd;
use Cwd qw(abs_path);

#BEGIN {
#use_ok( 'Publican::XmlClean' );
#}

diag("Testing bin/publican on the Users_Guide");

my $common_content = abs_path('blib/datadir/Common_Content');
my $common_config  = abs_path('blib/datadir');
my $cover_db       = undef;
$cover_db = abs_path('cover_db') if ( -d 'cover_db' );
my $coverdb = '';
$coverdb = qq|-MDevel::Cover=-db,$cover_db| if ($cover_db);
my $lib      = abs_path('blib/lib');
my $publican = abs_path('blib/script/publican');
my $common_opts
    = qq|--common_config="$common_config" --common_content="$common_content"|;

my $dir = pushd('Users_Guide');

## is(system('perl -I ../blib/lib ../blib/script/publican old2new'), 0, 'Run old2new');

is( system(qq{perl -I $lib $coverdb $publican print_tree $common_opts}),
    0, 'Run print_tree' );

is( system(qq{perl -I $lib $coverdb $publican update_pot $common_opts}),
    0, 'Update POT file' );

# TODO rebuild all translation when we get some
is( system(
        qq{perl -I $lib $coverdb $publican update_po --langs=de-DE $common_opts}
    ),
    0,
    'Update German PO files'
);

is( system(
        qq{perl -I $lib $coverdb $publican build --formats=eclipse,epub,html,html-single,html-desktop,pdf,txt --langs=en-US $common_opts}
    ),
    0,
    'build the Users Guide'
);

# TODO build translation when we get one
is( system(
        qq{perl -I $lib $coverdb $publican build --formats=html --langs=de-DE $common_opts}
    ),
    0,
    'build the Users Guide'
);

$dir = undef;

