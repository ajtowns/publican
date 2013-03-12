use strict;
use warnings;
use Module::Build;
use File::Spec;
use 5.008;

my $class = Module::Build->subclass(
    class => 'My::Builder',
    code  => q{
        use File::pushd;
        use Cwd;
        my $dir = cwd() . '/tmp/rpm';
        my $common_langs = 'all';
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
            use File::Find::Rule;
            my $rule = File::Find::Rule->new;
            $rule->file->name("*.src.rpm");
            my @rpm_files = $rule->in($dir);
            if($os_ver) {
                $self->do_system( 'rpmbuild', "--define", "_sourcedir $dir", "--define",
                    "_builddir $dir", "--define", "_srcrpmdir $dir", "--define",
                    "_rpmdir $dir", "--rebuild",        "--define",
                    "dist $os_ver", $rpm_files[0]
                );
            }
            else {
                $self->do_system( 'rpmbuild', "--define", "_sourcedir $dir", "--define",
                    "_builddir $dir", "--define", "_srcrpmdir $dir", "--define",
                    "_rpmdir $dir",  "--rebuild", $rpm_files[0]
                );
            }
        }
        sub ACTION_local {
            my $self = shift;
            $self->ACTION_rpm || die;
            use File::Find::Rule;
            my $rule = File::Find::Rule->new;
            $rule->file->name("*.rpm");
            $rule->file->not_name("*.src.rpm");
            my @rpm_files = $rule->in($dir);
            $self->do_system("sudo", "yum", "-y", "localinstall",  "--nogpg", @rpm_files);
        }
        sub process_brand_template_files {
            my $self = shift;
            use File::Find::Rule;
            use File::Copy::Recursive qw(rcopy);
            my $cwd = getcwd();
            my $path = "$cwd/blib/datadir/Common_Content/brand-template";
            mkpath("$path");
            rcopy( "datadir/Common_Content/brand-template/*", "$path/.");
        }
        sub ACTION_common_files {
            my $self = shift;
            $self->depends_on('build');
            use lib File::Spec->catdir('blib/lib');
            use File::Path;
            use File::Copy::Recursive qw(rcopy);
            eval {
                require Publican;
                $Publican::SINGLETON = undef;
                require Publican::Builder;
            };
            unless($@){
                my $cwd = getcwd();
                my $dir = pushd('datadir/Common_Content/common');
                my $path = "$cwd/blib/datadir/Common_Content";

                my $publican = Publican->new({NOCOLOURS => $self->args('nocolours'), common_config => "$cwd/datadir"});
                my $builder = Publican::Builder->new();
                $builder->build(
                    { formats => 'xml', langs => $common_langs, publish => 1 } );
                mkpath("$path");
                rcopy( "publish/*", "$path/.");
                rcopy('publican.cfg', "$path/common/.");
                $dir = undef;
                $builder = undef;
                $publican = undef;
            }
        }
        sub ACTION_commondb5_files {
            my $self = shift;
            $self->depends_on('build');
            use lib File::Spec->catdir('blib/lib');
            use File::Path;
            use File::Copy::Recursive qw(rcopy);
            eval {
                require Publican;
                $Publican::SINGLETON = undef;
                require Publican::Builder;
            };
            unless($@){
                my $cwd = getcwd();
                my $dir = pushd('datadir/Common_Content/common-db5');
                my $path = "$cwd/blib/datadir/Common_Content";

                my $publican = Publican->new({ NOCOLOURS => $self->args('nocolours'), common_config => "$cwd/datadir"});
                my $builder = Publican::Builder->new();
                $builder->build(
                    { formats => 'xml', langs => $common_langs, publish => 1 } );
                rcopy( "publish/*", "$path/.");
                rcopy('publican.cfg', "$path/common-db5/.");
                $dir = undef;
                $builder = undef;
                $publican = undef;
            }
        }
        sub ACTION_update_pot {
            my $self = shift;
            # BUGBUG TODO call Locale::Maketext::Extract::Run directly
            # use Locale::Maketext::Extract::Run 'xgettext';
            # my @args = qw(-d publican -D lib -D bin -P Locale::Maketext::Extract::Plugin::PPI=* -o po/publican.pot);
            # xgettext(@ARGV);
            $self->do_system('xgettext.pl -d publican -D lib -D bin -P Locale::Maketext::Extract::Plugin::PPI=* --wrap -o po/publican.pot');
        }
        sub ACTION_update_po {
            my $self = shift;
            use File::Find::Rule;
            my @po_files = find(
                maxdepth  => 1,
                file => name => "*.po",
                in        => 'po',
                relative  => 0,
            );
            # BUGBUG TODO switch to internal merge code
            foreach my $po_file (@po_files) {
                $self->do_system("msgmerge --quiet --no-wrap --backup=none --update $po_file po/publican.pot");
            }
        }
        sub ACTION_authortest {
            my ($self) = @_;
            $self->depends_on('build');
            $self->depends_on('distmeta');
            $self->test_files( qw< t xt/author > );
            $self->recursive_test_files(1);
            $self->depends_on('test');
            return;
        }
        sub ACTION_distdir {
            my ($self) = @_;
            $self->depends_on('update_pod');
            return $self->SUPER::ACTION_distdir();
        }
        sub ACTION_build {
            my ($self) = @_;
            $self->SUPER::ACTION_build();
            $self->depends_on('common_files');
            $self->depends_on('commondb5_files');
        }
        sub ACTION_test {
            my ($self) = @_;
            use Cwd qw(abs_path cwd);
            $self->config_data('etc', abs_path('blib/etc'));
            $self->config_data('datadir', abs_path('blib/datadir'));
            $self->config_data('web', abs_path('blib/web'));
            $self->config_data('templates', abs_path('blib/templates'));
            $self->config_data('book_templates', abs_path('blib/book_templates'));
            $self->config_data('docdir', abs_path('pod1'));
## BUGBUG TODO This hack is so the tessting works with publican uninstalled. BZ #908956
## The real fix is to either move book_templates to the brand or give it it's own conf setting
            symlink(abs_path('blib/book_templates'), abs_path('blib/datadir')."/Common_Content/common/book_templates");
            $self->SUPER::ACTION_test();
	    unlink(abs_path('blib/datadir')."/Common_Content/common/book_templates");
            $self->config_data('etc', $self->install_path('etc'));
            $self->config_data('datadir', $self->install_path('datadir'));
            $self->config_data('web', $self->install_path('web'));
            $self->config_data('templates', $self->install_path('templates'));
            $self->config_data('book_templates', $self->install_path('book_templates'));
            $self->config_data('docdir', $self->install_path('docdir'));
        }
        sub ACTION_update_pod {
            my ($self) = @_;
            use List::MoreUtils qw|uniq|;
            $self->depends_on('build');
            my $POD_FILE;
            open($POD_FILE, '>', 'pod1/publican') || die("can't open POD file");
            print($POD_FILE <<EOL);
=head1 NAME

publican - a DocBook XML publishing tool.

=head1 VERSION

This document describes publican version 1.0

=head1 SYNOPSIS

publican <command options>

publican <action> <action options>

Command Options

    --help 		Display help message
    --man		Display the man page
    --help_actions	Display a list of valid actions
    -v			Display the version of Publican
EOL

            my $pod = qx|perl -CA -I blib/lib bin/publican --help_actions|;
            print($POD_FILE $pod);
            print($POD_FILE <<EOL);
=head1 INTERFACE 

EOL

            $pod = qx|perl -CA -I blib/lib bin/publican --help all|;
            my $version = $self->dist_version;
            print($POD_FILE $pod, "\n");
            print($POD_FILE <<EOL);

=head1 CONFIGURATION AND ENVIRONMENT

Publican requires access to Apache FOP for creating PDF files.

=head1 DEPENDENCIES

EOL

            my $deps = $self->build_requires();
            my $reqs = $self->requires();
            foreach my $dep (sort(uniq(keys(%{$deps}), keys(%{$reqs})))) {
                print($POD_FILE "$dep\n");
            }

            print($POD_FILE <<EOL);

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<publican-list\@redhat.com>, or through the web interface at
L<https://bugzilla.redhat.com/bugzilla/enter_bug.cgi?product=Publican&component=publican&version=$version>.

=head1 AUTHOR

Jeff Fearn  C<< <jfearn\@redhat.com> >>
=cut
EOL

            close($POD_FILE);

            $self->do_system('perl -CA -I blib/lib bin/publican --bash');
            return;
        }
    }
);

my $builder = $class->new(
    module_name        => 'Publican',
    dist_name          => 'Publican',
    license            => 'perl',
    dist_author        => 'Jeff Fearn <jfearn@redhat.com>',
    dist_version_from  => 'lib/Publican.pm',
    configure_requires => { 'Module::Build' => 0 },
    build_requires     => {
        'Devel::Cover'                           => 0,
        'Module::Build'                          => 0,
        'Test::More'                             => 0,
        'Test::Pod'                              => 1.14,
        'Test::Pod::Coverage'                    => 1.04,
        'Archive::Tar'                           => 0,
        'Archive::Zip'                           => 0,
        'Locale::Maketext::Gettext'              => 0,
        'Carp'                                   => 0,
        'Config::Simple'                         => 0,
        'Cwd'                                    => 0,
        'DateTime'                               => 0,
        'DateTime::Format::DateParse'            => 0,
        'DBI'                                    => 0,
        'Encode'                                 => 0,
        'File::Basename'                         => 0,
        'File::Copy::Recursive'                  => 0.38,
        'File::Find'                             => 0,
        'File::Find::Rule'                       => 0,
        'File::HomeDir'                          => 0,
        'File::Inplace'                          => 0,
        'File::Path'                             => 0,
        'File::pushd'                            => 0,
        'File::Spec'                             => 0,
        'File::Which'                            => 0,
        'Getopt::Long'                           => 0,
        'HTML::FormatText'                       => 0,
        'HTML::FormatText::WithLinks'            => 0,
        'HTML::FormatText::WithLinks::AndTables' => 0.02,
        'HTML::TreeBuilder'                      => 0,
        'I18N::LangTags::List'                   => 0,
        'IO::String'                             => 0,
        'List::Util'                             => 0,
        'List::MoreUtils'                        => 0,
        'Locale::Language'                       => 0,
        'Locale::PO'                             => 0,
        'Module::Build'                          => 0,
        'Pod::Usage'                             => 0,
        'Sort::Versions'                         => 0,
        'String::Similarity'                     => 0,
        'Syntax::Highlight::Engine::Kate'        => 0,
        'Template'                               => 0,
        'Template::Constants'                    => 0,
        'Term::ANSIColor'                        => 0,
        'Text::Wrap'                             => 0,
        'Time::localtime'                        => 0,
        'XML::LibXML'                            => 1.67,
        'XML::LibXSLT'                           => 1.67,
        'XML::Simple'                            => 0,
        'XML::TreeBuilder'                       => 4.0,
        'Text::CSV_XS'                           => 0,
    },
    requires => {
        'Archive::Tar'                           => 0,
        'Archive::Zip'                           => 0,
        'Locale::Maketext::Gettext'              => 0,
        'Carp'                                   => 0,
        'Config::Simple'                         => 0,
        'Cwd'                                    => 0,
        'DateTime'                               => 0,
        'DateTime::Format::DateParse'            => 0,
        'DBI'                                    => 0,
        'Encode'                                 => 0,
        'File::Basename'                         => 0,
        'File::Copy::Recursive'                  => 0.38,
        'File::Find'                             => 0,
        'File::Find::Rule'                       => 0,
        'File::HomeDir'                          => 0,
        'File::Inplace'                          => 0,
        'File::Path'                             => 0,
        'File::pushd'                            => 0,
        'File::Spec'                             => 0,
        'File::Which'                            => 0,
        'Getopt::Long'                           => 0,
        'HTML::FormatText'                       => 0,
        'HTML::FormatText::WithLinks'            => 0,
        'HTML::FormatText::WithLinks::AndTables' => 0.02,
        'HTML::TreeBuilder'                      => 0,
        'I18N::LangTags::List'                   => 0,
        'IO::String'                             => 0,
        'List::Util'                             => 0,
        'Locale::Language'                       => 0,
        'Locale::PO'                             => 0,
        'Module::Build'                          => 0,
        'Pod::Usage'                             => 0,
        'Sort::Versions'                         => 0,
        'String::Similarity'                     => 0,
        'Syntax::Highlight::Engine::Kate'        => 0,
        'Template'                               => 0,
        'Template::Constants'                    => 0,
        'Term::ANSIColor'                        => 0,
        'Text::Wrap'                             => 0,
        'Time::localtime'                        => 0,
        'XML::LibXML'                            => 1.67,
        'XML::LibXSLT'                           => 1.67,
        'XML::Simple'                            => 0,
        'XML::TreeBuilder'                       => 4.0,
        'Text::CSV_XS'                           => 0,
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
        'Users_Guide/tmp',
        'Users_Guide/de-DE',
        'datadir/Common_Content/common/tmp',
        'datadir/Common_Content/common/publish',
        'MANIFEST.bak',
        'Site_Tech/tmp',
        'Site_Tech/publish',
        'META.yml',
        'Splash_Page/tmp/tmp',
        'Splash_Page/tmp/publish',
        'datadir/Common_Content/common-db5/tmp',
        'datadir/Common_Content/common-db5/publish',
        'META.json',
    ],
    script_files => [ 'bin/publican', 'bin/db5-valid', 'bin/db4-2-db5' ],
    bindoc_dirs  => ['pod1'],
    install_path => {
        'datadir'        => '/usr/share/publican',
        'web'            => '/usr/share/publican/sitetemplate',
        'templates'      => '/usr/share/publican/templates',
        'book_templates' => '/usr/share/publican/book_templates',
        'etc'            => '/etc',
        'completion'     => '/etc/bash_completion.d',
        'docdir'         => '/usr/share/doc/',
    },
    data_files => {
        'datadir/rpmlint.cfg'   => 'datadir/rpmlint.cfg',
        'datadir/default.db'    => 'datadir/default.db',
        'datadir/fop/fop.xconf' => 'datadir/fop/fop.xconf',
        'datadir/xsl/dt_htmlsingle_spec.xsl' =>
            'datadir/xsl/dt_htmlsingle_spec.xsl',
        'datadir/xsl/carousel.xsl'      => 'datadir/xsl/carousel.xsl',
        'datadir/xsl/xhtml-common.xsl'  => 'datadir/xsl/xhtml-common.xsl',
        'datadir/xsl/html-pdf.xsl'      => 'datadir/xsl/html-pdf.xsl',
        'datadir/xsl/html.xsl'          => 'datadir/xsl/html.xsl',
        'datadir/xsl/txt.xsl'           => 'datadir/xsl/txt.xsl',
        'datadir/xsl/web-spec.xsl'      => 'datadir/xsl/web-spec.xsl',
        'datadir/xsl/web-home-spec.xsl' => 'datadir/xsl/web-home-spec.xsl',
        'datadir/xsl/defaults.xsl'      => 'datadir/xsl/defaults.xsl',
        'datadir/xsl/html-single.xsl'   => 'datadir/xsl/html-single.xsl',
        'datadir/xsl/pdf.xsl'           => 'datadir/xsl/pdf.xsl',
        'datadir/xsl/epub.xsl'          => 'datadir/xsl/epub.xsl',
        'datadir/xsl/eclipse.xsl'       => 'datadir/xsl/eclipse.xsl',
        'datadir/xsl/man.xsl'           => 'datadir/xsl/man.xsl',
        'datadir/xsl/abstract.xsl'      => 'datadir/xsl/abstract.xsl',
        'datadir/xsl/subtitle.xsl'      => 'datadir/xsl/subtitle.xsl',
        'datadir/xsl/merge_revisions.xsl' =>
            'datadir/xsl/merge_revisions.xsl',
        'datadir/xsl/db4-upgrade.xsl' => 'datadir/xsl/db4-upgrade.xsl',
        'datadir/xsl/drupal-book.xsl' => 'datadir/xsl/drupal-book.xsl',
    },
    web_files => {
        'web/index.html'              => 'web/index.html',
        'web/toc.js'                  => 'web/toc.js',
        'web/interactive.css'         => 'web/interactive.css',
        'web/images/arrows.png'       => 'web/images/arrows.png',
        'web/images/close.png'        => 'web/images/close.png',
        'web/images/open.png'         => 'web/images/open.png',
        'web/images/page.png'         => 'web/images/page.png',
        'web/jquery-1.7.1.min.js'     => 'web/jquery-1.7.1.min.js',
        'web/jquery.jcarousel.min.js' => 'web/jquery.jcarousel.min.js',
        'web/menu.css'                => 'web/menu.css',
        'web/print.css'               => 'web/print.css',
        'web/static.css'              => 'web/static.css',
    },
    templates_files => {
        'templates/books_index.tmpl' => 'templates/books_index.tmpl',
        'templates/books_format_menu.tmpl' =>
            'templates/books_format_menu.tmpl',
        'templates/books_lang_menu.tmpl' => 'templates/books_lang_menu.tmpl',
        'templates/books_menu.tmpl'      => 'templates/books_menu.tmpl',
        'templates/index.tmpl'           => 'templates/index.tmpl',
        'templates/labels.tmpl'          => 'templates/labels.tmpl',
        'templates/language_index.tmpl'  => 'templates/language_index.tmpl',
        'templates/language_index_style_1.tmpl' =>
            'templates/language_index_style_1.tmpl',
        'templates/opds.tmpl'           => 'templates/opds.tmpl',
        'templates/opds-langs.tmpl'     => 'templates/opds-langs.tmpl',
        'templates/opds-prods.tmpl'     => 'templates/opds-prods.tmpl',
        'templates/products_index.tmpl' => 'templates/products_index.tmpl',
        'templates/products_menu.tmpl'  => 'templates/products_menu.tmpl',
        'templates/toc.tmpl'            => 'templates/toc.tmpl',
        'templates/versions_index.tmpl' => 'templates/versions_index.tmpl',
        'templates/versions_menu.tmpl'  => 'templates/versions_menu.tmpl',
        'templates/web_2_footer.tmpl'   => 'templates/web_2_footer.tmpl',
        'templates/web_2_head.tmpl'     => 'templates/web_2_head.tmpl',
        'templates/Sitemap.tmpl'        => 'templates/Sitemap.tmpl',
    },
    book_templates_files => {
        'book_templates/cover.tmpl'     => 'book_templates/cover.tmpl',
        'book_templates/footer.html'    => 'book_templates/footer.html',
        'book_templates/header.html'    => 'book_templates/header.html',
        'book_templates/toc.xsl'        => 'book_templates/toc.xsl',
        'book_templates/toc-xsl.tmpl'   => 'book_templates/toc-xsl.tmpl',
        'book_templates/titlepage.tmpl' => 'book_templates/titlepage.tmpl',
    },
    etc_files =>
        { 'etc/publican-website.cfg' => 'etc/publican-website.cfg', },
    completion_files => { 'completion/_publican' => 'completion/_publican', },
);

if ( $^O eq 'darwin' ) {
    $builder->install_path( 'datadir' => '/opt/local/share/publican' );
    $builder->install_path(
        'generated' => '/opt/local/share/publican/sitetemplate' );
    $builder->install_path(
        'web' => '/opt/local/share/publican/sitetemplate' );
    $builder->install_path(
        'templates' => '/opt/local/share/publican/templates' );
    $builder->install_path(
        'book_templates' => '/opt/local/share/publican/book_templates' );
    $builder->install_path( 'etc' => '/opt/local/etc' );
    $builder->install_path(
        'completion' => '/opt/local/etc/bash_completion.d' );
}

$builder->add_build_element('brand_template');
$builder->add_build_element('data');
$builder->add_build_element('web');
$builder->add_build_element('templates');
$builder->add_build_element('book_templates');
$builder->add_build_element('etc');
$builder->add_build_element('completion');
$builder->config_data( 'etc',       $builder->install_path('etc') );
$builder->config_data( 'datadir',   $builder->install_path('datadir') );
$builder->config_data( 'web',       $builder->install_path('web') );
$builder->config_data( 'templates', $builder->install_path('templates') );
$builder->config_data( 'book_templates',
    $builder->install_path('book_templates') );
$builder->config_data( 'docdir', $builder->install_path('docdir') );

$builder->create_build_script();

