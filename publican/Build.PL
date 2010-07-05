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
        $self->ACTION_srpm || die;
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
        $self->ACTION_rpm || die;
        $self->do_system("sudo yum -y localinstall --nogpg $dir/noarch/*.rpm");
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
        my $path = "$cwd/blib/datadir/Common_Content";
	return if(-d $path);
        die "can't chdir: $@" if $@;

        my $publican = Publican->new();
        my $builder = Publican::Builder->new();
        $builder->build(
        { formats => 'xml', langs => 'all', publish => 1 } );
        mkpath("$path");
        rcopy( "publish/*", "$path/.");
        rcopy('publican.cfg', "$path/common/.");
        $dir = undef;
        $builder = undef;
        $publican = undef;
      }
      sub ACTION_update_pot {
        my $self = shift;
        $self->do_system('xgettext.pl -d publican -D lib -D bin -P Locale::Maketext::Extract::Plugin::PPI=* --wrap -o po/publican.pot');
      }
      sub  process_generated_files {
        my $self = shift;
        use Cwd qw(abs_path);
        use File::Path;
        use File::Copy::Recursive qw(rcopy);
        use File::Find::Rule;
        my $pwd = getcwd();
        return if(-d "$pwd/blib/generated");
        my $dir = pushd('Site_Tech');
        die "can't chdir: $@" if $@;
        $self->do_system(qq|perl -I $pwd/blib/lib $pwd/blib/script/publican build --formats=html-single --publish --embedtoc --langs=all --common_config="$pwd/blib/datadir" --common_content="$pwd/blib/datadir/Common_Content"|);

        my @lang_dirs = sort( { $b cmp $a } find(
                maxdepth  => 1,
                directory => name => "*-*",
                in        => 'tmp',
                relative  => 0,
        ) );
		foreach my $lang_dir (@lang_dirs) {
			my $new_dir = $lang_dir;
			$new_dir =~ s/tmp\///;
			$new_dir = "$pwd/blib/generated/$new_dir";
			mkpath($new_dir);
			rcopy("$lang_dir/html-single/index.html", "$new_dir/Site_Tech.html");
		    if ( -d "$lang_dir/html-single/images" ) {
    			mkpath("$new_dir/images");
			    rcopy( "$lang_dir/html-single/images/*", "$new_dir/images/.");
            }
        }
      }
#      sub  process_sitetemplate_files {
#        my $self = shift;
#        use Cwd;
#        use File::Copy::Recursive qw(rcopy);
#        my $pwd = getcwd();
#        rcopy("$pwd/blib/generated", "$pwd/blib/sitetemplate");
#        rcopy("$pwd/blib/web/*", "$pwd/blib/sitetemplate/.");
#      }
  }
);

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
        'Test::Pod'                       => 0,
        'Test::Pod::Coverage'             => 0,
        'Test::Perl::Critic'              => 0,
        'Archive::Tar'                    => 0,
        'Archive::Zip'                    => 0,
        'Carp'                            => 0,
        'Config::Simple'                  => 0,
        'Cwd'                             => 0,
        'Data::Dumper'                    => 0,
        'DateTime'                        => 0,
        'DateTime::Format::DateParse'     => 0,
        'DBI'                             => 0,
        'DBD::SQLite'                     => 0,
        'Encode'                          => 0,
        'File::Basename'                  => 0,
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
        'IO::String'                      => 0,
        'Locale::Language'                => 0,
        'Locale::PO'                      => 0,
        'Makefile::Parser'                => 0,
        'Syntax::Highlight::Engine::Kate' => 0,
        'Template'                        => 0,
        'Term::ANSIColor'                 => 0,
        'Text::Wrap'                      => 0,
        'version'                         => 0,
        'XML::LibXML'                     => 1.67,
        'XML::LibXSLT'                    => 1.67,
        'XML::TreeBuilder'                => 3.09,
        'Locale::Maketext::Gettext'       => 0,
    },
    requires => {
        'Archive::Tar'                    => 0,
        'Archive::Zip'                    => 0,
        'Carp'                            => 0,
        'Config::Simple'                  => 0,
        'Cwd'                             => 0,
        'Data::Dumper'                    => 0,
        'DateTime'                        => 0,
        'DateTime::Format::DateParse'     => 0,
        'Encode'                          => 0,
        'File::Basename'                  => 0,
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
        'IO::String'                      => 0,
        'Locale::Language'                => 0,
        'Locale::PO'                      => 0,
        'Makefile::Parser'                => 0,
        'Syntax::Highlight::Engine::Kate' => 0,
        'Term::ANSIColor'                 => 0,
        'Text::Wrap'                      => 0,
        'version'                         => 0,
        'XML::LibXML'                     => 1.67,
        'XML::LibXSLT'                    => 1.67,
        'XML::TreeBuilder'                => 3.09,
        'Locale::Maketext::Gettext'       => 0,
        'DBI'                             => 0,
        'DBD::SQLite'                     => 0,
        'Template'                        => 0,
    },
    add_to_cleanup => [
        'publican-*',
        'Publican-*',
        'tmp',
        'blib',
        'foo*',
        'Test_*',
        'Users_Guide/build',
        'Users_Guide/publish',
        'datadir/Common_Content/common/tmp',
        'datadir/Common_Content/common/publish',
        'MANIFEST.bak',
        'Site_Tech/tmp',
        'Site_Tech/publish',
        'META.yml',
    ],
    script_files => ['bin/publican'],
    install_path => {
        'datadir'      => '/usr/share/publican',
        'generated'    => '/usr/share/publican/sitetemplate',
        'web'          => '/usr/share/publican/sitetemplate',
        'templates'    => '/usr/share/publican/templates',
        'etc'          => '/etc',
    },
    data_files => {
        'datadir/fop/fop.xconf' => 'datadir/fop/fop.xconf',
        'datadir/xsl/dt_htmlsingle_spec.xsl' =>
            'datadir/xsl/dt_htmlsingle_spec.xsl',
        'datadir/xsl/xhtml-common.xsl'  => 'datadir/xsl/xhtml-common.xsl',
        'datadir/xsl/html.xsl'          => 'datadir/xsl/html.xsl',
        'datadir/xsl/txt.xsl'           => 'datadir/xsl/txt.xsl',
        'datadir/xsl/web-spec.xsl'      => 'datadir/xsl/web-spec.xsl',
        'datadir/xsl/web-home-spec.xsl' => 'datadir/xsl/web-home-spec.xsl',
        'datadir/xsl/defaults.xsl'      => 'datadir/xsl/defaults.xsl',
        'datadir/xsl/html-single.xsl'   => 'datadir/xsl/html-single.xsl',
        'datadir/xsl/pdf.xsl'           => 'datadir/xsl/pdf.xsl',
        'datadir/xsl/epub.xsl'          => 'datadir/xsl/epub.xsl',
        'datadir/xsl/eclipse.xsl'       => 'datadir/xsl/eclipse.xsl',
    },
    web_files => {
        'web/index.html'        => 'web/index.html',
        'web/toc.js'            => 'web/toc.js',
        'web/interactive.css'   => 'web/interactive.css',
        'web/images/arrows.png' => 'web/images/arrows.png',
    },
    templates_files => {
        'templates/static_toc.tmpl' => 'templates/static_toc.tmpl',
        'templates/toc.tmpl'        => 'templates/toc.tmpl',
        'templates/stats.tmpl'      => 'templates/stats.tmpl',
        'templates/Sitemap.tmpl'    => 'templates/Sitemap.tmpl',
    },
    etc_files =>
        { 'etc/publican-website.cfg' => 'etc/publican-website.cfg', },
);
$builder->add_build_element('common');
$builder->add_build_element('data');
$builder->add_build_element('web');
#$builder->add_build_element('sitetemplate');
$builder->add_build_element('templates');
$builder->add_build_element('etc');
$builder->add_build_element('generated');
$builder->create_build_script();
