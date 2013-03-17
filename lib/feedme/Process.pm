package feedme::Process;

use strict;
use warnings;
use Carp;
use Digest::MD5 qw(md5_hex);
use Text::WordDiff;

# we need this for unicode in 5.8+
BEGIN {
    unless ( $] < 5.007 ) {
        require Encode;
        import Encode;
    }
};

sub process_feed {    
    my $items = shift;
    my $feed = shift;
    my $schema = shift;

    foreach my $fetched_item ( @$items ) {
        my $string_to_md5 = $fetched_item->{ 'title' } 
                          . $fetched_item->{ 'content' };
        
        # we do this to stop wide character warnings
        $string_to_md5 = encode('utf8', $string_to_md5) unless $] < 5.007;
        my $md5 = md5_hex( $string_to_md5 );
        $fetched_item->{ 'md5' } = $md5;
        
        my $item = $schema->resultset('Item')->find_or_create( {
                            permalink => $fetched_item->{'permalink'},
                            feed_id   => UNIVERSAL::can( $feed, 'id' ) ? 
                                            $feed->id 
                                            : 0,
                                        } );

        if ( $item->content ) {   # we've seen this before
            # skip if it's not changed
            next unless $md5 ne $item->md5;

            # has it changed in any significant way though?
            my $diff;
            if ( $fetched_item->{'content'} and 
                 $diff = diff_text( $fetched_item->{'content'},
                                       $item->content ) ) 
            {
                $item->content( $fetched_item->{'content'} );
                $item->title( $fetched_item->{'title'} );
                $item->last_update( $fetched_item->{'date'} || \'current_timestamp' );
                $item->link( $fetched_item->{'link'} );
                $item->permalink( $fetched_item->{'permalink'} );
                # $item->author( $fetched_item->{'author'} );
                $item->diff( $diff );
                $item->md5( $md5 );
                $item->viewed( 0 );
            }
        } else {            # more than one item with that permalink
            $item->content( $fetched_item->{'content'} );
            $item->title( $fetched_item->{'title'} );
            $item->last_update( $fetched_item->{'date'} || \'current_timestamp' );
            $item->link( $fetched_item->{'link'} );
            $item->permalink( $fetched_item->{'permalink'} );
            # $item->author( $fetched_item->{'author'} );
            $item->md5( $md5 );
        }

        $item->update;
    }

    $feed->update( { last_update => \'current_timestamp' } ) if @$items;
}

sub diff_text {
    my $new = shift;
    my $orig = shift;

    # sqlite, i assume, doesn't keep the utf8 flag
    unless ( $] < 5.007 ) {
        $orig = decode( 'utf8', $orig )
            unless Encode::is_utf8( $orig );
    }

    # Text::Diff doesn't add a newline so you can get the lines in
    # the diff running together...
    $new .= "\n" unless $new =~ /\n$/s;
    $orig .= "\n" unless $orig =~ /\n$/s;
    
    my $diff = word_diff( \$orig, \$new, { STYLE => 'HTML' } );

    return $diff;
}

1;
