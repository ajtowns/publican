package Publican::TreeView;

use strict;
use warnings;
use Carp;
use XML::TreeBuilder;
use Publican;
use vars qw($VERSION);
use File::pushd;
use Term::ANSIColor qw(:constants);
use File::Basename;

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
            || ( $self->{publican}->param('mainfile') ) . '.xml' );

    my $indent = ( delete $args->{'indent'} || 1 );
    my $path   = ( delete $args->{'path'}   || '' );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    if ( $in_file eq $self->{publican}->param('mainfile') . '.xml' ) {
        $dir = pushd( $self->{publican}->param('xml_lang') );
        logger("$in_file\n");
    }
    elsif ( dirname($in_file) ne '.' ) {
        $path = dirname($in_file) . '/';
    }

    my $xml_doc = XML::TreeBuilder->new();
    $xml_doc->parse_file($in_file)
        || croak( maketext( "Can't open file: [_1]: [_2]", $in_file, $@ ) );

    my @nodes = $xml_doc->look_down( "_tag", "xi:include" );
    foreach my $node (@nodes) {
        my $filename = $node->attr('href');
        if ( -f "$path$filename" ) {
            if ( "$filename" =~ /\.xml$/ ) {
                if ( $node->attr('parse') && $node->attr('parse') eq 'text' )
                {
                    logger( "   " x $indent . "$path$filename\n", GREEN );
                }
                else {
                    logger( "   " x $indent . "$path$filename\n" );
                    $self->print_tree(
                        {   in_file => "$path$filename",
                            indent  => ( $indent + 1 ),
                            path    => $path,
                        }
                    );
                }
            }
            else {
                logger( "   " x $indent . "$path$filename\n", MAGENTA );
            }
        }
        else {
            logger( "   " x $indent . "$path$filename*\n", RED );
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
            || ( $self->{publican}->param('mainfile') ) . '.xml' );
    my $path = ( delete $args->{'path'} || '' );

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

    if ( $in_file eq $self->{publican}->param('mainfile') . '.xml' ) {
        $dir = pushd($xml_lang);
    }
    elsif ( dirname($in_file) ne '.' ) {
        $path = dirname($in_file) . '/';
    }

    my $xml_doc = XML::TreeBuilder->new();
    $xml_doc->parse_file($in_file)
        || croak( maketext( "Can't open file: [_1]: [_2]", $in_file, $@ ) );

    my @nodes = $xml_doc->look_down( "_tag", "xi:include" );
    foreach my $node (@nodes) {
        my $filename = $node->attr('href');
        if ( -f "$path$filename" && $filename =~ /\.xml$/ ) {
            if ( !$node->attr('parse') || $node->attr('parse') ne 'text' ) {
                $self->print_unused(
                    { 'in_file' => "$path$filename", path => $path, } );
            }
            $self->{used_files}->{qq|'$path$filename'|} = 1;
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
                $xml_file eq $self->{publican}->param('mainfile') . '.xml' );

            unless ( ( defined $self->{used_files}->{qq|'$xml_file'|} )
                || ( defined $self->{used_files}->{qq|'./$xml_file'|} ) )
            {
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

=head2  print_unused_images

Print out a list of image files that are not used.

=cut

sub print_unused_images {
    my ( $self, $args ) = @_;

    my $in_file = ( delete $args->{'in_file'}
            || ( $self->{publican}->param('mainfile') ) . '.xml' );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    my ( %used_files, %missing_files );
    my $xml_lang  = $self->{publican}->param('xml_lang');
    my @xml_files = dir_list( $xml_lang, '*.xml' );
    my $first     = 1;

    foreach my $xml_file ( sort(@xml_files) ) {

        my $xml_doc = XML::TreeBuilder->new();
        $xml_doc->parse_file($xml_file)
            || croak(
            maketext( "Can't open file: [_1]: [_2]", $xml_file, $@ ) );

        my @nodes = $xml_doc->look_down( "_tag", "imagedata" );
        foreach my $node (@nodes) {
            my $filename = $node->attr('fileref');
            $filename =~ s/'//g;

            if ( -f "$xml_lang/$filename" ) {
                $used_files{"$filename"} = 1;
            }
            else {
                $missing_files{"$filename"} = 1;
            }
        }
    }

    my @image_files = dir_list( $xml_lang, '.*\.(svg|png|jpg|jpeg|gif)$', 1 );
    $first = 1;

    foreach my $image ( sort(@image_files) ) {
        $image =~ s/^$xml_lang\///;

        unless ( ( defined $used_files{"$image"} )
            || ( defined $used_files{"./$image"} ) )
        {
            if ($first) {
                logger(   "\n"
                        . maketext("List of unused Image files in $xml_lang")
                        . "\n" );
                $first = 0;
            }
            logger( "    " . "$image\n", RED );
        }
    }

    if ($first) {
        logger( "\n" . maketext("No unused Image files") . "\n" );
    }

    if (%missing_files) {
        logger(   "\n"
                . maketext("List of missing Image files in $xml_lang")
                . "\n" );
        foreach my $image ( sort( keys %missing_files ) ) {
            logger( "    " . "$image\n", RED );
        }
    }

    logger("\n");

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
L<https://bugzilla.redhat.com/bugzilla/enter_bug.cgi?product=Publican&amp;component=publican>.


=head1 AUTHOR

Ryan Lerch  C<< <rlerch@redhat.com> >>
