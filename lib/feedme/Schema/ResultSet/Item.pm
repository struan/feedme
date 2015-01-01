package feedme::Schema::ResultSet::Item;
use base 'DBIx::Class::ResultSet';

sub get_unread {
    my $self = shift;
    my $feed = shift;

    return $self->_get_items( 0, 0, $feed );
}

sub get_read {
    my $self = shift;
    my $feed = shift;
    my $page = shift;

    return $self->_get_items( 1, $page, 30, $feed );
}

sub _get_items {
    my $self = shift;
    my $viewed = shift;
    my $page = shift;
    my $paged = shift;
    my $feed = shift;

    my $params = { viewed => $viewed  };
    $params->{feed_id} = $feed if $feed;

    my $options = {
        order_by => { -desc => 'last_update' },
        join     => 'feed',
    };
    if ( $paged ) {
        $options->{page} = $page || 1;
        $options->{rows} = $paged;
    }

    return $self->search(
        $params,
        $options
    );
}

1;
