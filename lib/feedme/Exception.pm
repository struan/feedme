package feedme::Exception;

use Exception::Class (
    feedme::Exception => {
        fields  =>  'feed',
        description =>  'feedme2 error',
    },
    feedme::Exception::Fetch => {
        isa =>  'feedme::Exception',
        fields  =>  [ qw( code msg feed ) ],
        description =>  'error fetching rss',
    },
    feedme::Exception::Fetch::MaxNotFound => {
        isa =>  'feedme::Exception',
        fields  =>  [ qw( code msg feed ) ],
        description =>  'Exceeded max not found count',
    },
    feedme::Exception::Fetch::NoFeed => {
        isa =>  'feedme::Exception',
        fields  =>  [ qw( code msg feed ) ],
        description =>  'Failed to fetch feed on inital attempt',
    },
    feedme::Exception::Fetch::NotAllowed => {
        isa =>  'feedme::Exception',
        fields  =>  [ qw( code msg feed ) ],
        description =>  'Feed is either gone or access forbidden',
    },
    feedme::Exception::Parse => {
        isa =>  'feedme::Exception',
        fields => [ qw( fatal feed ) ],
        description =>  'error parsing rss',
    },
    feedme::Exception::Autodiscover => {
        isa =>  'feedme::Exception',
        fields => [ qw( uri feed ) ],
        description =>  'autodiscovery failed to find feed',
    },
    feedme::Exception::Require => {
        isa =>  'feedme::Exception',
        fields => [ qw( module feed ) ],
        description => 'optional module could not be loaded',
    }
);

# we need this to go after the use Exception::Class as it's
# actually in Exception::Class
use base 'Exception::Class::Base';

sub full_message {
    my $self = shift;

    my $message = 'ERROR' . ( $self->feed ?
                            ' with ' . $self->feed :
                            '' ) . ': ' . $self->description;

    if ( UNIVERSAL::can( $self, 'code' ) ) {
        $message .= ' (' . $self->code . ' error: ' . $self->msg . ')';
    } elsif ( UNIVERSAL::isa( $self, 'feedme::Exception::Autodiscover' ) ) {
        $message .= ' (uri: ' . $self->uri . ')';
    } elsif ( UNIVERSAL::isa( $self, 'feedme::Exception::Require' ) ) {
        $message .= ' (' . $self->module . ')';
    } else {
        $message .= ' (' . $self->error . ')';
    }

    return $message;
}

# hacky xml generation of this sort is asking for trouble
# but anything else is frankly overblown...
sub rss {
    my $self = shift;
    my $feed = shift;
    my $name = $feed->name;
    my $uri = $feed->uri;

    my $rss = qq(<?xml version="1.0"?>
    <rss version="0.91">
    <channel>
        <title>$name</title>
        <link>$uri</link>
        <description>Automatic unsubscribe info</description>
        <language>en</language>
        <item>
             <title>Unsubscribed from feed</title>
             <link>$uri</link>
             <description>);
    $rss .= $self->description;
    $rss .= qq(</description>
            </item>
        </channel>
    </rss>);

    return $rss;
}

1;
