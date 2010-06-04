package Publican::TreeView;

use strict;
use warnings;
use Carp;
use XML::TreeBuilder;
use Publican;
use vars qw($VERSION);
use File::pushd;
use Term::ANSIColor qw(:constants);

$VERSION = 0.1;

=head1 NAME

Publican::TreeView - Dumper for XInclude project structure.


=head1 VERSION

This document describes Publican::TreeView version 0.1


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
    $self->{first}    = 1;

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

=head2  print_unused

Print out a list of XML files that are not xi:included

=cut

sub print_unused {
    my ( $self, $args ) = @_;
    my $dir;
    my $in_file = ( delete $args->{'in_file'}
            || ( $self->{publican}->param('docname') ) . '.xml' );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    my $unused = 0;

    if ( $self->{first} ) {
        $self->{first} = 0;
        $unused = 1;
    }

    my $xml_lang = $self->{publican}->param('xml_lang');

    if ( $in_file eq $self->{publican}->param('docname') . '.xml' ) {
        $dir = pushd($xml_lang);
    }

    my $xml_doc = XML::TreeBuilder->new();
    $xml_doc->parse_file($in_file)
        || croak( maketext( "Can't open file: [_1]: [_2]", $in_file, $@ ) );

    my @nodes = $xml_doc->look_down( "_tag", "xi:include" );
    foreach my $node (@nodes) {
        my $filename = $node->attr('href');
        if ( -f $filename && $filename =~ /\.xml$/ ) {
            $self->print_unused( { 'in_file' => $filename, } );
            $self->{used_files}->{qq|'$filename'|} = 1;
        }
    }

    $dir = undef;

    if ($unused) {
        my @xml_files = dir_list( $xml_lang, '*.xml' );
        my $first = 1;

        foreach my $xml_file ( sort(@xml_files) ) {
            $xml_file =~ s/^$xml_lang\///;
            next
                if (
                $xml_file eq $self->{publican}->param('docname') . '.xml' );

            unless ( defined $self->{used_files}->{qq|'$xml_file'|} ) {
                if ($first) {
                    logger(
                        maketext("\nList of unused XML files in $xml_lang")
                            . "\n" );
                    $first = 0;
                }
                logger( "   " . "$xml_file\n", RED );
            }
        }
        if ($first) {
            logger( maketext("\nNo unused XML files") . "\n" );
        }
        logger("\n");
    }

    return;
}

1;    # Magic true value required at end of module
__END__

=head1 DIAGNOSTICS

=over

=item C<< unknown args %s >>

All subs with named parameters will return this error when unexpected named arguments are provided.

=item C<< %s is a required argument >>

Any sub with a mandatory parameter will return this error if the parameter is undef.

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
