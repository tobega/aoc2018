create or replace database a9;
use a9;

create or replace table indata (
  players int not null,
  marbles int not null
);

-- insert into indata values (9, 25);
-- insert into indata values (10, 1618);
insert into indata values (424, 71144);

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

create or replace table result as
with recursive game as (
  select
    1 next_marble,
    marbles,
    1 next_player,
    players,
    circle,
    1 size,
    0 position,
    scores
  from init
union
  select
    next_marble + 1,
    marbles,
    (next_player + 1) % players,
    players,
    case when next_marble % 23 = 0 then
      json_remove(circle, concat('$[', (position + size - 7) % size, ']'))
    else
      json_array_insert(circle, concat('$[', (position + 2) % size, ']'), next_marble)
    end,
    case when next_marble % 23 = 0 then
      size - 1
    else
      size + 1
    end,
    case when next_marble % 23 = 0 then
      (position + size - 7) % size
    else
      (position + 2) % size
    end,
    case when next_marble % 23 = 0 then
      json_replace(scores, concat('$[', next_player, ']'),
        json_value(scores, concat('$[', next_player, ']')) + next_marble +
        json_value(circle, concat('$[', (position + size - 7) % size, ']')))
    else
      scores
    end
  from game where next_marble < marbles
) select players, scores from game order by next_marble desc limit 1;

-- part 1
with recursive s as (
select
  0 player,
  0 score,
  scores,
  players
from result
union
select
  player + 1,
  json_value(scores, concat('$[', (player + 1) % players, ']')),
  scores,
  players
from s where player < players
) select player, score from s order by score desc limit 1;

