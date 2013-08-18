begin;

  create extension "uuid-ossp";

  create table items (
    id uuid primary key default uuid_generate_v4(),
    title text,
    uri text,
    post text,
    created timestamp not null default now(),
    updated timestamp not null default now(),
    creator text not null,
    parent uuid references items(id),
    child_count int not null default 0
  );

  create index on items (created desc);
  create index on items (updated desc);
  create index on items (parent);

commit;
