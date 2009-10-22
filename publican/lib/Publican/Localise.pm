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

