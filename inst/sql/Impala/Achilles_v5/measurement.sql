

/********************************************
  ACHILLES Analyses on MEASUREMENT table
*********************************************/

-- 1800   Number of persons with at least one measurement occurrence, by measurement_concept_id
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 1800 as analysis_id, 
   cast(m.measurement_CONCEPT_ID as string) as stratum_1,
   count(distinct m.PERSON_ID) as count_value
from measurement m
group by m.measurement_CONCEPT_ID
;


-- 1801   Number of measurement occurrence records, by measurement_concept_id
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 1801 as analysis_id, 
   cast(m.measurement_concept_id as string) as stratum_1,
   count(m.PERSON_ID) as count_value
from measurement m
group by m.measurement_CONCEPT_ID
;


-- 1802   Number of persons by measurement occurrence start month, by measurement_concept_id
insert into ACHILLES_results (analysis_id, stratum_1, stratum_2, count_value)
select 1802 as analysis_id,   
   cast(m.measurement_concept_id as string) as stratum_1,
   cast(YEAR(cast(measurement_date as timestamp))*100 + month(cast(measurement_date as timestamp)) as string) as stratum_2, 
   count(distinct PERSON_ID) as count_value
from measurement m
group by m.measurement_concept_id, 
   YEAR(cast(measurement_date as timestamp))*100 + month(cast(measurement_date as timestamp))
;


-- 1803   Number of distinct measurement occurrence concepts per person
insert into ACHILLES_results_dist (analysis_id, count_value, min_value, max_value, avg_value, stdev_value, median_value, p10_value, p25_value, p75_value, p90_value)
with rawData as
(
  select num_measurements as count_value
  from
   (
     select m.person_id, count(distinct m.measurement_concept_id) as num_measurements
     from
     measurement m
     group by m.person_id
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
select 1803 as analysis_id,
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


-- 1804   Number of persons with at least one measurement occurrence, by measurement_concept_id by calendar year by gender by age decile
insert into ACHILLES_results (analysis_id, stratum_1, stratum_2, stratum_3, stratum_4, count_value)
select 1804 as analysis_id,   
   cast(m.measurement_concept_id as string) as stratum_1,
   cast(YEAR(cast(measurement_date as timestamp)) as string) as stratum_2,
   cast(p1.gender_concept_id as string) as stratum_3,
   cast(floor((year(cast(measurement_date as timestamp)) - p1.year_of_birth)/10) as string) as stratum_4, 
   count(distinct p1.PERSON_ID) as count_value
from PERSON p1
inner join measurement m on p1.person_id = m.person_id
group by m.measurement_concept_id, 
   YEAR(cast(measurement_date as timestamp)),
   p1.gender_concept_id,
   floor((year(cast(measurement_date as timestamp)) - p1.year_of_birth)/10)
;


-- 1805   Number of measurement records, by measurement_concept_id by measurement_type_concept_id
insert into ACHILLES_results (analysis_id, stratum_1, stratum_2, count_value)
select 1805 as analysis_id, 
   cast(m.measurement_concept_id as string) as stratum_1,
   cast(m.measurement_type_concept_id as string) as stratum_2,
   count(m.PERSON_ID) as count_value
from measurement m
group by m.measurement_concept_id,   
   m.measurement_type_concept_id
;


-- 1806   Distribution of age by measurement_concept_id
insert into ACHILLES_results_dist (analysis_id, stratum_1, stratum_2, count_value, min_value, max_value, avg_value, stdev_value, median_value, p10_value, p25_value, p75_value, p90_value)
with rawData as
	(
	select o1.measurement_concept_id as subject_id,
	  p1.gender_concept_id,
	   o1.measurement_start_year - p1.year_of_birth as count_value
	from PERSON p1
	inner join
	(
	   select person_id, measurement_concept_id, min(year(cast(measurement_date as timestamp))) as measurement_start_year
	   from measurement
	   group by person_id, measurement_concept_id
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
select 1806 as analysis_id,
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


-- 1807   Number of measurement occurrence records, by measurement_concept_id and unit_concept_id
insert into ACHILLES_results (analysis_id, stratum_1, stratum_2, count_value)
select 1807 as analysis_id, 
   cast(m.measurement_concept_id as string) as stratum_1,
   cast(m.unit_concept_id as string) as stratum_2,
   count(m.PERSON_ID) as count_value
from measurement m
group by m.measurement_concept_id, m.unit_concept_id
;


-- 1809   Number of measurement records with invalid person_id
insert into ACHILLES_results (analysis_id, count_value)
select 1809 as analysis_id,  
   count(m.PERSON_ID) as count_value
from measurement m
   left join PERSON p1 on p1.person_id = m.person_id
where p1.person_id is null
;


-- 1810   Number of measurement records outside valid observation period
insert into ACHILLES_results (analysis_id, count_value)
select 1810 as analysis_id,  
   count(m.PERSON_ID) as count_value
from measurement m
   left join observation_period op on op.person_id = m.person_id
   and cast(m.measurement_date as timestamp) >= cast(op.observation_period_start_date as timestamp)
   and cast(m.measurement_date as timestamp) <= cast(op.observation_period_end_date as timestamp)
where op.person_id is null
;


-- 1812   Number of measurement records with invalid provider_id
insert into ACHILLES_results (analysis_id, count_value)
select 1812 as analysis_id,  
   count(m.PERSON_ID) as count_value
from measurement m
   left join provider p on p.provider_id = m.provider_id
where m.provider_id is not null
   and p.provider_id is null
;


-- 1813   Number of observation records with invalid visit_id
insert into ACHILLES_results (analysis_id, count_value)
select 1813 as analysis_id, count(m.PERSON_ID) as count_value
from measurement m
   left join visit_occurrence vo on m.visit_occurrence_id = vo.visit_occurrence_id
where m.visit_occurrence_id is not null
   and vo.visit_occurrence_id is null
;


-- 1814   Number of measurement records with no value (numeric or concept)
insert into ACHILLES_results (analysis_id, count_value)
select 814 as analysis_id,  
   count(m.PERSON_ID) as count_value
from measurement m
where m.value_as_number is null
   and m.value_as_concept_id is null
;


-- 1815  Distribution of numeric values, by measurement_concept_id and unit_concept_id
insert into ACHILLES_results_dist (analysis_id, stratum_1, stratum_2, count_value, min_value, max_value, avg_value, stdev_value, median_value, p10_value, p25_value, p75_value, p90_value)
with rawData as(
select measurement_concept_id as subject_id, 
   unit_concept_id,
   value_as_number as count_value
from measurement m
where m.unit_concept_id is not null and m.value_as_number is not null
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
select 1815 as analysis_id,
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


-- 1816   Distribution of low range, by measurement_concept_id and unit_concept_id
insert into ACHILLES_results_dist (analysis_id, stratum_1, stratum_2, count_value, min_value, max_value, avg_value, stdev_value, median_value, p10_value, p25_value, p75_value, p90_value)
with rawData as
(
	select measurement_concept_id as subject_id, 
	   unit_concept_id,
	   range_low as count_value
	from measurement m
	where m.unit_concept_id is not null
	   and m.value_as_number is not null
	   and m.range_low is not null
	   and m.range_high is not null
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
select 1816 as analysis_id,
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


-- 1817   Distribution of high range, by observation_concept_id and unit_concept_id
insert into ACHILLES_results_dist (analysis_id, stratum_1, stratum_2, count_value, min_value, max_value, avg_value, stdev_value, median_value, p10_value, p25_value, p75_value, p90_value)
with rawData as
	(
	select measurement_concept_id as subject_id, 
	   unit_concept_id,
	   range_high as count_value
	from measurement m
	where m.unit_concept_id is not null
	   and m.value_as_number is not null
	   and m.range_low is not null
	   and m.range_high is not null
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
select 1817 as analysis_id,
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


-- 1818   Number of observation records below/within/above normal range, by observation_concept_id and unit_concept_id
insert into ACHILLES_results (analysis_id, stratum_1, stratum_2, stratum_3, count_value)
select 1818 as analysis_id,  
   cast(m.measurement_concept_id as string) as stratum_1,
   cast(m.unit_concept_id as string) as stratum_2,
   case when m.value_as_number < m.range_low then 'Below Range Low'
      when m.value_as_number >= m.range_low and m.value_as_number <= m.range_high then 'Within Range'
      when m.value_as_number > m.range_high then 'Above Range High'
      else 'Other' end as stratum_3,
   count(m.PERSON_ID) as count_value
from measurement m
where m.value_as_number is not null
   and m.unit_concept_id is not null
   and m.range_low is not null
   and m.range_high is not null
group by measurement_concept_id,
   unit_concept_id,
     case when m.value_as_number < m.range_low then 'Below Range Low'
      when m.value_as_number >= m.range_low and m.value_as_number <= m.range_high then 'Within Range'
      when m.value_as_number > m.range_high then 'Above Range High'
      else 'Other' end
;


-- 1820   Number of observation records by condition occurrence start month
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 1820 as analysis_id,   
   cast(YEAR(cast(measurement_date as timestamp))*100 + month(cast(measurement_date as timestamp)) as string) as stratum_1, 
   count(PERSON_ID) as count_value
from measurement m
group by YEAR(cast(measurement_date as timestamp))*100 + month(cast(measurement_date as timestamp))
;
