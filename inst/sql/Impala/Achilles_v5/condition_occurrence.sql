
/**********************************************************
ACHILLES Analyses on CONDITION_OCCURRENCE table
***********************************************************/

-- create raw data table based on CONDITION_OCCURRENCE for better performance
-- create table condition_occurrence_raw as
-- select person_id, gender_concept_id, condition_concept_id, year_of_birth, syear, smonth, sday, 
	-- cast(concat_ws('-', cast(syear as string), lpad(cast(smonth as string), 2, '0'), lpad(cast(sday as string), 2, '0')) as timestamp) as sdate,
	-- eyear, emonth, eday, 
	-- cast(concat_ws('-', cast(eyear as string), lpad(cast(emonth as string), 2, '0'), lpad(cast(eday as string), 2, '0')) as timestamp) as edate
-- from 
 -- (
	-- select p.person_id, p.gender_concept_id, op.condition_concept_id,
	   -- cast(p.YEAR_OF_BIRTH as int) as year_of_birth, 
	   -- cast(regexp_extract(condition_start_date, '/(\\d+)$', 1) as int) as syear,
	   -- cast(regexp_extract(condition_start_date, '^(\\d+)/', 1) as int) as smonth,
	   -- cast(regexp_extract(condition_start_date, '/(\\d+)/', 1) as int) as sday,
	   -- cast(regexp_extract(condition_end_date, '/(\\d+)$', 1) as int) as eyear,
	   -- cast(regexp_extract(condition_end_date, '^(\\d+)/', 1) as int) as emonth,
	   -- cast(regexp_extract(condition_end_date, '/(\\d+)/', 1) as int) as eday
	-- from PERSON p join condition_occurrence op on p.person_id = op.person_id
 -- ) t
-- ;

-- 400   Number of persons with at least one condition occurrence, by condition_concept_id
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 400 as analysis_id, 
   cast(co1.condition_CONCEPT_ID as string) as stratum_1,
   count(distinct co1.PERSON_ID) as count_value
from condition_occurrence co1
group by co1.condition_CONCEPT_ID
;

-- 401   Number of condition occurrence records, by condition_concept_id
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 401 as analysis_id, 
   cast(co1.condition_CONCEPT_ID as string) as stratum_1,
   count(co1.PERSON_ID) as count_value
from condition_occurrence co1
group by co1.condition_CONCEPT_ID
;

-- 402   Number of persons by condition occurrence start month, by condition_concept_id
insert into ACHILLES_results (analysis_id, stratum_1, stratum_2, count_value)
select 402 as analysis_id,   
   cast(condition_concept_id as string) as stratum_1,
   cast(year(cast(condition_start_date as timestamp))*100 + month(cast(condition_start_date as timestamp)) as string) as stratum_2, 
   count(distinct PERSON_ID) as count_value
from condition_occurrence
group by condition_concept_id, year(cast(condition_start_date as timestamp))*100 + month(cast(condition_start_date as timestamp))
;

-- 403   Number of distinct condition occurrence concepts per person
insert into ACHILLES_results_dist (analysis_id, count_value, min_value, max_value, avg_value, stdev_value, median_value, p10_value, p25_value, p75_value, p90_value)
with rawData as
(
  select person_id, count(distinct condition_concept_id) as count_value
  from condition_occurrence
  group by person_id
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
select 403 as analysis_id,
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

-- 404   Number of persons with at least one condition occurrence, by condition_concept_id by calendar year by gender by age decile
insert into ACHILLES_results (analysis_id, stratum_1, stratum_2, stratum_3, stratum_4, count_value)
select 404 as analysis_id,   
   cast(condition_concept_id as string) as stratum_1,
   cast(year(cast(condition_start_date as timestamp)) as string) as stratum_2,
   cast(gender_concept_id as string) as stratum_3,
   cast(floor((year(cast(condition_start_date as timestamp)) - year_of_birth)/10) as string) as stratum_4, 
   count(distinct p1.PERSON_ID) as count_value
from PERSON p1
	inner join condition_occurrence co1 on p1.person_id = co1.person_id
group by condition_concept_id, 
	year(cast(condition_start_date as timestamp)), 
	gender_concept_id, 
	floor((year(cast(condition_start_date as timestamp)) - year_of_birth)/10)
;

-- 405   Number of condition occurrence records, by condition_concept_id by condition_type_concept_id
insert into ACHILLES_results (analysis_id, stratum_1, stratum_2, count_value)
select 405 as analysis_id, 
   cast(co1.condition_CONCEPT_ID as string) as stratum_1,
   cast(co1.condition_type_concept_id as string) as stratum_2,
   count(co1.PERSON_ID) as count_value
from
   condition_occurrence co1
group by co1.condition_CONCEPT_ID,   
   co1.condition_type_concept_id
;

-- 406   Distribution of age by condition_concept_id
insert into ACHILLES_results_dist (analysis_id, stratum_1, stratum_2, count_value, min_value, max_value, avg_value, stdev_value, median_value, p10_value, p25_value, p75_value, p90_value)
with rawdata as(
	select co1.condition_concept_id as subject_id,
	   p1.gender_concept_id,
	   (co1.condition_start_year - p1.year_of_birth) as count_value
	from PERSON p1
		inner join
		(
		   select person_id, condition_concept_id, min(year(cast(condition_start_date as timestamp))) as condition_start_year
		   from condition_occurrence
		   group by person_id, condition_concept_id
		) co1 on p1.person_id = co1.person_id
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
select 406 as analysis_id,
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

-- 409   Number of condition occurrence records with invalid person_id
insert into ACHILLES_results (analysis_id, count_value)
select 409 as analysis_id,  
   count(co1.PERSON_ID) as count_value
from
   condition_occurrence co1
   left join PERSON p1
   on p1.person_id = co1.person_id
where p1.person_id is null
;

-- 410   Number of condition occurrence records outside valid observation period
insert into ACHILLES_results (analysis_id, count_value)
select 410 as analysis_id,  
   count(co1.PERSON_ID) as count_value
from
   condition_occurrence co1
   left join observation_period op1
   on op1.person_id = co1.person_id
   and cast(co1.condition_start_date as timestamp) >= cast(op1.observation_period_start_date as timestamp)
   and cast(co1.condition_start_date as timestamp) <= cast(op1.observation_period_end_date as timestamp)
where op1.person_id is null
;

-- 411   Number of condition occurrence records with end date < start date
insert into ACHILLES_results (analysis_id, count_value)
select 411 as analysis_id, count(co1.PERSON_ID) as count_value
from condition_occurrence co1
where cast(co1.condition_end_date as timestamp) < cast(co1.condition_start_date as timestamp)
;

-- 412   Number of condition occurrence records with invalid provider_id
insert into ACHILLES_results (analysis_id, count_value)
select 412 as analysis_id,  
   count(co1.PERSON_ID) as count_value
from
   condition_occurrence co1
   left join provider p1
   on p1.provider_id = co1.provider_id
where co1.provider_id is not null
   and p1.provider_id is null
;

-- 413   Number of condition occurrence records with invalid visit_id
insert into ACHILLES_results (analysis_id, count_value)
select 413 as analysis_id,  
   count(co1.PERSON_ID) as count_value
from
   condition_occurrence co1
   left join visit_occurrence vo1
   on co1.visit_occurrence_id = vo1.visit_occurrence_id
where co1.visit_occurrence_id is not null
   and vo1.visit_occurrence_id is null
;

-- 420   Number of condition occurrence records by condition occurrence start month
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 420 as analysis_id,   
   cast(year(cast(condition_start_date as timestamp))*100 + month(cast(condition_start_date as timestamp)) as string) as stratum_1, 
   count(PERSON_ID) as count_value
from condition_occurrence 
group by year(cast(condition_start_date as timestamp))*100 + month(cast(condition_start_date as timestamp))
;

exit;
