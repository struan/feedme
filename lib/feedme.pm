package feedme;
use Dancer ':syntax';
use Dancer::Plugin::DBIC 'schema';

our $VERSION = '0.1';

get '/' => sub {
    my $items = [ schema->resultset('Item')->search(undef, { order_by => { -desc => 'last_update' }, join => 'feed' } )->all ];
    template 'index' => {
        items => $items
    };
};

true;
