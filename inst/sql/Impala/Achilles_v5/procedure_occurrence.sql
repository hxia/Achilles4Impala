
/***************************************************
ACHILLES Analyses on PROCEDURE_OCCURRENCE table
****************************************************/

-- create raw data table based on PROCEDURE_OCCURRENCE for query simplification
-- create table drug_era_raw as
-- select person_id, gender_concept_id, drug_concept_id, year_of_birth, syear, smonth, sday, 
	-- cast(concat_ws('-', cast(syear as string), lpad(cast(smonth as string), 2, '0'), lpad(cast(sday as string), 2, '0')) as timestamp) as sdate,
	-- eyear, emonth, eday, 
	-- cast(concat_ws('-', cast(eyear as string), lpad(cast(emonth as string), 2, '0'), lpad(cast(eday as string), 2, '0')) as timestamp) as edate
-- from 
 -- (
	-- select p.person_id, p.gender_concept_id, op.drug_concept_id,
	   -- cast(p.YEAR_OF_BIRTH as int) as year_of_birth, 
	   -- cast(regexp_extract(drug_era_start_date, '/(\\d+)$', 1) as int) as syear,
	   -- cast(regexp_extract(drug_era_start_date, '^(\\d+)/', 1) as int) as smonth,
	   -- cast(regexp_extract(drug_era_start_date, '/(\\d+)/', 1) as int) as sday,
	   -- cast(regexp_extract(drug_era_end_date, '/(\\d+)$', 1) as int) as eyear,
	   -- cast(regexp_extract(drug_era_end_date, '^(\\d+)/', 1) as int) as emonth,
	   -- cast(regexp_extract(drug_era_end_date, '/(\\d+)/', 1) as int) as eday
	-- from PERSON p join drug_era op on p.person_id = op.person_id
 -- ) t
-- ;

-- 600   Number of persons with at least one procedure occurrence, by procedure_concept_id
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 600 as analysis_id, 
   cast(po1.procedure_CONCEPT_ID as string) as stratum_1,
   count(distinct po1.PERSON_ID) as count_value
from procedure_occurrence po1
group by po1.procedure_CONCEPT_ID
;

-- 601   Number of procedure occurrence records, by procedure_concept_id
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 601 as analysis_id, 
   cast(po1.procedure_CONCEPT_ID as string) as stratum_1,
   count(po1.PERSON_ID) as count_value
from procedure_occurrence po1
group by po1.procedure_CONCEPT_ID
;

-- 602   Number of persons by procedure occurrence start month, by procedure_concept_id
insert into ACHILLES_results (analysis_id, stratum_1, stratum_2, count_value)
select 602 as analysis_id,   
   cast(po1.procedure_concept_id as string) as stratum_1,
   cast(YEAR(cast(procedure_date as timestamp))*100 + month(cast(procedure_date as timestamp)) as string) as stratum_2, 
   count(distinct PERSON_ID) as count_value
from procedure_occurrence po1
group by po1.procedure_concept_id, YEAR(cast(procedure_date as timestamp))*100 + month(cast(procedure_date as timestamp))
;

-- 603   Number of distinct procedure occurrence concepts per person
insert into ACHILLES_results_dist (analysis_id, count_value, min_value, max_value, avg_value, stdev_value, median_value, p10_value, p25_value, p75_value, p90_value)
with rawData as
(
  select count(distinct po.procedure_concept_id) as count_value
   from procedure_occurrence po
   group by po.person_id
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
select 603 as analysis_id,
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

-- 604   Number of persons with at least one procedure occurrence, by procedure_concept_id by calendar year by gender by age decile
insert into ACHILLES_results (analysis_id, stratum_1, stratum_2, stratum_3, stratum_4, count_value)
select 604 as analysis_id,   
   cast(po1.procedure_concept_id as string) as stratum_1,
   cast(YEAR(cast(procedure_date as timestamp)) as string) as stratum_2,
   cast(p1.gender_concept_id as string) as stratum_3,
   cast(floor((year(cast(procedure_date as timestamp)) - p1.year_of_birth)/10) as string) as stratum_4, 
   count(distinct p1.PERSON_ID) as count_value
from PERSON p1
	inner join procedure_occurrence po1 on p1.person_id = po1.person_id
group by po1.procedure_concept_id, 
   YEAR(cast(procedure_date as timestamp)),
   p1.gender_concept_id,
   floor((year(cast(procedure_date as timestamp)) - p1.year_of_birth)/10)
;

-- 605   Number of procedure occurrence records, by procedure_concept_id by procedure_type_concept_id
insert into ACHILLES_results (analysis_id, stratum_1, stratum_2, count_value)
select 605 as analysis_id, 
   cast(po1.procedure_CONCEPT_ID as string) as stratum_1,
   cast(po1.procedure_type_concept_id as string) as stratum_2,
   count(po1.PERSON_ID) as count_value
from procedure_occurrence po1
group by po1.procedure_CONCEPT_ID, po1.procedure_type_concept_id
;

-- 606   Distribution of age by procedure_concept_id
insert into ACHILLES_results_dist (analysis_id, stratum_1, stratum_2, count_value, min_value, max_value, avg_value, stdev_value, median_value, p10_value, p25_value, p75_value, p90_value)
with rawData as 
(
	select po1.procedure_concept_id as subject_id,
	   p1.gender_concept_id,
	   po1.procedure_start_year - p1.year_of_birth as count_value
	from PERSON p1
	inner join
	(
	   select person_id, procedure_concept_id, min(year(cast(procedure_date as timestamp))) as procedure_start_year
	   from procedure_occurrence
	   group by person_id, procedure_concept_id
	) po1 on p1.person_id = po1.person_id
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
select 606 as analysis_id,
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

-- 609   Number of procedure occurrence records with invalid person_id
insert into ACHILLES_results (analysis_id, count_value)
select 609 as analysis_id,  
   count(po1.PERSON_ID) as count_value
from procedure_occurrence po1
   left join PERSON p1 on p1.person_id = po1.person_id
where p1.person_id is null
;

-- 610   Number of procedure occurrence records outside valid observation period
insert into ACHILLES_results (analysis_id, count_value)
select 610 as analysis_id,  
   count(po1.PERSON_ID) as count_value
from procedure_occurrence po1
   left join observation_period op1
   on op1.person_id = po1.person_id
   and cast(po1.procedure_date as timestamp) >= cast(op1.observation_period_start_date as timestamp)
   and cast(po1.procedure_date as timestamp) <= cast(op1.observation_period_end_date as timestamp)
where op1.person_id is null
;

-- 612   Number of procedure occurrence records with invalid provider_id
insert into ACHILLES_results (analysis_id, count_value)
select 612 as analysis_id,  
   count(po1.PERSON_ID) as count_value
from procedure_occurrence po1
   left join provider p1 on p1.provider_id = po1.provider_id
where po1.provider_id is not null and p1.provider_id is null
;

-- 613   Number of procedure occurrence records with invalid visit_id
insert into ACHILLES_results (analysis_id, count_value)
select 613 as analysis_id,  
   count(po1.PERSON_ID) as count_value
from procedure_occurrence po1
   left join visit_occurrence vo1 on po1.visit_occurrence_id = vo1.visit_occurrence_id
where po1.visit_occurrence_id is not null and vo1.visit_occurrence_id is null
;

-- 620   Number of procedure occurrence records by condition occurrence start month
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 620 as analysis_id,   
   cast(YEAR(cast(procedure_date as timestamp))*100 + month(cast(procedure_date as timestamp)) as string) as stratum_1, 
   count(PERSON_ID) as count_value
from procedure_occurrence po1
group by YEAR(cast(procedure_date as timestamp))*100 + month(cast(procedure_date as timestamp))
;

exit;
