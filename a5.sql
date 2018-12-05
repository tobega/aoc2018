create or replace database a5;
use a5;

create or replace table polymers (
  polymer text not null
);

load data local infile '/home/setorgan/aoc2018/a5.txt'
into table polymers
;

with recursive reduction as (
select polymer from polymers
union
select regexp_replace(polymer, '(?i)([a-z])(?-i)(?!\\1)(?i)\\1', '')
from reduction
) select length(polymer) from reduction order by length(polymer) limit 1;

create table units (
  unit char(1)
);

insert into units values
('a'), ('b'),('c'),('d'),('e'),('f'),('g'),('h'),('i'),('j'),('k'),
('l'),('m'),('n'),('o'),('p'),('q'),('r'),('s'),('t'),('u'),('v'),
('w'),('x'),('y'),('z');

create table modifieds as
select u.unit, regexp_replace(p.polymer, concat('(?i)', u.unit), '') polymer
from units u join polymers p;

with recursive reduction as (
select unit, polymer from modifieds
union
select unit, regexp_replace(polymer, '(?i)([a-z])(?-i)(?!\\1)(?i)\\1', '')
from reduction
) select unit, length(polymer) from reduction order by length(polymer) limit 1;

drop database a5;

