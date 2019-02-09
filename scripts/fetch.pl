use strict;
use warnings;

use FindBin;
use Cwd qw/realpath/;
use Dancer2 ':script';
use Try::Tiny;
use Getopt::Long;

my $env = 'development';
my $verbose;

my $result = GetOptions( 
    "env=s"   => \$env,
    "verbose" => \$verbose
);

config->{environment} = $env;

use Modern::Perl;
use feedme::Schema;
use feedme::Fetch;
use feedme::Parse;
use feedme::Process;

my $db_conf = config->{plugins}->{DBIC}->{default};

my $schema = feedme::Schema->connect(
    $db_conf->{dsn},
    $db_conf->{user},
    $db_conf->{password}
);
    
my $feeds = $schema->resultset('Feed')->search( { should_fetch => 1 } );

while ( my $feed = $feeds->next) {
    warn $feed->uri if $verbose;
    my $content = feedme::Fetch::fetch_feed( $feed );

    next unless $content;

    my $items;

    try {
        $items = feedme::Parse::parse_rss( string => $content, base => $feed->uri, feed => $feed );
    } catch { 
        warning sprintf( "problem parsing feed %s:\n%s\n", $feed->name, $_ );
    };

    try {
        feedme::Process::process_feed(
            $items,
            $feed,
            $schema,
        ) if $items;
    } catch {
        warn sprintf( "problem processing feed %s:\n%s\n", $feed->name, $_ );
    };
}
