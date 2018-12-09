create or replace database a9;
use a9;

create or replace table indata (
  players int not null,
  marbles int not null
);

insert into indata values (9, 25);

create or replace table seed (
  players int not null,
  marbles int not null,
  circle json,
  scores json
);

insert into seed
select players, marbles, json_array(0), json_array(0) from indata;

create or replace table init as
with recursive a as (
  select
    1 i,
    players,
    marbles,
    circle,
    scores
from seed
union
  select
    i + 1,
    players,
    marbles,
    circle,
    json_array_append(scores, '$', 0)
  from a where i < players
) select players, marbles, circle, scores from a order by i desc limit 1;

with recursive game as (
  select
    0 marble,
    marbles,
    0 player,
    players,
    circle,
    1 size,
    0 position,
    scores
  from init
union
  select
    marble + 1,
    marbles,
    (player % players) + 1,
    players,
    json_array_insert(circle, concat('$[', (position + 1) % size + 1, ']'), marble + 1),
    size + 1,
    (position + 1) % size + 1,
    scores
  from game where marble < marbles
) select * from game;

    
