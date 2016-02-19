
/********************************************
ACHILLES Analyses on DEATH table
*********************************************/

-- create raw data table based on DEATH for better performance
-- create table death_raw as
-- select person_id, gender_concept_id, death_type_concept_id, year_of_birth, dyear, dmonth, dday, 
	-- cast(concat_ws('-', cast(dyear as string), lpad(cast(dmonth as string), 2, '0'), lpad(cast(dday as string), 2, '0')) as timestamp) as ddate
-- from 
 -- (
	-- select p.person_id, p.gender_concept_id, op.death_type_concept_id,
	   -- cast(p.YEAR_OF_BIRTH as int) as year_of_birth, 
	   -- cast(regexp_extract(death_date, '/(\\d+)$', 1) as int) as dyear,
	   -- cast(regexp_extract(death_date, '^(\\d+)/', 1) as int) as dmonth,
	   -- cast(regexp_extract(death_date, '/(\\d+)/', 1) as int) as dday
	-- from PERSON p join death op on p.person_id = op.person_id
 -- ) t
-- ;

-- 500   Number of persons with death, by cause_concept_id
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 500 as analysis_id, 
   cast(d1.cause_concept_id as string) as stratum_1,
   count(distinct d1.PERSON_ID) as count_value
from death d1
group by d1.cause_concept_id
;


-- 501   Number of records of death, by cause_concept_id
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 501 as analysis_id, 
   cast(d1.cause_concept_id as string) as stratum_1,
   count(d1.PERSON_ID) as count_value
from death d1
group by d1.cause_concept_id
;


-- 502   Number of persons by condition occurrence start month
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 502 as analysis_id,   
   cast(year(cast(death_date as timestamp))*100 + month(cast(death_date as timestamp)) as string) as stratum_1, 
   count(distinct PERSON_ID) as count_value
from death d1
group by year(cast(death_date as timestamp))*100 + month(cast(death_date as timestamp))
;


-- 504   Number of persons with a death, by calendar year by gender by age decile
insert into ACHILLES_results (analysis_id, stratum_1, stratum_2, stratum_3, count_value)
select 504 as analysis_id,   
   cast(year(cast(d1.death_date as timestamp)) as string) as stratum_1,
   cast(p1.gender_concept_id as string) as stratum_2,
   cast(floor((year(cast(d1.death_date as timestamp)) - p1.year_of_birth)/10) as string) as stratum_3, 
   count(distinct p1.PERSON_ID) as count_value
from PERSON p1
	inner join death d1
		on p1.person_id = d1.person_id
group by year(cast(d1.death_date as timestamp)), 
	p1.gender_concept_id, 
	floor((year(cast(d1.death_date as timestamp)) - p1.year_of_birth)/10)
;


-- 505   Number of death records, by death_type_concept_id
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 505 as analysis_id, 
   cast(death_type_concept_id as string) as stratum_1,
   count(PERSON_ID) as count_value
from death d1
group by death_type_concept_id
;


-- 506   Distribution of age by condition_concept_id
insert into ACHILLES_results_dist (analysis_id, stratum_1, count_value, min_value, max_value, avg_value, stdev_value, median_value, p10_value, p25_value, p75_value, p90_value)
with rawData as
(
  select gender_concept_id as stratum_id, 
	death_year - year_of_birth as count_value
  from PERSON p1
	inner join
	( select person_id, min(year(cast(death_date as timestamp))) as death_year
	  from death
	  group by person_id 
    ) d1 on p1.person_id = d1.person_id
),
overallStats as
(
  select stratum_id,
    avg(1.0 * count_value) as avg_value,
    stddev(count_value) as stdev_value,
    min(count_value) as min_value,
    max(count_value) as max_value,
    count(*) as total
  from rawData
  group by stratum_id
),
status  as
(
  select stratum_id, count_value, count(*) as total, row_number() over (order by count_value) as rn
  from rawData
  group by stratum_id, count_value
),
priorStats as
(
  select s.stratum_id, s.count_value, s.total, sum(p.total) as accumulated
  from status  s
  join status  p on s.stratum_id = p.stratum_id and p.rn <= s.rn
  group by s.stratum_id, s.count_value, s.total, s.rn
)
select 506 as analysis_id,
  cast(o.stratum_id as string),
  o.total as count_value,
  o.min_value,
  o.max_value,
  cast(o.avg_value as float),
  cast(o.stdev_value as float),
  min(case when p.accumulated >= .50 * o.total then count_value else o.max_value end) as median_value,
  min(case when p.accumulated >= .10 * o.total then count_value else o.max_value end) as p10_value,
  min(case when p.accumulated >= .25 * o.total then count_value else o.max_value end) as p25_value,
  min(case when p.accumulated >= .75 * o.total then count_value else o.max_value end) as p75_value,
  min(case when p.accumulated >= .90 * o.total then count_value else o.max_value end) as p90_value
from priorStats p
join overallStats o on p.stratum_id = o.stratum_id
group by o.stratum_id, o.total, o.min_value, o.max_value, o.avg_value, o.stdev_value
;


-- 509   Number of death records with invalid person_id
insert into ACHILLES_results (analysis_id, count_value)
select 509 as analysis_id, 
   count(d1.PERSON_ID) as count_value
from death d1
   left join person p1 on d1.person_id = p1.person_id
where p1.person_id is null
;


-- 510   Number of death records outside valid observation period
insert into ACHILLES_results (analysis_id, count_value)
select 510 as analysis_id, 
   count(d1.PERSON_ID) as count_value
from death d1
	left join observation_period op1
		on d1.person_id = op1.person_id
			and cast(d1.death_date as timestamp) >= cast(op1.observation_period_start_date as timestamp)
			and cast(d1.death_date as timestamp) <= cast(op1.observation_period_end_date as timestamp)
where op1.person_id is null
;


-- 511   Distribution of time from death to last condition
insert into ACHILLES_results_dist (analysis_id, count_value, min_value, max_value, avg_value, stdev_value, median_value, p10_value, p25_value, p75_value, p90_value)
select 511 as analysis_id,
   count(count_value) as count_value,
   min(count_value) as min_value,
   max(count_value) as max_value,
   cast(avg(1.0*count_value) as float) as avg_value,
   cast(stddev(count_value) as float) as stdev_value,
   max(case when p1<=0.50 then count_value else -9999 end) as median_value,
   max(case when p1<=0.10 then count_value else -9999 end) as p10_value,
   max(case when p1<=0.25 then count_value else -9999 end) as p25_value,
   max(case when p1<=0.75 then count_value else -9999 end) as p75_value,
   max(case when p1<=0.90 then count_value else -9999 end) as p90_value
from
(
	select datediff(t0.max_date, cast(d1.death_date as timestamp)) as count_value,
		1.0*(row_number() over (order by datediff(t0.max_date, cast(d1.death_date as timestamp))))/(count(*) over () + 1) as p1
	from death d1
		inner join
		(
			select person_id, max(cast(condition_start_date as timestamp)) as max_date
			from condition_occurrence
			group by person_id
		) t0 on d1.person_id = t0.person_id
) t1
;


-- 512   Distribution of time from death to last drug
insert into ACHILLES_results_dist (analysis_id, count_value, min_value, max_value, avg_value, stdev_value, median_value, p10_value, p25_value, p75_value, p90_value)
with rawData as
(
  select datediff(t0.max_date, cast(d1.death_date as timestamp)) as count_value
  from death d1
    inner join
    (
	   select person_id, max(cast(drug_exposure_start_date as timestamp)) as max_date
	   from drug_exposure
	   group by person_id
    ) t0
    on d1.person_id = t0.person_id
),
overallStats as
(
  select avg(1.0 * count_value) as avg_value,
    stddev(count_value) as stdev_value,
    min(count_value) as min_value,
    max(count_value) as max_value,
    count(*) as total
  from rawData
),
status  as
(
  select count_value, 
      count(*) as total, 
      row_number() over (order by count_value) as rn
  from rawData
  group by count_value
),
priorStats as
(
  select s.count_value, s.total, sum(p.total) as accumulated
  from status  s
  join status  p on p.rn <= s.rn
  group by s.count_value, s.total, s.rn
)
select 512 as analysis_id,
  o.total as count_value,
  o.min_value,
  o.max_value,
  cast(o.avg_value as float),
  cast(o.stdev_value as float),
  min(case when p.accumulated >= .50 * o.total then count_value else o.max_value end) as median_value,
  min(case when p.accumulated >= .10 * o.total then count_value else o.max_value end) as p10_value,
  min(case when p.accumulated >= .25 * o.total then count_value else o.max_value end) as p25_value,
  min(case when p.accumulated >= .75 * o.total then count_value else o.max_value end) as p75_value,
  min(case when p.accumulated >= .90 * o.total then count_value else o.max_value end) as p90_value
from priorStats p
cross join overallStats o
group by o.total, o.min_value, o.max_value, o.avg_value, o.stdev_value
;


-- 513   Distribution of time from death to last visit
insert into ACHILLES_results_dist (analysis_id, count_value, min_value, max_value, avg_value, stdev_value, median_value, p10_value, p25_value, p75_value, p90_value)
with rawData as
(
  select datediff(t0.max_date, cast(d1.death_date as timestamp)) as count_value
  from death d1
   inner join
   (
      select person_id, max(visit_start_date) as max_date
      from visit_occurrence
      group by person_id
   ) t0 on d1.person_id = t0.person_id
),
overallStats as
(
  select avg(1.0 * count_value) as avg_value,
    stddev(count_value) as stdev_value,
    min(count_value) as min_value,
    max(count_value) as max_value,
    count(*) as total
  from rawData
),
status  as
(
  select count_value, 
      count(*) as total, 
      row_number() over (order by count_value) as rn
  from rawData
  group by count_value
),
priorStats as
(
  select s.count_value, s.total, sum(p.total) as accumulated
  from status  s
  join status  p on p.rn <= s.rn
  group by s.count_value, s.total, s.rn
)
select 513 as analysis_id,
  o.total as count_value,
  o.min_value,
  o.max_value,
  cast(o.avg_value as float),
  cast(o.stdev_value as float),
  min(case when p.accumulated >= .50 * o.total then count_value else o.max_value end) as median_value,
  min(case when p.accumulated >= .10 * o.total then count_value else o.max_value end) as p10_value,
  min(case when p.accumulated >= .25 * o.total then count_value else o.max_value end) as p25_value,
  min(case when p.accumulated >= .75 * o.total then count_value else o.max_value end) as p75_value,
  min(case when p.accumulated >= .90 * o.total then count_value else o.max_value end) as p90_value
from priorStats p
cross join overallStats o
group by o.total, o.min_value, o.max_value, o.avg_value, o.stdev_value
;


-- 514   Distribution of time from death to last procedure
insert into ACHILLES_results_dist (analysis_id, count_value, min_value, max_value, avg_value, stdev_value, median_value, p10_value, p25_value, p75_value, p90_value)
with rawData as
(
  select datediff(t0.max_date, cast(d1.death_date as timestamp)) as count_value
  from death d1
   inner join
   (
      select person_id, max(cast(procedure_date as timestamp)) as max_date
      from procedure_occurrence
      group by person_id
   ) t0 on d1.person_id = t0.person_id
),
overallStats as
(
  select avg(1.0 * count_value) as avg_value,
    stddev(count_value) as stdev_value,
    min(count_value) as min_value,
    max(count_value) as max_value,
    count(*) as total
  from rawData
),
status  as
(
  select count_value, 
      count(*) as total, 
      row_number() over (order by count_value) as rn
  from rawData
  group by count_value
),
priorStats as
(
  select s.count_value, s.total, sum(p.total) as accumulated
  from status  s
  join status  p on p.rn <= s.rn
  group by s.count_value, s.total, s.rn
)
select 514 as analysis_id,
  o.total as count_value,
  o.min_value,
  o.max_value,
  cast(o.avg_value as float),
  cast(o.stdev_value as float),
  min(case when p.accumulated >= .50 * o.total then count_value else o.max_value end) as median_value,
  min(case when p.accumulated >= .10 * o.total then count_value else o.max_value end) as p10_value,
  min(case when p.accumulated >= .25 * o.total then count_value else o.max_value end) as p25_value,
  min(case when p.accumulated >= .75 * o.total then count_value else o.max_value end) as p75_value,
  min(case when p.accumulated >= .90 * o.total then count_value else o.max_value end) as p90_value
from priorStats p
cross join overallStats o
group by o.total, o.min_value, o.max_value, o.avg_value, o.stdev_value
;


-- 515   Distribution of time from death to last observation
insert into ACHILLES_results_dist (analysis_id, count_value, min_value, max_value, avg_value, stdev_value, median_value, p10_value, p25_value, p75_value, p90_value)
with rawData as
(
  select datediff(t0.max_date, cast(d1.death_date as timestamp)) as count_value
  from death d1
   inner join
   (
      select person_id, max(cast(observation_date as timestamp)) as max_date
      from observation
      group by person_id
   ) t0 on d1.person_id = t0.person_id
),
overallStats as
(
  select avg(1.0 * count_value) as avg_value,
    stddev(count_value) as stdev_value,
    min(count_value) as min_value,
    max(count_value) as max_value,
    count(*) as total
  from rawData
),
status  as
(
  select count_value, 
      count(*) as total, 
      row_number() over (order by count_value) as rn
  from rawData
  group by count_value
),
priorStats as
(
  select s.count_value, s.total, sum(p.total) as accumulated
  from status  s
  join status  p on p.rn <= s.rn
  group by s.count_value, s.total, s.rn
)
select 515 as analysis_id,
  o.total as count_value,
  o.min_value,
  o.max_value,
  cast(o.avg_value as float),
  cast(o.stdev_value as float),
  min(case when p.accumulated >= .50 * o.total then count_value else o.max_value end) as median_value,
  min(case when p.accumulated >= .10 * o.total then count_value else o.max_value end) as p10_value,
  min(case when p.accumulated >= .25 * o.total then count_value else o.max_value end) as p25_value,
  min(case when p.accumulated >= .75 * o.total then count_value else o.max_value end) as p75_value,
  min(case when p.accumulated >= .90 * o.total then count_value else o.max_value end) as p90_value
from priorStats p
cross join overallStats o
group by o.total, o.min_value, o.max_value, o.avg_value, o.stdev_value
;

exit;
