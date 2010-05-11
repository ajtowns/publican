use strict;
use warnings;

use Test::More tests => 9;
use File::pushd;
use Cwd qw(abs_path cwd);

#BEGIN {
#use_ok( 'Publican::XmlClean' );
#}
#
#
diag("\nTesting blib/script/publican\n");

my $cover_db = undef;
$cover_db = abs_path('cover_db') if ( -d 'cover_db' );

my $common_content = abs_path('blib/datadir/Common_Content');
my $common_config  = abs_path('blib/datadir');
my $lib            = abs_path('blib/lib');
my $publican       = abs_path('blib/script/publican');
my $coverdb        = '';
$coverdb = qq|-MDevel::Cover=-db,$cover_db| if ($cover_db);

my $common_opts
    = qq|--common_config="$common_config" --common_content="$common_content"|;

is( system(qq{perl $coverdb -I $lib -c $publican $common_opts --publish}),
    0, 'test sytnax OK' );

is( system(qq{perl $coverdb -I $lib $publican --help}),
    0, 'test help output' );

is( system(qq{perl $coverdb -I $lib $publican --man}), 0, 'test man output' );

is( system(
        qq{perl $coverdb -I $lib $publican create --name foo2 $common_opts}),
    0,
    'create a book'
);

my $dir = pushd("foo2");

is( system(qq{perl $coverdb -I $lib $publican help_config $common_opts}),
    0, 'test help_config' );

is( system(qq{perl $coverdb -I $lib $publican clean_ids $common_opts}),
    0, 'Run cleanids' );

is( system(qq{perl $coverdb -I $lib $publican update_pot $common_opts}),
    0, 'Run update_pot' );

is( system(
        qq{perl $coverdb -I $lib $publican update_po --langs=de-DE $common_opts}
    ),
    0,
    'Run update_po doe de-DE'
);

is( system(
        qq{perl $coverdb -I $lib $publican build --formats=html,pdf --langs=en-US $common_opts --publish}
    ),
    0,
    'publish a book'
);

$dir = undef;

