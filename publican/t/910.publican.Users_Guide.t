use strict;
use warnings;

use Test::More tests => 5;
use File::pushd;
use Cwd qw(abs_path);

diag("Testing bin/publican on the Users_Guide");

my $common_content = abs_path('blib/datadir/Common_Content');
my $common_config  = abs_path('blib/datadir');
my $cover_db       = undef;
$cover_db = abs_path('cover_db') if ( -d 'cover_db' );
my $coverdb = '';
$coverdb = qq|-MDevel::Cover=-db,$cover_db| if ($cover_db);
my $lib      = abs_path('blib/lib');
my $publican = abs_path('blib/script/publican');
my @common_opts
    = ( '--quiet', '--common_config', $common_config, '--common_content', $common_content );

my $dir = pushd('Users_Guide');
my $result;

$result = system( 'perl', '-CA', '-I', $lib, $publican, 'print_tree', @common_opts );
is( $result, 0, 'Run print_tree' );

$result = system( 'perl', '-CA', '-I', $lib, $publican, 'update_pot', @common_opts );
is( $result, 0, 'Update POT file' );

# TODO rebuild all translation when we get some
$result = system(
    'perl',       '-CA',         '-I',      $lib,
    $publican,    'update_po',   '--langs', 'de-DE',
    @common_opts, '--firstname', 'Dude',    '--surname',
    'McPants',    '--email',     'dudeM@example.com'
);

is( $result, 0, 'Update German PO files' );

## BUGBUG why doesn't the test system see these tests being run?
$result = system(
    'perl',      '-CA',  '-I',      $lib,    $publican, 'build',
    '--formats', 'html', '--langs', 'de-DE', @common_opts
);

is( $result, 0, 'build the Users Guide' );

$result
    = system( 'perl', '-CA', '-I', $lib, $publican, 'build', '--formats',
    'html,html-single,html-desktop,pdf,txt,eclipse,epub',
    '--langs', 'en-US', '--publish', @common_opts );

is( $result, 0, 'build the Users Guide in all formats' );

$dir = undef;

