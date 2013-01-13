package feedme;
use Dancer ':syntax';
use Dancer::Plugin::DBIC 'schema';

set serializer => 'JSON';

our $VERSION = '0.1';

get '/' => sub {
    my $items = [ schema->resultset('Item')->get_unread->all ];
    template 'index' => {
        items => $items
    };
};

post '/viewed' => sub {
    my $id = param "id";
    my $item = schema->resultset('Item')->find( { id => $id } );
    if ( $item ) {
        $item->viewed(1);
        $item->update;
    }

    return { success => 1, id => $id };
};

get '/admin/add' => sub {
    template 'add';
};

post '/admin/add' => sub {
    my $name = param "name";
    my $uri  = param "uri";

    my $feed = schema->resultset('Feed')->find_or_create(
        {
            name => $name,
            uri  => $uri,
        }
    );

    template 'added' => {
        feed => $feed,
    };
};

get '/admin/list' => sub {
    my $feeds = schema->resultset('Feed')->search();
    template 'list' => {
        feeds => $feeds,
    };
};

true;
