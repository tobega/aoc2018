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
select guard,
 time_to_sec(timediff(time(fell_asleep), '00:00:00'))/60 fell_asleep,
 time_to_sec(timediff(time(woke), '00:00:00'))/60 woke,
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

create or replace table sleep_minutes
with recursive ms as (
  select guard, fell_asleep asleep, fell_asleep + 1 rest, woke
  from naps where fell_asleep < woke
union all
  select guard, rest, rest + 1, woke
  from ms where rest < woke
)
select guard, asleep from ms;

create or replace table sleep_patterns as
select guard, asleep, count(*) occasions from sleep_minutes
group by asleep, guard;

-- part 1
select (guard * asleep) from sleep_patterns
where guard = (select guard from (
  select guard, sum(nap_minutes) total from naps group by guard) t
  order by total desc limit 1)
order by occasions desc limit 1;

-- part 2
select (guard * asleep) from sleep_patterns
order by occasions desc limit 1;

drop database a4;

