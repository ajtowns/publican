use strict;
use warnings;

use Test::More tests => 6;
use File::pushd;
use Cwd qw(abs_path);

BEGIN {
    use_ok('Publican');
    use_ok('Publican::XmlClean');
}

diag("Testing Publican::XmlClean $Publican::XmlClean::VERSION");

my $dir = pushd("Test_Book");

my $publican = Publican->new(
    {   debug          => 1,
        configfile     => 'publican.cfg',
        common_config  => abs_path('../blib/datadir'),
        common_content => abs_path('../blib/datadir/Common_Content')
    }
);

my $cleaner = Publican::XmlClean->new( { clean_id => 1 } );
isa_ok( $cleaner, 'Publican::XmlClean', 'creating a Publican::XmlClean' );

eval {
    $cleaner->process_file(
        { file => 'en-US/Book_Info.xml', out_file => 'en-US/Book_Info.xml' }
    );
};
my $e = $@;
ok( ( not $e ), "clean ids for a book" );
diag($e) if $e;

eval { $cleaner->print_known_tags() };
$e = $@;
ok( ( not $e ), "print_known_tags" );
diag($e) if $e;

eval { $cleaner->print_banned_tags() };
$e = $@;
ok( ( not $e ), "print_banned_tags" );
diag($e) if $e;

$dir = undef;

