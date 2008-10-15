# This -*- perl -*- script writes the Makefile for XML::TreeBuilder
#
# Time-stamp: "2004-06-10 19:57:41 ADT"
#
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
#

require 5.004;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	    => 'XML-TreeBuilder',
    'VERSION_FROM'  => 'lib/XML/TreeBuilder.pm',
    'ABSTRACT_FROM' => 'lib/XML/TreeBuilder.pm',

    'PREREQ_PM'    => {	
	                 'HTML::Element' => 3.08,   # at LEAST!
	                 'HTML::Tagset' => 3.02,
                         'XML::Parser' => 0,
		      },
    dist           => { COMPRESS => 'gzip -6f', SUFFIX => 'gz', },
);

package MY;

sub libscan
{ # Determine things that should *not* be installed
    my($self, $path) = @_;
    return '' if $path =~ m/~/;
    $path;
}
