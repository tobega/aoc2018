create or replace database a4;
use a4;

create or replace table raw_entries (
  entry varchar(50) not null
);

load data local infile '/home/setorgan/aoc2018/a4.txt'
into table raw_entries (entry)
;

create or replace table entries (
  time datetime not null,
  note varchar(50) not null
);

insert into entries
select * from (
select regexp_substr(entry, '\\[\\K\\d\\d\\d\\d-\\d\\d-\\d\\d \\d\\d:\\d\\d') time,
  regexp_substr(entry, '.*] \\K.*') note
  from raw_entries
) s order by time
;

-- how safe is it to rely on @g here?
create or replace table naps as
select guard, fell_asleep, woke,
 time_to_sec(timediff(woke, fell_asleep))/60 nap_minutes from (
with t as (
select time, note, regexp_substr(note, 'Guard #\\K\\d+') guard,
  (note = 'falls asleep') is_fall_asleep,
  (note = 'wakes up') is_wake
from entries order by time
) select time, note, is_fall_asleep, is_wake,
  @g:=case when length(guard) = 0 then @g else guard end guard,
  case when is_fall_asleep then time else LAG(time) over (order by time) end fell_asleep,
  case when is_wake then time end woke
from t join (select @g := 0) g order by time
) q where woke is not null;

create sequence i;

create or replace table longest_sleeper as
  select nextval(i) i,
  time_to_sec(timediff(time(fell_asleep), '00:00:00'))/60 sleeping,
  time_to_sec(timediff(time(woke), '00:00:00'))/60 waking,
  occasions, sg.guard
  from naps join
   (select guard, occasions from
     (select guard, sum(nap_minutes) sleepiness, count(*) occasions from naps
      group by guard) s
   order by sleepiness desc limit 1) sg on naps.guard = sg.guard
;

insert into longest_sleeper
select 0, 0, 60, occasions, guard from longest_sleeper where i = 1;

with recursive overlaps as (
  select 1 n, 0 k, 0 i, sleeping, waking, guard from longest_sleeper l
    where i = 0
union
  select (1 + o.n),
  case when l.i > o.i then (1 + o.k) else o.k end,
  greatest(l.i, o.i),
  greatest(l.sleeping, o.sleeping),
  least(l.waking, o.waking),
  l.guard
  from longest_sleeper l join overlaps o on
    l.i <= o.n and o.n <= (select max(i) from longest_sleeper)
  where l.sleeping >= o.sleeping and l.sleeping < o.waking or o.sleeping >= l.sleeping and o.sleeping < l.waking
)
select  (guard * sleeping) from overlaps
order by k desc limit 1;

