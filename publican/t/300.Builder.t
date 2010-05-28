use strict;
use warnings;

use Test::More tests => 5;
use File::pushd;
use Cwd qw(abs_path);

BEGIN {
    use_ok('Publican');
    use_ok('Publican::Builder');
}

diag("Testing Publican::Builder $Publican::Builder::VERSION");

my $dir = pushd("Test_Book");

my $publican = Publican->new(
    {   debug          => 1,
        common_config  => abs_path('../blib/datadir'),
        common_content => abs_path('../blib/datadir/Common_Content')
    }
);

my $builder = Publican::Builder->new();
isa_ok( $builder, 'Publican::Builder', 'creating a Publican::Builder' );

eval { $builder->build( { formats => "html,pdf", langs => "en-US" } ) };
my $e = $@;
ok( ( not $e ), "build a book" );
diag($e) if $e;

eval { $builder->package( { lang => "en-US" } ) };
$e = $@;
ok( ( not $e ), "tar a book" );
diag($e) if $e;

$dir = undef;

