use strict;
use warnings;

package Publican::Localise;
use base qw(Locale::Maketext::Gettext);

=head1 NAME

Publican::Localise - Publican localisation utilities.

#...any methods you might want all your languages to share...

# And, assuming you want the base class to be an _AUTO lexicon,
# as is discussed a few sections up:

=head2 fallback_language_classes

fallback to en for unknow locales

=cut

sub fallback_language_classes {
    return "en";
}

1;

package Publican::Localise::C;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::en;
use base qw(Locale::Maketext::Gettext);

return 1;

=head1
package Publican::Localise::zh_tw;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::zh_cn;
use base qw(Locale::Maketext::Gettext);

return 1;
=cut


=head1 BUGS AND LIMITATIONS

None reported.

Please report any bugs or feature requests to
C<publican-list@redhat.com>, or through the web interface at
L<https://bugzilla.redhat.com/bugzilla/enter_bug.cgi?product=Fedora&amp;version=rawhide&amp;component=publican>.

=head1 AUTHOR

Jeff Fearn  C<< <jfearn@redhat.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009 Red Hat, Inc.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

