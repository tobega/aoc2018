create or replace database a6;
use a6;

create or replace table coords (
  id int not null auto_increment,
  x int,
  y int,
  primary key(id)
);

load data local infile '/home/setorgan/aoc2018/a6.txt'
into table coords
fields terminated by ', '
(x, y)
;

create or replace table bounding_box as
select min(x) l, min(y) t, max(x) r, max(y) b
from coords;

create or replace table xs as
with recursive c as (
 select l x from bounding_box
union
 select x + 1 from c join bounding_box b on c.x < b.r
) 
select * from c;

create or replace table ys as
with recursive r as (
 select t y from bounding_box
union
 select y + 1 from r join bounding_box b on r.y < b.b
) 
select * from r;

create or replace table dists as
with box as (
  select x, y from xs, ys
)
select b.x, b.y, c.id coord, (abs(b.x - c.x) + abs(b.y - c.y)) dist
 from box b join coords c;

create or replace table closest as
select x, y, coord from
(with min_dists as (
  select x,y, min(dist) md from dists group by x,y
) select d.x, d.y, d.coord, (count(*) > 1) is_shared from dists d join min_dists m
 on d.dist = m.md and d.x = m.x and d.y = m.y
 group by d.x,d.y
) t where not is_shared;

create or replace table infinites as
select distinct(coord) coord from closest c
join bounding_box b on c.x = b.l or c.x = b.r or c.y = b.t or c.y = b.b;

-- part 1
with areas as (
  select c.coord, count(*) size from closest c
  left join infinites i on c.coord = i.coord
  where i.coord is null
  group by c.coord
) select max(size) from areas;

-- part 2
with tightness as (
  select x, y, sum(dist) tightness from dists
  group by x,y
)
select count(*) from tightness where tightness < 10000;

drop database a6;

