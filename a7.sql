create or replace database a7;
use a7;

create or replace table deps (
  pre char(1) not null,
  post char(1) not null
);

load data local infile '/home/setorgan/aoc2018/a7.txt'
into table deps
(@line)
set pre = regexp_substr(@line, '^Step \\K.'),
    post = regexp_substr(@line, 'before step \\K.')
;

-- severe black magic ordering by task everywhere to hope we get alphabetical order in @a
create or replace table tasks as
with t as (
  select pre task from deps
union
  select post task from deps
) select distinct(task) task from t order by task;

create or replace table all_posts as
select task, group_concat((case when post is not null then post else '' end) separator '') posts
from tasks left join deps on task = pre
group by task;

-- part 1
with recursive chains as (
 select
   1 level,
   1 counter,
   @l:=0 longest,
   (select space(count(*)) from tasks) chain,
   (select group_concat(task separator '') from tasks) head,
   (select group_concat(post separator '') from deps) tail,
   left(@a:=(select group_concat(task separator '') from tasks order by task),1) a
union
 select distinct
   level + 1,
   case when m is true then
      1 else counter % length(@a) + 1 end,
   @l:=(greatest(@l, length(trim(chain)))),
   case when m is true then 
     trim(concat(chain, task))
     else chain end,
   case when m is true then 
     regexp_replace(head, task, '')
     else head end,
   case when m is true then 
     regexp_replace(tail, concat('(?U)([', posts, '])(?!.*\\1)'), '')
     else tail end,
   case when m is true then
     left(@a,1)
     else substr(@a, counter % length(@a) + 1, 1) end
 from 
   (select level, counter, chain, head, tail, task, posts,
      (task = a) m
      from
      chains join all_posts
      where head like concat('%', task, '%')
         and tail not like concat ('%', task, '%')
-- not perfect, but at least some pruning
         and length(trim(chain)) >= @l
   ) t
) select chain from chains order by level desc limit 1;

