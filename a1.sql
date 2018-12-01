create or replace database a1;
use a1;

create or replace table a1 (
  id int not null auto_increment,
  frequency_change int not null,
  primary key (id)
);

load data local infile '/home/setorgan/aoc2018/a1.txt'
into table a1 (frequency_change)
;

select sum(frequency_change) from a1;

create or replace table a1_running as
  SELECT id,
         frequency_change,
         @running_total := @running_total + frequency_change AS cumulative_sum,
         @position := @position + 1 as position
    FROM a1
         JOIN (SELECT @running_total := 0, @position := 0) r
;

create or replace table a1_possible as
with recursive repeateds as (
  select cumulative_sum,
  position
  from a1_running
union
  select t.cumulative_sum + @lsum,
  t.position + @lpos
  from repeateds t
  join (select @lsum := (select cumulative_sum from a1_running order by position desc limit 1),
    @lpos := (select position from a1_running order by position desc limit 1),
    @lmax := (select max(cumulative_sum) from a1_running),
    @lmin := (select min(cumulative_sum) from a1_running)
  ) r
   where (t.cumulative_sum < @lmax and @lsum > 0) or (t.cumulative_sum > @lmin and @lsum < 0)
)
select position,
 cumulative_sum,
 count(*) over (partition by cumulative_sum order by position rows unbounded preceding) repeats
 from repeateds order by position
;

select cumulative_sum
from a1_possible where repeats = 2 order by position limit 1;

drop database a1;

