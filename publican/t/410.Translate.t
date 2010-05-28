use strict;
use warnings;

use Test::More tests => 3;
use File::pushd;
use Cwd qw(abs_path);

BEGIN {
    use_ok('Publican');
    use_ok('Publican::Translate');

    #use_ok( 'Publican::Builder' );
}

diag("Testing Publican::Translate $Publican::Translate::VERSION");

#my $dir = pushd("Users_Guide");
my $dir = pushd("Test_Book");

my $publican = Publican->new(
    {   debug          => 1,
        common_config  => abs_path('../blib/datadir'),
        common_content => abs_path('../blib/datadir/Common_Content')
    }
);

my $trans = Publican::Translate->new();

eval { $trans->update_pot() };
my $e = $@;
ok( ( not $e ), "Update POT  files" );
diag($e) if $e;

#my $builder = Publican::Builder->new();

#eval { $builder->build({formats => "html-single", langs => "de-DE"}) };
#$e = $@;
#ok( (not $e),  "build a book" );
#diag($e) if $e;

$dir = undef;

