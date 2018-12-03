create or replace database a3;
use a3;

create or replace table claim_strings (
  claim varchar(50) not null
);

load data local infile '/home/setorgan/aoc2018/a3.txt'
into table claim_strings (claim)
;

create or replace table claims as
select regexp_substr(claim, '#\\K\\d+') id,
  regexp_substr(claim, '#\\d+ @ \\K\\d+') pleft,
  regexp_substr(claim, '#\\d+ @ \\d+,\\K\\d+') ptop,
  regexp_substr(claim, '#\\d+ @ \\d+,\\d+: \\K\\d+') width,
  regexp_substr(claim, '#\\d+ @ \\d+,\\d+: \\d+x\\K\\d+') height
  from claim_strings;

create or replace table squares as
select id, polygon(linestring(point(pleft,ptop), point(pleft + width, ptop),
  point(pleft + width, ptop + height), point(pleft, ptop + height),
  point(pleft, ptop))) square
  from claims;

create or replace table overlaps (
  nr int not null auto_increment,
  sq1 int not null,
  sq2 int not null,
  overlap geometry,
  primary key(nr)
);

insert into overlaps (sq1, sq2, overlap)
select * from
(select s1.id sq1, s2.id sq2, ST_intersection(s1.square, s2.square) overlap
  from squares s1 join squares s2 where s1.id < s2.id
) i where st_area(i.overlap) > 0;

-- part 1
with recursive unions as (
  select nr, overlap from overlaps where nr = 1
union
  select o.nr, ST_union(o.overlap, u.overlap)
  from unions u join overlaps o on o.nr = u.nr + 1
)
select st_area(overlap) from unions order by nr desc limit 1;

-- part 2
select s.id from squares s left join overlaps o on s.id = o.sq1 or s.id = o.sq2 where o.sq1 is null;

drop database a3;

