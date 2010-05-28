use strict;
use warnings;

use Test::More tests => 8;

BEGIN {
    use_ok('Publican');
    use_ok('Publican::CreateBook');
}

diag("Testing Publican::CreateBook $Publican::CreateBook::VERSION");

my $creator = Publican::CreateBook->new( { name => 'Test_Book' } );
isa_ok( $creator, 'Publican::CreateBook', 'creating a Publican::CreateBook' );

eval { $creator->create() };
my $e = $@;
ok( ( not $e ), "create a book" );
diag($e) if $e;

$creator = Publican::CreateBook->new(
    { name => 'Test_Article', type => 'Article' } );
isa_ok( $creator, 'Publican::CreateBook', 'creating a Publican::CreateBook' );

eval { $creator->create() };
$e = $@;
ok( ( not $e ), "create an article" );
diag($e) if $e;

$creator = Publican::CreateBook->new( { name => 'Test_Set', type => 'Set' } );
isa_ok( $creator, 'Publican::CreateBook', 'creating a Publican::CreateBook' );

eval { $creator->create() };
$e = $@;
ok( ( not $e ), "create a set" );
diag($e) if $e;

