use strict;
use warnings;

use Test::More tests => 8;
use File::pushd;
use File::Path;

use Cwd qw(abs_path cwd);

BEGIN {
    use_ok('Publican');
    use_ok('Publican::Builder');
    use_ok('Publican::WebSite');
}

diag("Testing build a website with publican");

my $cover_db       = undef;
$cover_db = abs_path('cover_db') if ( -d 'cover_db' );
my $coverdb = undef;
$coverdb = qq|-MDevel::Cover=-db,$cover_db| if ($cover_db);

my $lib      = abs_path('blib/lib');
my $publican = abs_path('blib/script/publican');

my @perl_args = ( 'perl', '-CA', '-I', $lib );
push @perl_args, $coverdb if defined $coverdb;

my @common_opts = ( '--quiet' );

my $directory = 'foo3';

mkpath($directory) unless -d $directory;

my $result;

my $flink = cwd() . '/blib';

my $tlink = cwd() . '/foo3';

my $dir = pushd('foo3');

system("ln -s $flink $tlink") unless ( -l 'blib' && -d 'blib' );

$result = system(
    @perl_args,  $publican,      'create_site', '--site_config', 'foomaster.cfg',
    '--db_file', 'foomaster.db', '--toc_path',  'html/docs',     @common_opts
);
is( $result, 0, 'build the website structure' );

$dir = undef;

my $site_config = abs_path('foo3/foomaster.cfg');

$dir = pushd('Users_Guide');

$result
    = system( @perl_args, $publican, 'install_book', '--site_config', $site_config, '--lang',
    'en-US', @common_opts );
is( $result, 0, 'install the Users Guide on the website' );

$result = system( @perl_args, $publican, 'remove_book', '--site_config', $site_config, '--lang',
    'en-US', @common_opts );
is( $result, 0, 'remove the Users Guide on the website' );

$dir = undef;

$result = system( @perl_args, $publican, 'site_stats', '--site_config', $site_config,
    @common_opts );
is( $result, 0, 'report on the content of a Website' );

$result = system( @perl_args, $publican, 'update_site', '--site_config', $site_config,
    @common_opts );
is( $result, 0, 'refresh the website structure' );

