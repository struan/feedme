CREATE TABLE feeds (
    id_feed SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    last_update timestamp,
    headers TEXT,
    failed_updates INTEGER,
    uri TEXT,
    should_fetch boolean not null default 't'
);

CREATE TABLE items (
    id_item SERIAL PRIMARY KEY,
    id_feed INT REFERENCES feeds(id_feed) NOT NULL,
    title TEXT,
    permalink TEXT,
    content TEXT,
    last_update timestamp,
    md5 TEXT
);
