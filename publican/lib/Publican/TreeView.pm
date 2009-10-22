package Publican::TreeView;

use strict;
use warnings;
use Carp;
use version;
use XML::TreeBuilder;
use Publican;
use vars qw($VERSION);
use File::pushd;
use Term::ANSIColor qw(:constants);

=head1 NAME

Publican::TreeView - Dumper for XInclude project structure.


=head1 VERSION

This document describes Publican::TreeView version $VERSION


=head1 SYNOPSIS

    use Publican;
    use Publican::TreeView...

=head1 DESCRIPTION

Publican::TreeView displays the xi:include structure of the entire project.

=head1 INTERFACE 

=cut

=head2  new

Create a new Publican::TreeView object.

=cut

sub new {
    my ( $this, $args ) = @_;
    my $class = ref($this) || $this;
    my $self = bless {}, $class;

    my $publican = Publican->new();
    $self->{publican} = $publican;
    return $self;
}

=head2  print_tree

Print out a tree view of xi:includes

=cut

sub print_tree {
    my ( $self, $args ) = @_;
    my $dir;
    my $in_file = ( delete $args->{'in_file'}
            || ( $self->{publican}->param('docname') ) . '.xml' );

    my $indent = ( delete $args->{'indent'} || 1 );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    if ( $in_file eq $self->{publican}->param('docname') . '.xml' ) {
        $dir = pushd( $self->{publican}->param('xml_lang') );
        logger("$in_file\n");
    }

    my $xml_doc = XML::TreeBuilder->new();
    $xml_doc->parse_file($in_file)
        || croak( maketext( "Can't open file: [_1]: [_2]", $in_file, $@ ) );

    my @nodes = $xml_doc->look_down( "_tag", "xi:include" );
    foreach my $node (@nodes) {
        my $filename = $node->attr('href');
        if ( -f $filename ) {
            if ( $filename =~ /\.xml$/ ) {
                if ( $node->attr('parse') && $node->attr('parse') eq 'text' )
                {
                    logger( "   " x $indent . "$filename\n", GREEN );
                }
                else {
                    logger( "   " x $indent . "$filename\n" );
                    $self->print_tree(
                        {   'in_file' => $filename,
                            'indent'  => ( $indent + 1 )
                        }
                    );
                }
            }
            else {
                logger( "   " x $indent . "$filename\n", MAGENTA );
            }
        }
        else {
            logger( "   " x $indent . "$filename*\n", RED );
        }
    }

    return;
}

1;    # Magic true value required at end of module
__END__

=head1 DIAGNOSTICS

=over

=item C<< unknown args %s >>

All subs with named parameters will return this error when unexpected anmed arguments are provided.

=item C<< %s is a required argument >>

Any sub with a mandadtory parameter will return this error if the parameter is undef.

=item C<< Can't open file %s >>

=back


=head1 CONFIGURATION AND ENVIRONMENT

Publican requires no configuration files or environment variables.


=head1 DEPENDENCIES

Carp
XML::TreeBuilder
Publican
File::pushd
Term::ANSIColor

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<publican-list@redhat.com>, or through the web interface at
L<https://bugzilla.redhat.com/bugzilla/enter_bug.cgi?product=Fedora&amp;version=rawhide&amp;component=publican>.


=head1 AUTHOR

Ryan Lerch  C<< <rlerch@redhat.com> >>
