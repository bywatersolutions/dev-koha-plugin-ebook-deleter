package Koha::Plugin::Com::ByWaterSolutions::EBookDeleter;

## It's good practive to use Modern::Perl
use Modern::Perl;

## Required for all plugins
use base qw(Koha::Plugins::Base);

use File::Basename;
use DateTime;
use Text::CSV;
use MARC::Record;
use MARC::Field;

use C4::Context;
use C4::Biblio;
use C4::Items;
use C4::Reserves;
use C4::Serials;

use open qw(:utf8);

## Here we set our plugin version
our $VERSION = "{VERSION}";

## Here is our metadata, some keys are required, some are optional
our $metadata = {
    name   => 'Ebook Deleter',
    author => 'Kyle M Hall',
    description => 'This plugin assists in batch deleting ebook records',
    date_authored   => '2015-07-01',
    date_updated    => '1900-01-01',
    minimum_version => '3.18',
    maximum_version => undef,
    version         => $VERSION,
};

## This is the minimum code required for a plugin's 'new' method
## More can be added, but none should be removed
sub new {
    my ( $class, $args ) = @_;

    ## We need to add our metadata here so our base class can access it
    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    ## Here, we call the 'new' method for our base class
    ## This runs some additional magic and checking
    ## and returns our actual $self
    my $self = $class->SUPER::new($args);

    return $self;
}

## The existance of a 'tool' subroutine means the plugin is capable
## of running a tool. The difference between a tool and a report is
## primarily semantic, but in general any plugin that modifies the
## Koha database should be considered a tool
sub tool {
    my ( $self, $args ) = @_;

    my $cgi = $self->{'cgi'};

    unless ( $cgi->param('url_contains') ) {
        $self->tool_step1();
    }
    else {
        $self->tool_step2();
    }

}

## This is the 'install' method. Any database tables or other setup that should
## be done when the plugin if first installed should be executed in this method.
## The installation method should always return true if the installation succeeded
## or false if it failed.
sub install() {
    my ( $self, $args ) = @_;

    return 1;
}

## This method will be run just before the plugin files are deleted
## when a plugin is uninstalled. It is good practice to clean up
## after ourselves!
sub uninstall() {
    my ( $self, $args ) = @_;

    return 1;
}

sub tool_step1 {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $template = $self->get_template( { file => 'tool-step1.tt' } );

    print $cgi->header();
    print $template->output();
}

sub tool_step2 {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $url_contains = $cgi->param('url_contains');
    my $url_ends_with = $cgi->param('url_ends_with');

    my @lines = split /\r?\n/, $url_ends_with;

    my $dbh = C4::Context->dbh();
    my $query = qq{
        SELECT biblionumber
        FROM biblioitems
        WHERE url LIKE '%$url_contains%'
        AND (
    };

    my @likes = map { "( url LIKE '%$_' OR url LIKE '%$_  | %' )" } @lines;
    $query .= join( ' OR ', @likes );
    $query .= ')';

    my $bibs = $dbh->selectall_arrayref( $query, { Slice => {} } );

    my $url = '/cgi-bin/koha/tools/batch_delete_records.pl?recordtype=biblio&op=list&recordnumber_list=';
    $url .= join( '%0D%0A', map { $_->{biblionumber}  } @$bibs );

    print $cgi->redirect($url);
}

1;
