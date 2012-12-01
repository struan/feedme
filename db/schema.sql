CREATE TABLE feeds (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    last_update timestamp,
    headers TEXT,
    failed_updates INTEGER,
    uri TEXT,
    should_fetch boolean not null default 't'
);

CREATE TABLE items (
    id SERIAL PRIMARY KEY,
    feed_id INT REFERENCES feeds(id) NOT NULL,
    title TEXT,
    permalink TEXT,
    content TEXT,
    last_update timestamp,
    md5 TEXT,
    diff TEXT,
    viewed BOOLEAN not null default 'f'
);
