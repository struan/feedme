package feedme;
use Dancer ':syntax';
use Dancer::Plugin::DBIC 'schema';

our $VERSION = '0.1';

get '/' => sub {
    my $items = [ schema->resultset('Item')->search(undef, { join => 'id_feed' } )->all ];
    template 'index' => {
        items => $items
    };
};

true;
