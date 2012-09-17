package Publican::Drupal::NodeImport;

use strict;
use warnings;
use Carp;
use Publican;
use XMLRPC::Lite;
use Net::FTP;


sub new {
    my ( $this, $args ) = @_;
    my $class = ref($this) || $this;

    my $lang = delete $args->{lang}
      || croak maketext("lang is the mandatory argument for NodeImport constructor");

    my $self = bless {}, $class;

     $self->{publican}   = Publican->new();

    $self->{xmlrpc_server}   = "http://kabuto.cloud.lab.eng.bne.redhat.com/drupal/?q=drupalxmlrpc";
    $self->{upload_file_dir} = "sites/default/files/imports";

    my $tmp_dir = $self->{publican}->param('tmp_dir');
    my $docname = $self->{publican}->param('docname');
    my $product = $self->{publican}->param('product');
    my $version = $self->{publican}->param('version');
    my $edition = $self->{publican}->param('edition');

    $self->{prefix}     = "$product-$version";
    $self->{book}       = "$self->{prefix}-$docname-$edition";
    $self->{drupal_dir} = "$tmp_dir/$lang/drupal-book";
    $self->{file_name}   = $self->{book} . ".csv";
    $self->{file_path}  =  $self->{upload_file_dir} . '/' . $self->{file_name};
    

    $self->{task} = {
                  'headers' => [
                               'Title',
                               'Book',
                               'Parent item',
                               'Weight',
                               'Menu link title',
                               'Alias for node which should be used as parent menu',
                               'Body',
                               'Input format',
                               'Authored By',
                               'Published',
                               'URL path settings'
                             ],
                  'options' => [],
                  'fid' => 60,
                  'defaults' => {
                                'book:weight' => '0',
                                'uid' => '',
                                'status' => '1',
                                'promote' => '0',
                                'menu:parent' => 'primary-links:0',
                                'created' => '',
                                'sticky' => '0',
                                'comment' => '2',
                                'format' => '1',
                                'book:book' => '<new>',
                                'type' => 'book',
                                'log' => 'Imported with node_import.'
                              },
                  'has_headers' => '1',
                  'map' => {
                           'book:weight' => '3',
                           'uid' => '8',
                           'menu:link_title' => '4',
                           'status' => '9',
                           'path' => '10',
                           'promote' => '',
                           'book:parent' => '2',
                           'menu:path' => '5',
                           'created' => '',
                           'body' => '6',
                           'comment' => '',
                           'sticky' => '',
                           'format' => '7',
                           'book:book' => '1',
                           'title' => '0'
                         },
                  'uid' => '1',
                  'name' => $self->{book} . "xmlrpc_test",
                  'file_options' => {
                                    'other record separator' => '',
                                    'field separator' => ',',
                                    'other field separator' => '',
                                    'text delimiter' => '"',
                                    'escape character' => '"',
                                    'record separator' => '<newline>',
                                    'other escape character' => '',
                                    'file_format' => 'csv',
                                    'other text delimiter' => ''
                                  },
                  'type' => 'node:book'
                };

    return $self;
}


sub connect() {
    my ($self, $args) = @_;
    my $anonymous = $self->xmlrpc_call("system.connect");
    my $user = $self->xmlrpc_call("user.login", "hyu", "haotest1");

    if (!$user) {
        croak ( maketext("Invalid username or password") );
    }

    return $user;
}


sub import_nodes {
    my ($self, $args) = @_;

    my $task_id = $self->xmlrpc_call("node_import.save_task", $self->{task} );

    if ( $task_id ) {
        $self->{task}{taskid} = $task_id;
        $self->xmlrpc_call("node_import.do_task", $self->{task} , 'all', 0 );
    } 
}

#sub node_exists {
#    my ($self, $args) = @_;
#
#    my $title = delete $args->{title}
#      || croak( maketext("title is a mandatory argument for node_exists") );
#
#    my $nodes = $self->xmlrpc_call("node_import.retrieve", $title);
#    use Data::Dumper;
#    print Dumper($nodes);
#
#    return $nodes;
#}

sub upload_file {
     my ($self, $args) = @_;
}

sub xmlrpc_call {  
    my $self   = shift;
    my $method = shift;
    my @args   = @_;


    my $rpc = XMLRPC::Lite->new( proxy => $self->{xmlrpc_server} );
    my $call;

    if (@args) {
        $call = $rpc->call($method, @args);
    }
    else {
        $call = $rpc->call($method);
    }

    if ($call->fault) {
        croak ( maketext($call->faultstring) );
    } 
 
    return $call->result;     
}

1;
