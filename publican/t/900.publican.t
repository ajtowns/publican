use strict;
use warnings;

use Test::More tests => 19;
use File::pushd;
use Cwd qw(abs_path cwd);

diag("\nTesting blib/script/publican\n");

my $cover_db = undef;
$cover_db = abs_path('cover_db') if ( -d 'cover_db' );

my $lib            = abs_path('blib/lib');
my $publican       = abs_path('blib/script/publican');
my $coverdb        = '';
$coverdb = qq|-MDevel::Cover=-db,$cover_db| if ($cover_db);

my $common_opts
    = qq|--quiet --nocolours|;

is( system(
        qq{perl -CA $coverdb -I $lib $publican create --name foo2 $common_opts}
    ),
    0,
    'create a book'
);

my $flink = cwd().'/blib';

my $tlink = cwd().'/foo2';

my $dir = pushd("foo2");

system("ln -s $flink $tlink");

is( system(qq{perl -CA $coverdb -I $lib $publican help_config $common_opts}),
    0, 'test help_config'
);

is( system(qq{perl -CA $coverdb -I $lib $publican clean_ids $common_opts}),
    0, 'Run cleanids' );

is( system(qq{perl -CA $coverdb -I $lib $publican add_revision $common_opts --member "testing add_revision" --lang 'en-US' --firstname 'Testing' --surname 'Tester' --email 'tt\@example.com' }),
    0, 'Run add_revision' );

is( system(qq{perl -CA $coverdb -I $lib $publican print_unused $common_opts}),
    0, 'Run print_unused' );

is( system(qq{perl -CA $coverdb -I $lib $publican print_unused_images $common_opts}),
    0, 'Run print_unused_images' );

is( system(qq{perl -CA $coverdb -I $lib $publican print_known $common_opts}),
    0, 'Run print_known' );


is( system(qq{perl -CA $coverdb -I $lib $publican update_pot $common_opts}),
    0, 'Run update_pot' );

is( system(
        qq{perl -CA $coverdb -I $lib $publican update_po --langs=de-DE --email 'test\@example.com' --firstname 'Simple' --surname 'Simon' $common_opts}
    ),
    0,
    'Run update_po doe de-DE'
);

is( system(qq{perl -CA $coverdb -I $lib $publican lang_stats $common_opts --lang 'all' }),
    0, 'Run lang_stats' );


is( system(
        qq{perl -CA $coverdb -I $lib $publican build --formats=html,pdf --langs=en-US $common_opts --publish}
    ),
    0,
    'publish a book'
);

is( system(
        qq{perl -CA $coverdb -I $lib $publican package --lang en-US $common_opts}
    ),
    0,
    'package a book'
);

is( system(qq{perl -CA $coverdb -I $lib $publican print_banned $common_opts}),
    0, 'print banned tags'
);

$dir = undef;

is( system(qq{perl -CA $coverdb -I $lib -c $publican $common_opts -v}),
    0, 'test sytnax OK' );

is( system(qq{perl -CA $coverdb -I $lib $publican -v --help all}),
    0, 'test help output' );

is( system(qq{perl -CA $coverdb -I $lib $publican --help_actions}),
    0, 'all action help' );

like(
    qx/perl -CA $coverdb -I $lib $publican pants/,
    qr/'pants' is an unknown action!/,
    'invalid action'
);

is( system(qq{perl -CA $coverdb -I $lib $publican --help build}),
    0, 'valid action help' );

is( system(qq{perl -CA $coverdb -I $lib $publican --man}),
    0, 'test man output' );


