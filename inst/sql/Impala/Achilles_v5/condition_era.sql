
/********************************************
  ACHILLES Analyses on CONDITION_ERA table
*********************************************/

-- create raw data table based on CONDITION_ERA for query performance
-- create table condition_era_raw as
-- select person_id, gender_concept_id, condition_concept_id, year_of_birth, syear, smonth, sday, 
	-- cast(concat_ws('-', cast(syear as string), lpad(cast(smonth as string), 2, '0'), lpad(cast(sday as string), 2, '0')) as timestamp) as sdate,
	-- eyear, emonth, eday, 
	-- cast(concat_ws('-', cast(eyear as string), lpad(cast(emonth as string), 2, '0'), lpad(cast(eday as string), 2, '0')) as timestamp) as edate
-- from 
 -- (
	-- select p.person_id, p.gender_concept_id, op.condition_concept_id,
	   -- cast(p.YEAR_OF_BIRTH as int) as year_of_birth, 
	   -- cast(regexp_extract(condition_era_start_date, '/(\\d+)$', 1) as int) as syear,
	   -- cast(regexp_extract(condition_era_start_date, '^(\\d+)/', 1) as int) as smonth,
	   -- cast(regexp_extract(condition_era_start_date, '/(\\d+)/', 1) as int) as sday,
	   -- cast(regexp_extract(condition_era_end_date, '/(\\d+)$', 1) as int) as eyear,
	   -- cast(regexp_extract(condition_era_end_date, '^(\\d+)/', 1) as int) as emonth,
	   -- cast(regexp_extract(condition_era_end_date, '/(\\d+)/', 1) as int) as eday
	-- from PERSON p join condition_era op on p.person_id = op.person_id
 -- ) t
-- ;

-- 1000   Number of persons with at least one condition occurrence, by condition_concept_id
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 1000 as analysis_id, 
   cast(ce1.condition_CONCEPT_ID as string) as stratum_1,
   count(distinct ce1.PERSON_ID) as count_value
from condition_era ce1
group by ce1.condition_CONCEPT_ID
;

-- 1001   Number of condition occurrence records, by condition_concept_id
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 1001 as analysis_id, 
   cast(ce1.condition_CONCEPT_ID as string) as stratum_1,
   count(ce1.PERSON_ID) as count_value
from condition_era ce1
group by ce1.condition_CONCEPT_ID
;

-- 1002   Number of persons by condition occurrence start month, by condition_concept_id
insert into ACHILLES_results (analysis_id, stratum_1, stratum_2, count_value)
select 1002 as analysis_id,   
   cast(ce1.condition_concept_id as string) as stratum_1,
   cast(year(cast(condition_era_start_date as timestamp))*100 + month(cast(condition_era_start_date as timestamp)) as string) as stratum_2, 
   count(distinct PERSON_ID) as count_value
from condition_era ce1
group by ce1.condition_concept_id, year(cast(condition_era_start_date as timestamp))*100 + month(cast(condition_era_start_date as timestamp))
;

-- 1003   Number of distinct condition era concepts per person
insert into ACHILLES_results_dist (analysis_id, count_value, min_value, max_value, avg_value, stdev_value, median_value, p10_value, p25_value, p75_value, p90_value)
with rawData as
(
  select count(distinct ce1.condition_concept_id) as count_value
  from condition_era ce1
  group by ce1.person_id
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
select 1003 as analysis_id,
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

-- 1004   Number of persons with at least one condition occurrence, by condition_concept_id by calendar year by gender by age decile
insert into ACHILLES_results (analysis_id, stratum_1, stratum_2, stratum_3, stratum_4, count_value)
select 1004 as analysis_id,   
   cast(ce1.condition_concept_id as string) as stratum_1,
   cast(year(cast(ce1.condition_era_start_date as timestamp)) as string) as stratum_2,
   cast(p1.gender_concept_id as string) as stratum_3,
   cast(floor((year(cast(ce1.condition_era_start_date as timestamp)) - p1.year_of_birth)/10) as string) as stratum_4, 
   count(distinct p1.PERSON_ID) as count_value
from PERSON p1 
	inner join condition_era ce1 
		on p1.person_id = ce1.person_id
group by ce1.condition_concept_id, 
	year(cast(ce1.condition_era_start_date as timestamp)), 
	p1.gender_concept_id, 
	floor((year(cast(ce1.condition_era_start_date as timestamp)) - p1.year_of_birth)/10)
;

-- 1006   Distribution of age by condition_concept_id
insert into ACHILLES_results_dist (analysis_id, stratum_1, stratum_2, count_value, min_value, max_value, avg_value, stdev_value, median_value, p10_value, p25_value, p75_value, p90_value)
with rawData as
(
	select ce.condition_concept_id as subject_id,
	   p1.gender_concept_id,
	   ce.condition_start_year - p1.year_of_birth as count_value
	from PERSON p1
		inner join
		(
		  select person_id, condition_concept_id, min(year(cast(condition_era_start_date as timestamp))) as condition_start_year
		  from condition_era
		  group by person_id, condition_concept_id
		) ce on p1.person_id = ce.person_id
),
overallStats as
(
  select subject_id as stratum1_id,
    gender_concept_id as stratum2_id,
    avg(1.0 * count_value) as avg_value,
    stddev(count_value) as stdev_value,
    min(count_value) as min_value,
    max(count_value) as max_value,
    count(*) as total
  from rawData
  group by subject_id, gender_concept_id
),
status  as
(
  select subject_id as stratum1_id, gender_concept_id as stratum2_id, count_value, count(*) as total, row_number() over (partition by subject_id, gender_concept_id order by count_value) as rn
  from rawData
  group by subject_id, gender_concept_id, count_value
),
priorStats as
(
  select s.stratum1_id, s.stratum2_id, s.count_value, s.total, sum(p.total) as accumulated
  from status  s
  join status  p on s.stratum1_id = p.stratum1_id and s.stratum2_id = p.stratum2_id and p.rn <= s.rn
  group by s.stratum1_id, s.stratum2_id, s.count_value, s.total, s.rn
)
select 1006 as analysis_id,
  cast(o.stratum1_id as string),
  cast(o.stratum2_id as string),
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
join overallStats o on p.stratum1_id = o.stratum1_id and p.stratum2_id = o.stratum2_id 
group by o.stratum1_id, o.stratum2_id, o.total, o.min_value, o.max_value, o.avg_value, o.stdev_value
;

-- 1007   Distribution of condition era length, by condition_concept_id
insert into ACHILLES_results_dist (analysis_id, stratum_1, count_value, min_value, max_value, avg_value, stdev_value, median_value, p10_value, p25_value, p75_value, p90_value)
with rawData as
(
  select condition_concept_id as stratum1_id, 
	datediff(cast(condition_era_end_date as timestamp), cast(condition_era_start_date as timestamp)) as count_value
  from condition_era
),
overallStats as
(
  select stratum1_id, 
    avg(1.0 * count_value) as avg_value,
    stddev(count_value) as stdev_value,
    min(count_value) as min_value,
    max(count_value) as max_value,
    count(*) as total
  from rawData
  group by stratum1_id
),
status  as
(
  select stratum1_id, 
      count_value, 
      count(*) as total, 
      row_number() over (partition by stratum1_id order by count_value) as rn
  from rawData
  group by stratum1_id, count_value
),
priorStats as
(
  select s.stratum1_id, s.count_value, s.total, sum(p.total) as accumulated
  from status  s
  join status  p on s.stratum1_id = p.stratum1_id and p.rn <= s.rn
  group by s.stratum1_id, s.count_value, s.total, s.rn
)
select 1007 as analysis_id,
  cast(p.stratum1_id as string) as stratum_1,
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
join overallStats o on p.stratum1_id = o.stratum1_id
group by p.stratum1_id, o.total, o.min_value, o.max_value, o.avg_value, o.stdev_value
;

-- 1008   Number of condition eras with invalid person
insert into ACHILLES_results (analysis_id, count_value)
select 1008 as analysis_id,  
   count(ce1.PERSON_ID) as count_value
from
   condition_era ce1
   left join PERSON p1
   on p1.person_id = ce1.person_id
where p1.person_id is null
;

-- 1009   Number of condition eras outside valid observation period
insert into ACHILLES_results (analysis_id, count_value)
select 1009 as analysis_id,  
	count(ce1.PERSON_ID) as count_value
from
	condition_era ce1
	left join observation_period op1
	on op1.person_id = ce1.person_id
	and cast(ce1.condition_era_start_date as timestamp) >= cast(op1.observation_period_start_date as timestamp)
	and cast(ce1.condition_era_start_date as timestamp) <= cast(op1.observation_period_end_date as timestamp)
where op1.person_id is null
;

-- 1010   Number of condition eras with end date < start date
insert into ACHILLES_results (analysis_id, count_value)
select 1010 as analysis_id,
   count(ce1.PERSON_ID) as count_value
from
   condition_era ce1
where cast(ce1.condition_era_end_date as timestamp) < cast(ce1.condition_era_start_date as timestamp)
;

-- 1020   Number of drug era records by drug era start month
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 1020 as analysis_id,
   cast(YEAR(cast(condition_era_start_date as timestamp))*100 + month(cast(condition_era_start_date as timestamp)) as string) as stratum_1,
   count(PERSON_ID) as count_value
from condition_era ce1
group by YEAR(cast(condition_era_start_date as timestamp))*100 + month(cast(condition_era_start_date as timestamp))
;

exit;

