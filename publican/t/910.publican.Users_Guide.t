use strict;
use warnings;

use Test::More tests => 5;
use File::pushd;
use Cwd qw(abs_path cwd);

diag("Testing bin/publican on the Users_Guide");

my $cover_db       = undef;
$cover_db = abs_path('cover_db') if ( -d 'cover_db' );
my $coverdb = undef;
$coverdb = qq|-MDevel::Cover=-db,$cover_db| if ($cover_db);
my $lib      = abs_path('blib/lib');
my $publican = abs_path('blib/script/publican');

my @perl_args = ( 'perl', '-CA', '-I', $lib );
push @perl_args, $coverdb if defined $coverdb;

my @common_opts = ( '--quiet' );

my $flink = cwd().'/blib';

my $tlink = cwd().'/Users_Guide';

my $dir = pushd('Users_Guide');
my $result;

system("ln -s $flink $tlink") unless (-l 'blib' && -d 'blib');

$result = system( @perl_args, $publican, 'print_tree', @common_opts );
is( $result, 0, 'Run print_tree' );

$result = system( @perl_args, $publican, 'update_pot', @common_opts );
is( $result, 0, 'Update POT file' );

# TODO rebuild all translation when we get some
$result = system(
    @perl_args,  $publican,    'update_po',   '--langs',
    'de-DE',     @common_opts, '--firstname', 'Dude',
    '--surname', 'McPants',    '--email',     'dudeM@example.com'
);

is( $result, 0, 'Update German PO files' );

$result = system( @perl_args, $publican, 'build', '--formats', 'html', '--langs', 'de-DE',
    @common_opts );

is( $result, 0, 'build the Users Guide' );

$result
    = system( @perl_args, $publican, 'build', '--formats',
    'html,html-single,html-desktop,pdf,txt,eclipse,epub,drupal-book',
    '--langs', 'en-US', '--publish', @common_opts );

is( $result, 0, 'build the Users Guide in all formats' );

$dir = undef;
