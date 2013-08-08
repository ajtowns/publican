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
    {
        debug          => 1,
        NOCOLOURS      => 1,
        QUIET          => 1,
    }
);

my $builder = Publican::Builder->new();
isa_ok( $builder, 'Publican::Builder', 'creating a Publican::Builder' );

eval { $builder->build( { formats => "html,pdf,drupal-book", langs => "en-US", pub_dir => 'publishing' } ) };
my $e = $@;
ok( ( not $e ), "build a book" );
diag($e) if $e;

eval { $builder->package( { lang => "en-US" } ) };
$e = $@;
ok( ( not $e ), "package a book" );
diag($e) if $e;

$dir = undef;

