
/********************************************
ACHILLES Analyses on OBSERVATION table
*********************************************/

-- 800   Number of persons with at least one observation occurrence, by observation_concept_id
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 800 as analysis_id, 
   cast(o1.observation_CONCEPT_ID as string) as stratum_1,
   count(distinct o1.PERSON_ID) as count_value
from observation o1
group by o1.observation_CONCEPT_ID
;

-- 801   Number of observation occurrence records, by observation_concept_id
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 801 as analysis_id, 
   cast(o1.observation_CONCEPT_ID as string) as stratum_1,
   count(o1.PERSON_ID) as count_value
from observation o1
group by o1.observation_CONCEPT_ID
;

-- 802   Number of persons by observation occurrence start month, by observation_concept_id
insert into ACHILLES_results (analysis_id, stratum_1, stratum_2, count_value)
select 802 as analysis_id,   
   cast(o1.observation_concept_id as string) as stratum_1,
   cast(YEAR(cast(observation_date as timestamp))*100 + month(cast(observation_date as timestamp)) as string) as stratum_2, 
   count(distinct PERSON_ID) as count_value
from observation o1
group by o1.observation_concept_id, 
   YEAR(cast(observation_date as timestamp))*100 + month(cast(observation_date as timestamp))
;

-- 803   Number of distinct observation occurrence concepts per person
insert into ACHILLES_results_dist (analysis_id, count_value, min_value, max_value, avg_value, stdev_value, median_value, p10_value, p25_value, p75_value, p90_value)
with rawData as
(
  select num_observations as count_value
  from
   (
     select o1.person_id, count(distinct o1.observation_concept_id) as num_observations
     from
     observation o1
     group by o1.person_id
   ) t0
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
select 803 as analysis_id,
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

-- 804   Number of persons with at least one observation occurrence, by observation_concept_id by calendar year by gender by age decile
insert into ACHILLES_results (analysis_id, stratum_1, stratum_2, stratum_3, stratum_4, count_value)
select 804 as analysis_id,   
   cast(o1.observation_concept_id as string) as stratum_1,
   cast(YEAR(cast(observation_date as timestamp)) as string) as stratum_2,
   cast(p1.gender_concept_id as string) as stratum_3,
   cast(floor((year(cast(observation_date as timestamp)) - p1.year_of_birth)/10) as string) as stratum_4, 
   count(distinct p1.PERSON_ID) as count_value
from PERSON p1
	inner join observation o1 on p1.person_id = o1.person_id
group by o1.observation_concept_id, 
   YEAR(cast(observation_date as timestamp)),
   p1.gender_concept_id,
   floor((year(cast(observation_date as timestamp)) - p1.year_of_birth)/10)
;

-- 805   Number of observation occurrence records, by observation_concept_id by observation_type_concept_id
insert into ACHILLES_results (analysis_id, stratum_1, stratum_2, count_value)
select 805 as analysis_id, 
   cast(o1.observation_CONCEPT_ID as string) as stratum_1,
   cast(o1.observation_type_concept_id as string) as stratum_2,
   count(o1.PERSON_ID) as count_value
from observation o1
group by o1.observation_CONCEPT_ID, o1.observation_type_concept_id
;

-- 806   Distribution of age by observation_concept_id
insert into ACHILLES_results_dist (analysis_id, stratum_1, stratum_2, count_value, min_value, max_value, avg_value, stdev_value, median_value, p10_value, p25_value, p75_value, p90_value)
with rawData as 
	(
	select o1.observation_concept_id as subject_id,
	  p1.gender_concept_id,
	   o1.observation_start_year - p1.year_of_birth as count_value
	from PERSON p1
	inner join
	(
	   select person_id, observation_concept_id, min(year(cast(observation_date as timestamp))) as observation_start_year
	   from observation
	   group by person_id, observation_concept_id
	) o1
	on p1.person_id = o1.person_id
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
select 806 as analysis_id,
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

-- 807   Number of observation occurrence records, by observation_concept_id and unit_concept_id
insert into ACHILLES_results (analysis_id, stratum_1, stratum_2, count_value)
select 807 as analysis_id, 
   cast(o1.observation_CONCEPT_ID as string) as stratum_1,
   cast(o1.unit_concept_id as string) as stratum_2,
   count(o1.PERSON_ID) as count_value
from observation o1
group by o1.observation_CONCEPT_ID, o1.unit_concept_id
;

-- 809   Number of observation records with invalid person_id
insert into ACHILLES_results (analysis_id, count_value)
select 809 as analysis_id,  
   count(o1.PERSON_ID) as count_value
from observation o1
   left join PERSON p1 on p1.person_id = o1.person_id
where p1.person_id is null
;

-- 810   Number of observation records outside valid observation period
insert into ACHILLES_results (analysis_id, count_value)
select 810 as analysis_id,  
   count(o1.PERSON_ID) as count_value
from observation o1
   left join observation_period op1
   on op1.person_id = o1.person_id
   and cast(o1.observation_date as timestamp) >= cast(op1.observation_period_start_date as timestamp)
   and cast(o1.observation_date as timestamp) <= cast(op1.observation_period_end_date as timestamp)
where op1.person_id is null
;

-- 812   Number of observation records with invalid provider_id
insert into ACHILLES_results (analysis_id, count_value)
select 812 as analysis_id,  
   count(o1.PERSON_ID) as count_value
from observation o1
   left join provider p1 on p1.provider_id = o1.provider_id
where o1.provider_id is not null and p1.provider_id is null
;

-- 813   Number of observation records with invalid visit_id
insert into ACHILLES_results (analysis_id, count_value)
select 813 as analysis_id,  
   count(o1.PERSON_ID) as count_value
from observation o1
   left join visit_occurrence vo1 on o1.visit_occurrence_id = vo1.visit_occurrence_id
where o1.visit_occurrence_id is not null and vo1.visit_occurrence_id is null
;

-- 814   Number of observation records with no value (numeric, string, or concept)
insert into ACHILLES_results (analysis_id, count_value)
select 814 as analysis_id,  
   count(o1.PERSON_ID) as count_value
from observation o1
where o1.value_as_number is null
   and o1.value_as_string is null
   and o1.value_as_concept_id is null
;

-- 815  Distribution of numeric values, by observation_concept_id and unit_concept_id
insert into ACHILLES_results_dist (analysis_id, stratum_1, stratum_2, count_value, min_value, max_value, avg_value, stdev_value, median_value, p10_value, p25_value, p75_value, p90_value)
with rawData as
(
	select observation_concept_id as subject_id, 
	   unit_concept_id,
	   value_as_number as count_value
	from observation o1
	where o1.unit_concept_id is not null and o1.value_as_number is not null
),
overallStats as
(
  select subject_id as stratum1_id,
    unit_concept_id as stratum2_id,
    avg(1.0 * count_value) as avg_value,
    stddev(count_value) as stdev_value,
    min(count_value) as min_value,
    max(count_value) as max_value,
    count(*) as total
  from rawData
   group by subject_id, unit_concept_id
),
status  as
(
  select subject_id as stratum1_id, unit_concept_id as stratum2_id, count_value, count(*) as total, row_number() over (partition by subject_id, unit_concept_id order by count_value) as rn
  from rawData
  group by subject_id, unit_concept_id, count_value
),
priorStats as
(
  select s.stratum1_id, s.stratum2_id, s.count_value, s.total, sum(p.total) as accumulated
  from status  s
  join status  p on s.stratum1_id = p.stratum1_id and s.stratum2_id = p.stratum2_id and p.rn <= s.rn
  group by s.stratum1_id, s.stratum2_id, s.count_value, s.total, s.rn
)
select 815 as analysis_id,
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

-- 816   Distribution of low range, by observation_concept_id and unit_concept_id
--NOT APPLICABLE FOR OMOP CDM v5

-- 817   Distribution of high range, by observation_concept_id and unit_concept_id
--NOT APPLICABLE FOR OMOP CDM v5

-- 818   Number of observation records below/within/above normal range, by observation_concept_id and unit_concept_id
--NOT APPLICABLE FOR OMOP CDM v5

-- 820   Number of observation records by condition occurrence start month
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 820 as analysis_id,   
   cast(YEAR(cast(observation_date as timestamp))*100 + month(cast(observation_date as timestamp)) as string) as stratum_1, 
   count(PERSON_ID) as count_value
from observation o1
group by YEAR(cast(observation_date as timestamp))*100 + month(cast(observation_date as timestamp))
;

exit;
