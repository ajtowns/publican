use strict;
use warnings;

use File::pushd;
use Cwd qw(abs_path);

my @brands = qw{publican-fedora publican-gimp publican-jboss publican-jboss-community publican-jboss-community-hibernate publican-redhat};

system('perl Build.PL');
system('Build');

my $common_content = abs_path('blib/datadir/Common_Content');
my $common_config = abs_path('blib/datadir');
my $publican = abs_path('blib/script/publican');
my $lib = abs_path('blib/lib');
my $dir;


foreach my $brand (@brands) {
	$dir = pushd("../$brand");
	system(qq{perl -I $lib $publican build --formats=xml --langs=all --publish --common_config="$common_config" --common_content="$common_content"});
	$dir = undef;              
}

$dir = pushd('windows');
system('pp @pp-opts ..\bin\publican -vv 1>2> pp.log');
system('"C:\Program Files\NSIS\makensis.exe" publican.nsi');
$dir = undef;

exit(0);