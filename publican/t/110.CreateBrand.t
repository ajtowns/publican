use strict;
use warnings;

use Test::More tests => 5;
use File::Path;

BEGIN {
    use_ok('Publican');
    use_ok('Publican::CreateBrand');
    rmtree(['publican-Test_Brand']) if(-e 'publican-Test_Brand');
}

diag("Testing Publican::CreateBrand $Publican::CreateBrand::VERSION");
my $creator;
eval { $creator = Publican::CreateBrand->new( { name => 'Test_Brand' } ); };
my $e = $@;
like( $e, qr/^lang is a required parameter/, 'missing mandatory lang' );

eval {
    $creator
        = Publican::CreateBrand->new(
        { name => 'Test_Brand', lang => 'en-US' } );
};

isa_ok( $creator, 'Publican::CreateBrand',
    'creating a Publican::CreateBrand' );
eval { $creator->create(); };
$e = $@;
ok( ( not $e ), "create the brand" );
diag($e) if $e;

