create or replace database a7;
use a7;

create or replace table deps (
  pre char(1) not null,
  post char(1) not null
);

load data local infile '/home/setorgan/aoc2018/a7test.txt'
into table deps
(@line)
set pre = regexp_substr(@line, '^Step \\K.'),
    post = regexp_substr(@line, 'before step \\K.')
;

create or replace table tasks as
with t as (
  select pre task from deps
union
  select post task from deps
) select distinct(task) task from t;

create or replace table all_posts as
select task, group_concat((case when post is not null then post else '' end) separator '') posts
from tasks left join deps on task = pre
group by task;

-- part 1
with recursive chains as (
 select
   1 level,
   (select group_concat(task separator '') from tasks) chain,
   (select group_concat(task separator '') from tasks) head,
   (select group_concat(post separator '') from deps) tail
union
 select distinct
   level + 1,
   concat(regexp_replace(chain, task, ''), task) chain,
   regexp_replace(head, task, '') head,
   regexp_replace(tail, concat('(?U)([', posts, '])(?!.*\\1)'), '') tail
 from chains join all_posts
      on head like concat('%', task, '%')
      and (length(tail) = 0 or tail regexp concat ('(?U).*[', posts, '].*'))
      and tail not like concat ('%', task, '%')
) select chain from chains
order by level desc, chain asc limit 1;




