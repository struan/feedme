package feedme::Fetch;

use strict;
use warnings;
use Carp;
use HTTP::Headers;
use HTTP::Request;
use LWP::UserAgent;

use feedme::Exception;
use feedme::UserAgent;
use feedme::Util;

sub fetch_feed {
    my $feed = shift;
    my $content;

    Dancer::debug sprintf( "fetching feed %d (%s)", $feed->id, $feed->name);
    
    eval { 
        $content = fetch( { feed => $feed } );
    };
    if ( $@ ) {
        if ( UNIVERSAL::isa( $@, 'feedme::Exception::Fetch::NoFeed' ) 
             or UNIVERSAL::isa( $@, 'feedme::Exception::Fetch::MaxNotFound' ) 
             or UNIVERSAL::isa( $@, 'feedme::Exception::Fetch::NotAllowed' ) 
        ) {
            Dancer::error $@;
            $content = $@->rss($feed);
            $feed->update( { should_fetch => 0 } );
        } elsif ( UNIVERSAL::isa( $@, 'feedme::Exception::Fetch' ) ) {
            Dancer::error $@;
        } else {
            croak $@;
        }
    }

    return $content;
}

# grab the rss from the intarweb
# we grab the various headers from the db so we can do a conditional
# GET and then return undef if nothing's changed
# also magic to make sure we do the right thing with 301, 410 and 403
# responses.
sub fetch {
    my ( $feed, $name, $uri, $head );
    my $args = shift;
    if ( $args->{feed} ) {
        $feed = $args->{feed};
        $name = $feed->name;
        $uri  = $feed->uri;
    } elsif ( $args->{name} and $args->{uri} ) {
        $name = $args->{name};
        $uri  = $args->{uri};
    }

    # set headers for only updated HTTP GET magic
    if ( $feed ) {
        $head = $feed->headers();
    }
    my $ua = feedme::UserAgent->new(
        agent   =>  "feedme (http://exo.org.uk/code/feedme/)",
        timeout =>  30,     # otherwise we have to wait 180, YAWN
    );
    my $req = HTTP::Request->new(GET =>  $uri, $head || undef);
    my $resp = $ua->simple_request($req);
   
    # some sort of redirect was issued so we need to follow it, 
    # however as some people like to issue multiple redirects
    # for reasons unknowable we check till all is well.
    while ( $resp->code != 304 and $resp->code >= 300 and $resp->code < 400 ) { 

        # 'cause you know, some people are idiots
        feedme::Exception::Fetch->throw(
            feed  => $name,
            error => 'No location header on redirect',
        ) unless $resp->header('location');
        
        # permanent redirect
        $feed->uri( $resp->header('location') ) if $feed and $resp->code == 301;
        $uri = $resp->header('location');

        # update feed now because if we have a 301 to a location that then 
        # returns a 304 the new location will get thrown away _and_ Class::DBI
        # will complain about feed being destroyed with changed uri. 
        $feed->update() if $feed;
            
        $req = HTTP::Request->new(
                GET =>  feedme::Util::uri_to_abs( $resp->header('Location'), 
                                     $resp->base ),
                    $head
               );
        $resp = $ua->simple_request($req);
    }

    # we're never going to be able to fetch this so unsubscribe
    if ( $resp->code == 410 || $resp->code == 403 ) {
        feedme::Exception::Fetch::NotAllowed->throw(
            feed  => $name,
            code  => $resp->code,
            msg   => $resp->message, 
            error => 'Cannot fetch content: gone or forbidden',
        );
    }

    # if we had some sort of error then check if we've
    # been able to fetch before. if not then lets just
    # unsub. if it looks like a persistant issue unsub too
    if ( $resp->code >= 400 ) {
        unless ( $feed and $feed->last_update() ) {
            feedme::Exception::Fetch::NoFeed->throw(
                feed  => $name,
                code  => $resp->code,
                msg   => $resp->message, 
                error => 'No feed found on initial fetch',
            );
        }

        if ( $feed ) {
            $feed->failed_updates( 
                $feed->failed_updates ?
                    $feed->failed_updates + 1 :
                    1
            );
            $feed->update();
            
            if ( $feed->failed_updates && ( $feed->failed_updates > Dancer::Config::setting('max_not_found') ) ) {
                feedme::Exception::Fetch::MaxNotFound->throw(
                    feed  => $feed->name,
                    code  => $resp->code,
                    msg   => $resp->message, 
                    error => 'Exceeded max not found count',
                );
            }
        }
    }
  
    # content not changed
    return undef if $resp->code == 304;
   
    # something else bad happened
    unless ($resp->is_success) {
        feedme::Exception::Fetch->throw(
            feed  => $name,
            code  => $resp->code,
            msg   => $resp->message,
            error => 'Failed to fetch',
        );
    }
    
    if ( $feed and $feed->failed_updates ) {
        $feed->failed_updates(0);
    }

    if ( $feed ) {
        # this might look like the wrong place to stick this but regardless 
        # of what the content is like there is NO point in fetching a feed
        # again until it changes. Even if the feed can't be parsed that fact
        # won't change until the feed is updated and hence the last-updated
        # and etag headers change
        $feed->headers($resp->headers);

        $feed->update;
    }
    
    my $content = $resp->content;
    if ( wantarray ) {
        return ( $content, $uri );
    }
    return $content;
}

1;
