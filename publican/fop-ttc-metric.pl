#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use Carp;

=head1 NAME

fop-ttc-metrics.pl - script to handle TrueType font Collections.

=head1 SYNOPSIS

fop-ttc-metrics.pl <options>

Options

    --help 		Display help message
    --man		Display the man page
    --outdir		Change the output directory for the metric xml files
    --share		Change the share directory where publican common files
			get installed

=head1 DESCRIPTION

FOP <= 0.95 can not automatically generate metrics for true Type collections so
Publican must generate them at build time.

This script will look for known ttc files and generate metrics if they are found.
This requires the packaging system to Require the ttc font packages as build and
install dependencies.

=cut

my $man       = undef;
my $help      = undef;
my $outdir    = 'font-metrics';
my $share     = '/usr/share/publican';
my $conf_file = 'datadir/fop/fop.xconf';

GetOptions(
    'h|help|?'   => \$help,
    'man'        => \$man,
    'outdir|d=s' => \$outdir,
    'share=s'    => \$share,
    'conffile=s' => \$conf_file,
) or pod2usage(2);
pod2usage(1) if $help;
pod2usage( -verbose => 2 ) if $man;

# FYI you also need to add the font names to template pickfont in datadir/xsl/pdf.xsl
my %ttclist = (
    'AR PL UMing CN' => {
        path   => '/usr/share/fonts/cjkuni-uming/uming.ttc',
        style  => [ 'normal', 'italic' ],
        weight => [ 'normal', 'bold' ],
    },
    'AR PL UMing TW' => {
        path   => '/usr/share/fonts/cjkuni-uming/uming.ttc',
        style  => [ 'normal', 'italic' ],
        weight => [ 'normal', 'bold' ],
    },
);

my $log_jar = '/usr/share/java/commons-logging.jar';

$log_jar = '/usr/share/java/commons-logging-1.1.1.jar' if(-f '/usr/share/java/commons-logging-1.1.1.jar') ;

my $ttfcommand
    = qq|java -cp /usr/share/java/fop.jar:/usr/share/java/avalon-framework.jar:$log_jar:/usr/share/java/commons-io.jar:/usr/share/java/xmlgraphics-commons.jar org.apache.fop.fonts.apps.TTFReader|;

open( my $conf, '>', $conf_file )
    || croak("Can't open fop.xconf for output!: $!");

sub font_metrics {
    `rm -rf $outdir`;
    system("mkdir -p $outdir");
    croak("can't create metric dir: $!") if ($@);

    foreach my $font ( sort( keys(%ttclist) ) ) {
        my $path                   = $ttclist{$font}{path};
        my $spaces_break_stupid_os = $font;
        $spaces_break_stupid_os =~ s/\s/_/g;
        my $url = qq{$share/fop/font-metrics/$spaces_break_stupid_os.xml};

        if ( -f $path ) {
            my $command
                = qq{$ttfcommand -fn "$font" -ttcname "$font" $path $outdir/$spaces_break_stupid_os.xml};
            print STDERR $command;
            my $result = system($command );
            croak("FAILED to create font metric for $font: $!")
                if ( $@ || $result );
            print {$conf}
                qq{\t\t\t\t<font metrics-url="$url" kerning="yes" embed-url="$path">\n};
            foreach my $style ( @{ $ttclist{$font}{style} } ) {
                foreach my $weight ( @{ $ttclist{$font}{weight} } ) {
                    print {$conf}
                        qq{\t\t\t\t\t<font-triplet name="$font" style="$style" weight="$weight"/>\n};
                }
            }
            print {$conf} qq{\t\t\t\t</font>\n};
        }
    }
}

print {$conf} <<TOP;
<?xml version="1.0"?>
<fop version="1.0">
\t<base>.</base>
\t<source-resolution>72</source-resolution>
\t<target-resolution>72</target-resolution>
\t<default-page-settings height="240mm" width="120mm"/>
\t<renderers>
\t\t<renderer mime="application/pdf">
\t\t\t<filterList>
\t\t\t\t<value>flate</value>
\t\t\t</filterList>
\t\t\t<fonts>
TOP

font_metrics();

print {$conf} <<BOTTOM;
\t\t\t\t<auto-detect/>
\t\t\t</fonts>
\t\t</renderer>
\t</renderers>
</fop>
BOTTOM

close($conf);

exit;

