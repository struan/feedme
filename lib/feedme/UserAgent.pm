package feedme::UserAgent;

use strict;
use warnings;
use feedme::Exception;

our @ISA = qw(LWP::UserAgent);

sub new {
    my $self = LWP::UserAgent::new(@_);
    $self->agent("feedme/auth (http://exo.org.uk/)");
    $self;
}

sub get_basic_credentials {
    my ( $self, $realm, $uri ) = @_;
        if ($main::options{'C'}) {
        return split(':', $main::options{'C'}, 2);
    } elsif (-t) {
        my $netloc = $uri->host_port;
        print "Enter username for $realm at $netloc: ";
        my $user = <STDIN>;
        chomp($user);
        return (undef, undef) unless length $user;
        print "Password: ";
        system("stty -echo");
        my $password = <STDIN>;
        system("stty echo");
        print "\n";  # because we disabled echo
        chomp($password);
        return ($user, $password);
    } else {
        return (undef, undef)
    }
}

1;
