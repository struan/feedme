package feedme;
use Dancer2;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::Auth::Tiny;

our $VERSION = '0.1';

get '/login' => sub {
    template 'login' => {};
};

post '/login' => sub {
    if ( _is_valid( params->{username}, params->{password} ) ) {
        session user => params->{username};
        return redirect '/';
    } else {
        template 'login' => {};
    }
};

sub _is_valid {
    my ($username, $password) = @_;

    return 1 if $username eq config->{username} && $password eq config->{password};
}

get '/archive' => needs login => sub {
    my $items = schema->resultset('Item')->get_read;
    my $pager = $items->pager;
    template 'archive' => {
        items => $items,
        page => $pager
    };
};

get '/archive/:page' => needs login => sub {
    my $items = schema->resultset('Item')->get_read(param('page'));
    my $pager = $items->pager;
    template 'archive' => {
        items => $items,
        page => $pager
    };
};

get '/' => needs login => sub {
    my $items = [ schema->resultset('Item')->get_unread()->all ];
    template 'index' => {
        items => $items
    };
};

get '/extras' => needs login => sub {
    template 'extras' => {
        uri_base => request->uri_base
    };
};

get '/d/:id' => needs login => sub {
    my $item = schema->resultset('Item')->find( { id => param('id') } );
    if ( $item ) {
        template 'diff' => {
            item => $item
        };
    }
};

get '/:id' => needs login => sub {
    my $items = [ schema->resultset('Item')->get_unread( param('feed') )->all ];
    template 'index' => {
        items => $items
    };
};

post '/viewed' => needs login => sub {
    my $id = param "id";
    my $item = schema->resultset('Item')->find( { id => $id } );
    if ( $item ) {
        $item->viewed(1);
        $item->update;
    }

    send_as JSON => { success => 1, id => $id };
};

get '/admin/add' => needs login => sub {
    my $uri = param "uri";
    if ( $uri ) {
        my $feed = schema->resultset('Feed')->find_or_create(
            {
                name => '',
                uri  => $uri,
            }
        );

        template 'added' => {
            feed => $feed,
        };
    } else {
        template 'add';
    }
};

post '/admin/add' => needs login => sub {
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

get '/admin/list' => needs login => sub {
    my $feeds = schema->resultset('Feed')->search();
    template 'list' => {
        feeds => $feeds,
    };
};

post '/admin/fetch_on' => needs login => sub {
    my $id = param "id";

    my $feed = schema->resultset('Feed')->find( { id => $id } );
    $feed->update( { should_fetch => 1 } );

    send_as JSON => { success => 1, id => $feed->id };
};

post '/admin/fetch_off' => needs login => sub {
    my $id = param "id";

    my $feed = schema->resultset('Feed')->find( { id => $id } );
    $feed->update( { should_fetch => 0 } );

    send_as JSON => { success => 1, id => $feed->id };
};

true;
