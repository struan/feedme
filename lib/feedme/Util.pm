package feedme::Util;

use strict;
use warnings;
use feedme::Exception;
use XML::Feed;
use Carp;
use File::Path;
use Fcntl qw( :flock :seek );
use File::Spec::Functions qw(rel2abs splitpath);

# stolen from LWP::UserAgent::request()
sub uri_to_abs {
    my $uri = shift;
    my $base = shift;
    local $URI::ABS_ALLOW_RELATIVE_SCHEME = 1;
    return $HTTP::URI_CLASS->new($uri, $base)                                 
        ->abs($base);
}

# quick wrapper for RSS autodiscovery
sub autodiscover {
    my $uri = shift;

    warn "DEBUG: Attempting autodiscovery at $uri\n" if Dancer::Config::setting('DEBUG');
   
    my @links = XML::Feed->find_feeds( $uri );

    if ( Dancer::Config::setting('DUMPER') ) {
        warn "DEBUG: autodiscovery found:\n" if Dancer::Config::setting('DEBUG') > 1;
        warn Dumper( \@links ) if Dancer::Config::setting('DEBUG') > 1;
    }
   
    # just return the first link
    if ( @links ) {
        return $links[0];
    } else {
        feedme::Exception::Autodiscover->throw(
            uri => $uri,
        );
    }
}

sub save_content {
    my ($dir, $target, $content) = @_;
    return undef unless $content;
    _write_to_file("$dir/$target.rss", $content, $target) or return undef;
    return "$dir/$target.rss";
}

sub _write_to_file {
    my $file = shift;
    my $string = shift;
    my $feed_name = shift;
    
    return undef unless $file;
    return undef unless $string;

    $file = rel2abs($file);

    my $dir = (splitpath($file))[1];
    mkpath $dir unless -e $dir;
    
    open FILE, ">", "$file" 
        or do {
            my $_file_err = "Failed to write to [$file] - $!";
            feedme::Exception->throw(
                feed => $feed_name,
                error => $_file_err
            );
        };
    flock FILE, LOCK_EX;
    seek FILE, 0, SEEK_SET;
    # binmode FILE, "utf8" if $] > 5.007; 
    print FILE $string;
    close FILE;
   
    return 1;
}

1;
