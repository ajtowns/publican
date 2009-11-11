use strict;
use warnings;

use Test::More tests => 3;
use File::pushd;
use Cwd qw(abs_path);

#BEGIN {
#use_ok( 'Publican::XmlClean' );
#}

diag( "Testing bin/publican on the Users_Guide" );

my $common_content = abs_path('blib/datadir/Common_Content');
my $common_config = abs_path('blib/datadir');
my $cover_db = abs_path('cover_db');

my $dir = pushd('Users_Guide');

is(system('perl -I ../blib/lib ../blib/script/publican old2new'), 0, 'Run old2new');

is(system('perl -I ../blib/lib ../blib/script/publican printtree'), 0, 'Run print_tree');

# TODO build translation when we get one
is(system(qq{perl -I ../blib/lib ../blib/script/publican build --formats=pdf,html --langs=en-US --common_config="$common_config" --common_content="$common_content"}), 0, 'build the Users Guide');

$dir = undef;

