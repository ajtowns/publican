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

fallback to en for unknown locales

=cut

sub fallback_language_classes {
    return "en";
}

1;

package Publican::Localise::C;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::as;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::bg;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::bn_in;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::bs;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::ca;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::cs;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::da;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::de;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::el;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::en;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::es;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::fi;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::fr;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::gu;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::he;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::hi;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::hr;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::hu;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::id;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::it;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::ja;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::kn;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::ko;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::lv;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::ml;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::mr;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::ms;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::nb;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::nl;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::or;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::pa;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::pl;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::pt;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::pt_br;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::ru;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::sk;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::sr_latn;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::sr;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::sv;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::ta;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::te;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::uk;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::zh_cn;
use base qw(Locale::Maketext::Gettext);

return 1;

package Publican::Localise::zh_tw;
use base qw(Locale::Maketext::Gettext);

return 1;

=head1
package Publican::Localise::de_de;
use base qw(Locale::Maketext::Gettext);

return 1;

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

