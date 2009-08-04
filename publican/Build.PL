use strict;
use warnings;
use Module::Build;
use File::Spec;

my $class = Module::Build->subclass(
    class => 'My::Builder',
    code  => q{
       use File::pushd;
       use Cwd;
       my $dir = cwd() . '/tmp/rpm';
      sub ACTION_srpm {
        my $self = shift;
        my $os_ver = $self->args('os_ver');
        $self->SUPER::ACTION_clean;
        $self->SUPER::ACTION_dist;
        $self->do_system("mkdir -p $dir");
        $self->do_system("cp Publican*.tar.gz $dir/.");
        if($os_ver) {
            $self->do_system( 'rpmbuild', "--define", "_sourcedir $dir", "--define",
            "_builddir $dir", "--define", "_srcrpmdir $dir", "--define",
            "_rpmdir $dir", "-bs", "--nodeps", "--define",
            "dist $os_ver", "publican.spec");
        }
        else {
            $self->do_system( 'rpmbuild', "--define", "_sourcedir $dir", "--define",
            "_builddir $dir", "--define", "_srcrpmdir $dir", "--define",
            "_rpmdir $dir", "-bs", "--nodeps", "publican.spec");
        }
      }
      sub ACTION_rpm {
        my $self = shift;
        $self->ACTION_srpm;
        my $os_ver = $self->args('os_ver');
	my $srpm = `find $dir -name '*.src.rpm'`;
        chomp($srpm);
        if($os_ver) {
          $self->do_system( 'rpmbuild', "--define", "_sourcedir $dir", "--define",
            "_builddir $dir", "--define", "_srcrpmdir $dir", "--define",
            "_rpmdir $dir",  "--rebuild",        "--define",
            "dist $os_ver",   $srpm);
        }
        else {
          $self->do_system( 'rpmbuild', "--define", "_sourcedir $dir", "--define",
            "_builddir $dir", "--define", "_srcrpmdir $dir", "--define",
            "_rpmdir $dir",  "--rebuild", $srpm);
        }

      }
      sub ACTION_local {
        my $self = shift;
        $self->ACTION_rpm;
	my $rpm = `find $dir/noarch -name '*.rpm'`;
        chomp($rpm);
        $rpm =~ s/\n/ /g;
        $self->do_system("sudo yum localinstall --nogpg $rpm");
      }
      sub  process_common_files {
        my $self = shift;
        # This is how to self host
        use lib File::Spec->catdir('lib'); 
        use Publican;
        use Publican::Builder;
        use File::Path;
        use File::Copy::Recursive qw(rcopy);
        my $cwd = getcwd();
        my $dir = pushd('datadir/Common_Content/common');
        die "can't chdir: $@" if $@;

        my $publican = Publican->new();
        my $builder = Publican::Builder->new();
        $builder->build(
        { formats => 'xml', langs => 'all', publish => 1 } );
        my $path = "$cwd/blib/datadir/Common_Content";
        mkpath("$path");
        rcopy( "publish/*", "$path/.");
        $dir = undef;
      }
  }
);

# TODO validate requires are complete
my $builder = $class->new(
    module_name       => 'Publican',
    dist_name         => 'Publican',
    license           => 'perl',
    dist_author       => 'Jeff Fearn <jfearn@redhat.com>',
    dist_version_from => 'bin/publican',
    build_requires    => {
        'Devel::Cover'                    => 0,
        'Module::Build'                   => 0,
        'Test::Exception'                 => 0,
        'Test::More'                      => 0,
        'Test::Pod::Coverage'             => 0,
        'Test::Perl::Critic'              => 0,
        'Archive::Tar'                    => 0,
        'Carp'                            => 0,
        'Config::Simple'                  => 0,
        'Cwd'                             => 0,
        'Data::Dumper'                    => 0,
        'DateTime'                        => 0,
        'DateTime::Format::DateParse'     => 0,
        'Encode'                          => 0,
        'File::Copy::Recursive'           => 0.38,
        'File::Find'                      => 0,
        'File::Find::Rule'                => 0,
        'File::Path'                      => 0,
        'File::pushd'                     => 0,
        'File::Spec'                      => 0,
        'Getopt::Long'                    => 0,
        'HTML::FormatText'                => 0,
        'HTML::TreeBuilder'               => 0,
        'I18N::LangTags::List'            => 0,
        'Image::Magick'                   => 0,
        'Image::Size'                     => 0,
        'Locale::PO'                      => 0,
        'Makefile::Parser'                => 0,
        'Syntax::Highlight::Engine::Kate' => 0,
        'Term::ANSIColor'                 => 0,
        'Text::Wrap'                      => 0,
        'version'                         => 0,
        'XML::LibXML'                     => 0,
        'XML::LibXSLT'                    => 0,
        'XML::TreeBuilder'                => 3.09,
        'Locale::Maketext::Gettext'       => 0,
    },
    requires => {
        'Archive::Tar'                    => 0,
        'Carp'                            => 0,
        'Config::Simple'                  => 0,
        'Cwd'                             => 0,
        'Data::Dumper'                    => 0,
        'DateTime'                        => 0,
        'DateTime::Format::DateParse'     => 0,
        'Encode'                          => 0,
        'File::Copy::Recursive'           => 0.38,
        'File::Find'                      => 0,
        'File::Find::Rule'                => 0,
        'File::Path'                      => 0,
        'File::pushd'                     => 0,
        'File::Spec'                      => 0,
        'Getopt::Long'                    => 0,
        'HTML::FormatText'                => 0,
        'HTML::TreeBuilder'               => 0,
        'I18N::LangTags::List'            => 0,
        'Image::Magick'                   => 0,
        'Image::Size'                     => 0,
        'Locale::PO'                      => 0,
        'Makefile::Parser'                => 0,
        'Syntax::Highlight::Engine::Kate' => 0,
        'Term::ANSIColor'                 => 0,
        'Text::Wrap'                      => 0,
        'version'                         => 0,
        'XML::LibXML'                     => 0,
        'XML::LibXSLT'                    => 0,
        'XML::TreeBuilder'                => 3.09,
        'Locale::Maketext::Gettext'       => 0,
    },
    add_to_cleanup => [
        'publican-*',
        'Publican-*',
        'tmp',
        'blib',
        'foo*',
        'Test_*',
        'Users_Guide/tmp',
        'datadir/Common_Content/common/tmp',
        'datadir/Common_Content/common/publish',
    ],
    script_files => ['bin/publican'],
    install_path => { 'datadir' => '/usr/share/Publican' },
    data_files   => {
        'datadir/fop/fop.xconf'       => 'datadir/fop/fop.xconf',
        'datadir/fop/hyphenation.dtd' => 'datadir/fop/hyphenation.dtd',
        'datadir/xsl/dt_htmlsingle_spec.xsl' =>
            'datadir/xsl/dt_htmlsingle_spec.xsl',
        'datadir/xsl/xhtml-common.xsl' => 'datadir/xsl/xhtml-common.xsl',
        'datadir/xsl/html.xsl'         => 'datadir/xsl/html.xsl',
        'datadir/xsl/txt.xsl'          => 'datadir/xsl/txt.xsl',
        'datadir/xsl/web-spec.xsl'     => 'datadir/xsl/web-spec.xsl',
        'datadir/xsl/defaults.xsl'     => 'datadir/xsl/defaults.xsl',
        'datadir/xsl/html-single.xsl'  => 'datadir/xsl/html-single.xsl',
        'datadir/xsl/pdf.xsl'          => 'datadir/xsl/pdf.xsl',
    },
);
$builder->add_build_element('common');
$builder->add_build_element('data');
$builder->create_build_script();
