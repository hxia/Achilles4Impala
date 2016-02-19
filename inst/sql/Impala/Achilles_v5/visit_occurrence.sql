
/********************************************
ACHILLES Analyses on VISIT_OCCURRENCE table
*********************************************/

-- create raw data table based on VISIT_OCCURRENCE for better performace
create table visit_occurrence_raw as
select person_id, gender_concept_id, visit_concept_id, year_of_birth, syear, smonth, sday, 
	cast(concat_ws('-', cast(syear as string), lpad(cast(smonth as string), 2, '0'), lpad(cast(sday as string), 2, '0')) as timestamp) as sdate,
	eyear, emonth, eday, 
	cast(concat_ws('-', cast(eyear as string), lpad(cast(emonth as string), 2, '0'), lpad(cast(eday as string), 2, '0')) as timestamp) as edate
from 
 (
	select p.person_id, p.gender_concept_id, op.visit_concept_id,
	   cast(p.YEAR_OF_BIRTH as int) as year_of_birth, 
	   cast(regexp_extract(visit_start_date, '/(\\d+)$', 1) as int) as syear,
	   cast(regexp_extract(visit_start_date, '^(\\d+)/', 1) as int) as smonth,
	   cast(regexp_extract(visit_start_date, '/(\\d+)/', 1) as int) as sday,
	   cast(regexp_extract(visit_end_date, '/(\\d+)$', 1) as int) as eyear,
	   cast(regexp_extract(visit_end_date, '^(\\d+)/', 1) as int) as emonth,
	   cast(regexp_extract(visit_end_date, '/(\\d+)/', 1) as int) as eday
	from PERSON p join visit_occurrence op on p.person_id = op.person_id
 ) t
;


-- 200   Number of persons with at least one visit occurrence, by visit_concept_id
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 200 as analysis_id, 
   cast(vo1.visit_concept_id as string) as stratum_1,
   count(distinct vo1.PERSON_ID) as count_value
from visit_occurrence vo1
group by vo1.visit_concept_id
;


-- 201   Number of visit occurrence records, by visit_concept_id
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 201 as analysis_id, 
   cast(vo1.visit_concept_id as string) as stratum_1,
   count(vo1.PERSON_ID) as count_value
from visit_occurrence vo1
group by vo1.visit_concept_id
;


-- 202   Number of persons by visit occurrence start month, by visit_concept_id
insert into ACHILLES_results (analysis_id, stratum_1, stratum_2, count_value)
select 202 as analysis_id,   
   cast(vo1.visit_concept_id as string) as stratum_1,
   cast(syear*100 + smonth as string) as stratum_2, 
   count(distinct PERSON_ID) as count_value
from visit_occurrence_raw vo1
group by vo1.visit_concept_id, syear*100 + smonth
;


-- 203   Number of distinct visit occurrence concepts per person
insert into ACHILLES_results_dist (analysis_id, count_value, min_value, max_value, avg_value, stdev_value, median_value, p10_value, p25_value, p75_value, p90_value)
with rawData as
(
    select person_id as stratum1_id, gender_concept_id as stratum2_id, count(distinct visit_concept_id) as count_value
    from visit_occurrence_raw 
    group by person_id, gender_concept_id
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
select 203 as analysis_id,
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


-- 204   Number of persons with at least one visit occurrence, by visit_concept_id by calendar year by gender by age decile
insert into ACHILLES_results (analysis_id, stratum_1, stratum_2, stratum_3, stratum_4, count_value)
select 204 as analysis_id,   
   cast(visit_concept_id as string) as stratum_1,
   cast(syear as string) as stratum_2,
   cast(gender_concept_id as string) as stratum_3,
   cast(floor((syear - year_of_birth)/10) as string) as stratum_4, 
   count(distinct PERSON_ID) as count_value
from visit_occurrence_raw 
group by visit_concept_id, syear, gender_concept_id, floor((syear - year_of_birth)/10)
;


-- 206   Distribution of age by visit_concept_id
insert into ACHILLES_results_dist (analysis_id, stratum_1, stratum_2, count_value, min_value, max_value, avg_value, stdev_value, median_value, p10_value, p25_value, p75_value, p90_value)
with rawData as
(
  select visit_concept_id as stratum1_id, gender_concept_id as stratum2_id, visit_start_year - year_of_birth as count_value
   from 
	  (
		  select person_id, gender_concept_id, year_of_birth, visit_concept_id, min(syear) as visit_start_year
		  from visit_occurrence_raw
		  group by person_id, gender_concept_id, year_of_birth, visit_concept_id
	   ) vo1 
),
overallStats as
(
  select stratum1_id,
    stratum2_id,
    avg(1.0 * count_value) as avg_value,
    stddev(count_value) as stdev_value,
    min(count_value) as min_value,
    max(count_value) as max_value,
    count(*) as total
  from rawData
   group by stratum1_id, stratum2_id
),
status  as
(
  select stratum1_id, stratum2_id, count_value, count(*) as total, row_number() over (partition by stratum1_id, stratum2_id order by count_value) as rn
  from rawData
  group by stratum1_id, stratum2_id, count_value
),
priorStats as
(
  select s.stratum1_id, s.stratum2_id, s.count_value, s.total, sum(p.total) as accumulated
  from status  s
  join status  p on s.stratum1_id = p.stratum1_id and s.stratum2_id = p.stratum2_id and p.rn <= s.rn
  group by s.stratum1_id, s.stratum2_id, s.count_value, s.total, s.rn
)
select 206 as analysis_id,
  o.stratum1_id,
  o.stratum2_id,
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


--207   Number of visit records with invalid person_id
insert into ACHILLES_results (analysis_id, count_value)
select 207 as analysis_id, count(vo1.PERSON_ID) as count_value
from visit_occurrence vo1
   left join PERSON p1 on p1.person_id = vo1.person_id
where p1.person_id is null
;


--208   Number of visit records outside valid observation period
insert into ACHILLES_results (analysis_id, count_value)
select 208 as analysis_id,  
   count(vo1.PERSON_ID) as count_value
from visit_occurrence_raw vo1
   left join observation_period_raw op1
		on op1.person_id = vo1.person_id and vo1.sdate >= op1.sdate and vo1.sdate <= op1.edate
where op1.person_id is null
;


--209   Number of visit records with end date < start date
insert into ACHILLES_results (analysis_id, count_value)
select 209 as analysis_id, count(PERSON_ID) as count_value
from visit_occurrence_raw vo1
where edate < sdate
;


--210   Number of visit records with invalid care_site_id
insert into ACHILLES_results (analysis_id, count_value)
select 210 as analysis_id, count(vo1.PERSON_ID) as count_value
from visit_occurrence vo1
   left join care_site cs1 on vo1.care_site_id = cs1.care_site_id
where vo1.care_site_id is not null and cs1.care_site_id is null
;


-- 211   Distribution of length of stay by visit_concept_id
insert into ACHILLES_results_dist (analysis_id, stratum_1, count_value, min_value, max_value, avg_value, stdev_value, median_value, p10_value, p25_value, p75_value, p90_value)
with rawData as
(
  select visit_concept_id as stratum_id, datediff(edate,sdate) as count_value
  from visit_occurrence_raw
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
select 211 as analysis_id,
  o.stratum_id,
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


-- 220   Number of visit occurrence records by condition occurrence start month
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 220 as analysis_id,    
   cast(syear*100 + smonth as string) as stratum_1, 
   count(PERSON_ID) as count_value
from visit_occurrence_raw
group by syear*100 + smonth
;
