package feedme::Schema::ResultSet::Item;
use base 'DBIx::Class::ResultSet';

sub get_unread {
    my $self = shift;
    my $feed = shift;

    my $params = { viewed => 0 };
    $params->{feed_id} = $feed if $feed;

    return $self->search(
        $params,
        {
            order_by => { -desc => 'last_update' },
            join     => 'feed',
        }
    );
}


1;
