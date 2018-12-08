create or replace database a8;
use a8;

create or replace table nums (
  pos int not null,
  val int not null
);

create sequence s;

load data local infile '/home/setorgan/aoc2018/a8.txt'
into table nums
lines terminated by ' '
(@i)
set pos = nextval(s),
    val = @i
;

create or replace table seed_table (
  str varchar(5000)
);
insert into seed_table (str) values ('');

alter sequence s restart 1;

create or replace table nodes (
  id int not null,
  parent int not null,
  metadata varchar(2000) not null
);

insert into nodes
with recursive parser as (
select
  1 next,
  'c' mode,
  0 id,
  0 parent,
  str metadata,
  0 cc,
  0 cm,
  concat(',0,0', str) qey,
  concat(',0,0', str) ccs,
  concat(',0,0', str) cms
from seed_table
union
select
  case when mode = 'e' or (mode = 'v' and cm = 0) -- >end element
    then next
    else next + 1
  end,
  case when mode = 'c'
    then 'm'
    when (mode = 'm' or mode = 'e') and cc > 0 -- >next child
    then 'c'
    when (mode = 'm' or mode = 'e') and cc = 0 -- >read values
    then 'v'
    when mode = 'v' and cm = 0 -- >end element
    then 'e'
    when mode = 'e' and cc < 0 -- edge case no children no metadata
    then 'c'
    else mode
  end,
  case when (mode = 'm' or mode = 'e')
    then cast(regexp_substr(qey, ',\\K\\d+\\z') as integer)
    when mode = 'v' and cm = 0 -- >end element
    then cast(regexp_substr(regexp_replace(qey, ',\\d+\\z', ''), ',\\K\\d+\\z') as integer)
    else id
  end,
  case when mode = 'c'
    then regexp_substr(qey, ',\\K\\d+\\z')
    when mode = 'e'
    then regexp_substr(regexp_replace(qey, ',\\d+\\z', ''), ',\\K\\d+\\z')
    else parent
  end,
  case when (mode = 'm' or mode = 'e') and cc = 0
    then ''
    when mode = 'v' and cm > 0
    then concat(metadata,',',val)
    else metadata
  end,
  case when mode = 'v' and cm = 0 -- > end element
    then regexp_substr(regexp_replace(ccs, ',\\d+\\z', ''), ',\\K-?\\d+\\z') - 1
    when mode = 'c'
    then val
    else cc
  end,
  case when mode = 'v' and cm > 0
    then cm - 1
    when mode = 'v' and cm = 0 -- >end element
    then regexp_substr(regexp_replace(cms, ',\\d+\\z', ''), ',-?\\K\\d+\\z')
    when mode = 'm'
    then val
    else cm
  end,
  case when mode = 'c'
    then concat(qey, ',', nextval(s))
    when mode = 'v' and cm = 0 -- >end element
    then regexp_replace(qey, ',\\d+\\z', '')
    else qey
  end,
  case when mode ='c'
    then concat(ccs,',',val)
    when mode = 'v' and cm = 0 -- >end element
    then regexp_replace(ccs, ',-?\\d+\\z', '')
    when mode = 'e'
    then regexp_replace(ccs, ',-?\\d+\\z', concat(',',cc))
    else ccs
  end,
  case when mode = 'm'
    then concat(cms,',',val)
    when mode = 'v' and cm = 0 -- >end element
    then regexp_replace(cms, ',-?\\d+\\z', '')
    else cms
  end
from parser join nums on pos = next
) select distinct
  last_value(id) over w id,
  last_value(parent) over w parent,
  last_value(
     case when length(metadata) > 0 then substr(metadata,2)
     else metadata end
  ) over w metadata
from parser
where id > 0
window w as (partition by id order by next rows between unbounded preceding and unbounded following)
;

-- part 1
with recursive mv as (
select
  1 n,
  cast(regexp_substr(metadata, '\\d+') as unsigned integer) val,
  regexp_replace(metadata, '\\A\\d+,?', '') mm
from nodes
where length(metadata) > 0
union all
select
  n + 1,
  cast(regexp_substr(mm, '\\d+') as unsigned integer) val,
  regexp_replace(mm, '\\A\\d+,?', '') mm
from mv where length(mm) > 0
) select sum(val) from mv;

