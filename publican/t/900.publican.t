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
diag( "\nTesting blib/script/publican\n" );

my $cover_db = abs_path('cover_db');

my $pwd = cwd();
my $common_content = abs_path('blib/datadir/Common_Content');
my $common_config = abs_path('blib/datadir');

is(system(qq{perl -I blib/lib -c blib/script/publican  --common_config="$common_config" --common_content="$common_content" --publish}), 0, 'test sytnax OK');

is(system(qq{perl -MDevel::Cover=-db,cover_db -I blib/lib blib/script/publican --help}), 0, 'test help output');

is(system(qq{perl -MDevel::Cover=-db,cover_db -I blib/lib blib/script/publican --man}), 0, 'test man output');

is(system(qq{perl -MDevel::Cover=-db,cover_db -I blib/lib blib/script/publican create --name foo2}), 0, 'create a book');

my $dir = pushd("foo2");

is(system(qq{perl -MDevel::Cover=-db,../cover_db -I $pwd/blib/lib $pwd/blib/script/publican help_config}), 0, 'test help_config');

is(system(qq{perl -MDevel::Cover=-db,../cover_db -I $pwd/blib/lib $pwd/blib/script/publican clean_ids --common_config="$common_config" --common_content="$common_content"}), 0, 'Run cleanids');

is(system(qq{perl -MDevel::Cover=-db,../cover_db -I $pwd/blib/lib $pwd/blib/script/publican update_pot --common_config="$common_config" --common_content="$common_content"}), 0, 'Run update_pot');

is(system(qq{perl -MDevel::Cover=-db,../cover_db -I $pwd/blib/lib $pwd/blib/script/publican update_po --langs=de-DE --common_config="$common_config" --common_content="$common_content"}), 0, 'Run update_po doe de-DE');

is(system(qq{perl -MDevel::Cover=-db,../cover_db -I $pwd/blib/lib $pwd/blib/script/publican build --formats=html,pdf --langs=en-US --common_config="$common_config" --common_content="$common_content" --publish}), 0, 'publish a book');


$dir = undef;

