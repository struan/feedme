package feedme::Parse;

use strict;
use warnings;
use XML::Feed;
use HTML::ResolveLink;
use List::Util qw( first );
use Carp;

use feedme::Util;

# we need this for unicode in 5.8+
BEGIN {
    unless ( $] < 5.007 ) {
        require Encode;
        import Encode;
    }
};

# this is all basically to get round the less than optimal unicode 
# processing in perl 5.6. it means we loose some content but that things
# don't blow up in our face. it is less than optimal :(
# it also gets round some issue XML::RSS has with weird windows chars
sub clean_rss {
    my $rss = shift;
    # quick bad feed cleanup hack
    # should weed out worst of problems with ctrl chars and the like
    if ( $] < 5.007 ) {
        $rss =~ s/[^[:ascii:]]+/ /g; # assumes not using too many unicode chars
        $rss =~ s/[^[:graph:][:blank:]\n]+/ /g;
    }
    $rss =~ s/ & / &amp; /g;      # 'cause some people still can't encode...

    # some XML::RSS versions don't seem to like windows encoding maps...
    # god alone knows what happens if there are any windows encoded
    # characters in there. 
    #if ($XML::RSS::VERSION < 2.32 ) {
    #    $rss =~ s#encoding="windows[^"]*"#encoding="iso-8859-1"#;
    #}

    # 'cause Joel on Software has bogus dates and DateTime::Format::Mail
    # seems to ignore the day ;) this is, of course, hacky
    #$rss =~ s#<pubDate>(?=\d)#<pubDate>Mon, #g;
    #$rss =~ s#EST</pubDate>#-0500</pubDate>#g;
    return $rss;
}

# THIS NEEDS SOME WORK!
sub parse_rss {
    my %args = @_;

    my $failed_parse = 0;
    my $parse_count = 0;
    my $parser; # = XML::Feed->new();
    PARSE:
    eval {
        # local $^W = 0; # XML::RSS spews warnings on some rss files :(
        if ( exists( $args{file} ) ) {
            $parser = XML::Feed->parse( $args{file}) 
                or die XML::Feed->errstr;
        } else {
            $parser = XML::Feed->parse( \$args{string} )
                or die XML::Feed->errstr;
        }
    };
    if ($@) {
        # sometimes things fail to parse if we have unicode in them 
        # but they're not properly encoded so we try this to see if
        # it helps. if not then spit out the original error
        unless ( $failed_parse and $] < 5.007 ) {
            $args{ string } = encode( 'utf8', $args{ string } );
            $failed_parse = $@;
            if ( Dancer::Config::setting('DEBUG') > 1 ) {
                warn "DEBUG: reparsing\n";
                warn "DEBUG: original error: $@\n";
            }
            $parse_count++;
            goto PARSE if $parse_count < 2;
        }
        feedme::Exception::Parse->throw( 
            feed => $args{feed_name},
            error => ( $failed_parse or $@ )
        );
    }

    if ( $args{ title_only } ) {
        return $parser->title;
    }

    unless ( $args{feed}->name ) {
        $args{feed}->name( $parser->title );
        $args{feed}->update;
    }

    my @feed;
    foreach my $item ( $parser->entries ) {
        my $desc = $item->content->body || '[no content]';
        unless ( $] < 5.007 ) {
            $desc = decode( 'utf8', $desc ) 
                unless Encode::is_utf8( $desc );
        }

        my $title = $item->title
                  || '[no title]';
        $title =~s/\n//g;
        unless ( $] < 5.007 ) {
            $title = decode( 'utf8', $title )
                unless Encode::is_utf8( $title );
        }

        my $date = '';
        eval {
            $date = $item->issued->dmy . ' ' . $item->issued->hms
                if $item->issued; 
        };
        if ($@) {
            feedme::Exception::Parse->throw(
                feed => $args{feed_name},
                error => $@
            );
        }

        my $permalink = $item->id;

        my $author = $item->author 
                     || '';

        my $link = $item->link;

        # this is to deal with a mixture of issues with the way
        # XML::Feed seems to work things out and Sam Ruby's
        # atom feed being too clever by half. It's all very
        # heuristicy
        if ( not $link or $link !~ /^https?:/ ) {
            $link = $item->id;
            if ( not $link or $link !~ /^https?:/ ) {
                warn "DEBUG: no http in link or id, trying extreme measures\n"
                    if ( Dancer::Config::setting('DEBUG') > 2 );
                # XML::Feed only looks for links with rel eq 'alternate'
                # but the atom spec tells us that if there's no rel then
                # we can assume it meant alternate
                # this is fixed in recent versions of XML::Feed
                $link = undef;
                if ( $item->{entry} and UNIVERSAL::can( $item->{entry}, 'link' ) ) {
                    $link = first { not $_->rel } $item->{entry}->link;
                } elsif ( $item->{entry} and $item->{entry}->{link} ne "") {
                    $link = $item->{entry}->{link};
                }

                if ( $link and UNIVERSAL::can( $link, 'href' ) ) {
                    $link = $link->href;
                }
            }
            # sometime we need to use the base URI in combination 
            # with the link to get an absolute URI...
            if ( not $link or $link !~ /^https?:/ ) {
                warn "DEBUG: still no http in link or id, useing _uri_to_abs on
                      $link and " . $parser->link . "\n"
                    if ( Dancer::Config::setting('DEBUG') > 2 );
                my $base = $parser->link;
                $base = $args{feed_uri} if $base eq '.' or $base !~ /^https?:/;
                $link = feedme::Util::uri_to_abs($link, $base);    
            }
        }

        my $resolver = HTML::ResolveLink->new(
            base => $link,
        );
        
        $desc = $resolver->resolve( $desc );
        
        push @feed, { 
                      author => $author,
                      content => $desc, 
                      title => $title, 
                      date => $date, 
                      permalink => $permalink,
                      link => $link || '[no link]',
                    };
    }

    return \@feed;
}

1;
