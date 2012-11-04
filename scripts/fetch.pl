use strict;
use warnings;

use feedme::Schema;
use feedme::Fetch;
use feedme::Parse;
use Data::Printer;

my $schema = feedme::Schema->connect('dbi:Pg:dbname=feedme;host=localhost', 'feedme', 'feedme' );
my $feeds = $schema->resultset('Feed')->search( { should_fetch => 1 } );
# my $fetcher = feedme::Fetch->new();

while ( my $feed = $feeds->next) {
    warn $feed->uri;
    my $content = feedme::Fetch::fetch_feed( $feed );

    next unless $content;
    warn $content;

    my $items = feedme::Parse::parse_rss( string => $content );

    p $items;
}
