use strict;
use warnings;

use File::pushd;
use Cwd qw(abs_path);

my @brands = qw{publican-fedora publican-gimp publican-jboss publican-jboss-community publican-jboss-community-hibernate publican-redhat publican-jboss-community-richfaces };

system('Build realclean') if( -f 'Build' );
system('perl Build.PL');
system('Build');

my $common_content = abs_path('blib/datadir/Common_Content');
my $common_config = abs_path('blib/datadir');
my $publican = abs_path('blib/script/publican');
my $lib = abs_path('blib/lib');
my $dir;

$dir = pushd("Users_Guide");
system(qq{perl -I $lib $publican clean --common_config="$common_config" --common_content="$common_content"});
system(qq{perl -I $lib $publican build --publish --formats=html-desktop --langs=en-US --common_config="$common_config" --common_content="$common_content"});
$dir = undef;

my $brand_path = 'D:\Data\temp\Redhat\publican\trunk';

foreach my $brand (@brands) {
	print("\nPreparing $brand\n");
	$dir = pushd("$brand_path/$brand");
	system(qq{perl -I $lib $publican clean --common_config="$common_config" --common_content="$common_content"});
	system(qq{perl -I $lib $publican build --formats=xml --langs=all --publish --common_config="$common_config" --common_content="$common_content"});
	$dir = undef;              
}

$dir = pushd('windows');
print("\nRunning pp\n");
system('pp @pp-opts ..\bin\publican -vv 1>2> pp.log');
print("\nRunning NSIS\n");
system('"C:\Program Files\NSIS\makensis.exe" publican.nsi');
$dir = undef;

exit(0);