create or replace database a2;
use a2;

create or replace table tags (
  id int not null auto_increment,
  tag varchar(50) not null,
  primary key (id)
);

load data local infile '/home/setorgan/aoc2018/a2.txt'
into table tags (tag)
;

create or replace table tag_letters as
with recursive letters as (
  select id, 0 as position, 'x' as letter, tag as rest
  from tags
union
  select id, position+1, left(rest,1), substring(rest,2)
  from letters where length(rest) > 0
)
select id, position, letter from letters where position > 0;

create or replace table counts as
  select id, letter, count(*) reps
  from tag_letters
  group by id, letter
;

with uc as (
  select distinct id, reps from counts
)
select (select count(*) from uc where reps = 2) * (select count(*) from uc where reps = 3)
;

create or replace table commons as
with diffs as (
select t1.id id1, t2.id id2, t1.position, t1.letter letter1, t2.letter letter2,
  case when t1.letter = t2.letter then 1 end hit
  from tag_letters t1 join tag_letters t2 on t1.position = t2.position and t1.id < t2.id
)
select id1, id2, group_concat(letter1 order by position separator '') common
from diffs
where hit is not null
group by id1, id2
order by position;

select * from commons c join tags t on c.id1 = t.id and length(t.tag) - length(c.common) = 1;

drop database a2;

