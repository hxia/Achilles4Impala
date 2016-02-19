

/********************************************
ACHILLES Analyses on DRUG_EXPOSURE table
*********************************************/

-- create raw data table based on DRUG_EXPOSURE for better performance
create table drug_exposure_raw as
select person_id, gender_concept_id, drug_concept_id, year_of_birth, syear, smonth, sday, 
	cast(concat_ws('-', cast(syear as string), lpad(cast(smonth as string), 2, '0'), lpad(cast(sday as string), 2, '0')) as timestamp) as sdate,
	eyear, emonth, eday, 
	cast(concat_ws('-', cast(eyear as string), lpad(cast(emonth as string), 2, '0'), lpad(cast(eday as string), 2, '0')) as timestamp) as edate
from 
 (
	select p.person_id, p.gender_concept_id, op.drug_concept_id,
	   cast(p.YEAR_OF_BIRTH as int) as year_of_birth, 
	   cast(regexp_extract(drug_exposure_start_date, '/(\\d+)$', 1) as int) as syear,
	   cast(regexp_extract(drug_exposure_start_date, '^(\\d+)/', 1) as int) as smonth,
	   cast(regexp_extract(drug_exposure_start_date, '/(\\d+)/', 1) as int) as sday,
	   cast(regexp_extract(drug_exposure_end_date, '/(\\d+)$', 1) as int) as eyear,
	   cast(regexp_extract(drug_exposure_end_date, '^(\\d+)/', 1) as int) as emonth,
	   cast(regexp_extract(drug_exposure_end_date, '/(\\d+)/', 1) as int) as eday
	from PERSON p join drug_exposure op on p.person_id = op.person_id
 ) t
;


-- 700   Number of persons with at least one drug occurrence, by drug_concept_id
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 700 as analysis_id, 
   cast(de1.drug_CONCEPT_ID as string) as stratum_1,
   count(distinct de1.PERSON_ID) as count_value
from drug_exposure de1
group by de1.drug_CONCEPT_ID
;


-- 701   Number of drug occurrence records, by drug_concept_id
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 701 as analysis_id, 
   cast(de1.drug_CONCEPT_ID as string) as stratum_1,
   count(de1.PERSON_ID) as count_value
from drug_exposure de1
group by de1.drug_CONCEPT_ID
;


-- 702   Number of persons by drug occurrence start month, by drug_concept_id
insert into ACHILLES_results (analysis_id, stratum_1, stratum_2, count_value)
select 702 as analysis_id,   
   cast(de1.drug_concept_id as string) as stratum_1,
   cast(YEAR(cast(drug_exposure_start_date as timestamp))*100 + month(cast(drug_exposure_start_date as timestamp)) as string) as stratum_2, 
   count(distinct PERSON_ID) as count_value
from drug_exposure de1
group by de1.drug_concept_id, 
   YEAR(cast(drug_exposure_start_date as timestamp))*100 + month(cast(drug_exposure_start_date as timestamp))
;


-- 703   Number of distinct drug exposure concepts per person
insert into ACHILLES_results_dist (analysis_id, count_value, min_value, max_value, avg_value, stdev_value, median_value, p10_value, p25_value, p75_value, p90_value)
with rawData as
(
  select num_drugs as count_value
   from
   (
      select de1.person_id, count(distinct de1.drug_concept_id) as num_drugs
      from drug_exposure de1
      group by de1.person_id
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
select 703 as analysis_id,
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


-- 704   Number of persons with at least one drug occurrence, by drug_concept_id by calendar year by gender by age decile
insert into ACHILLES_results (analysis_id, stratum_1, stratum_2, stratum_3, stratum_4, count_value)
select 704 as analysis_id,   
   cast(de1.drug_concept_id as string) as stratum_1,
   cast(YEAR(cast(drug_exposure_start_date as timestamp)) as string) as stratum_2,
   cast(p1.gender_concept_id as string) as stratum_3,
   cast(floor((year(cast(drug_exposure_start_date as timestamp)) - p1.year_of_birth)/10) as string) as stratum_4, 
   count(distinct p1.PERSON_ID) as count_value
from PERSON p1
	inner join drug_exposure de1 on p1.person_id = de1.person_id
group by de1.drug_concept_id, 
   YEAR(cast(drug_exposure_start_date as timestamp)),
   p1.gender_concept_id,
   floor((year(cast(drug_exposure_start_date as timestamp)) - p1.year_of_birth)/10)
;


-- 705   Number of drug occurrence records, by drug_concept_id by drug_type_concept_id
insert into ACHILLES_results (analysis_id, stratum_1, stratum_2, count_value)
select 705 as analysis_id, 
   cast(de1.drug_CONCEPT_ID as string) as stratum_1,
   cast(de1.drug_type_concept_id as string) as stratum_2,
   count(de1.PERSON_ID) as count_value
from drug_exposure de1
group by de1.drug_CONCEPT_ID, de1.drug_type_concept_id
;


-- 706   Distribution of age by drug_concept_id
insert into ACHILLES_results_dist (analysis_id, stratum_1, stratum_2, count_value, min_value, max_value, avg_value, stdev_value, median_value, p10_value, p25_value, p75_value, p90_value)
with rawData as(
	select de1.drug_concept_id as subject_id,
	  p1.gender_concept_id,
	   de1.drug_start_year - p1.year_of_birth as count_value
	from PERSON p1
	inner join
	(
	   select person_id, drug_concept_id, min(year(cast(drug_exposure_start_date as timestamp))) as drug_start_year
	   from drug_exposure
	   group by person_id, drug_concept_id
	) de1 on p1.person_id = de1.person_id
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
select 706 as analysis_id,
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


-- 709   Number of drug exposure records with invalid person_id
insert into ACHILLES_results (analysis_id, count_value)
select 709 as analysis_id,  
   count(de1.PERSON_ID) as count_value
from drug_exposure de1
   left join PERSON p1 on p1.person_id = de1.person_id
where p1.person_id is null
;


-- 710   Number of drug exposure records outside valid observation period
insert into ACHILLES_results (analysis_id, count_value)
select 710 as analysis_id,  
   count(de1.PERSON_ID) as count_value
from drug_exposure de1
   left join observation_period op1
	   on op1.person_id = de1.person_id
	   and cast(de1.drug_exposure_start_date as timestamp) >= cast(op1.observation_period_start_date as timestamp)
	   and cast(de1.drug_exposure_start_date as timestamp) <= cast(op1.observation_period_end_date as timestamp)
where op1.person_id is null
;


-- 711   Number of drug exposure records with end date < start date
insert into ACHILLES_results (analysis_id, count_value)
select 711 as analysis_id,  
   count(de1.PERSON_ID) as count_value
from drug_exposure de1
where cast(de1.drug_exposure_end_date as string) < cast(de1.drug_exposure_start_date as string)
;


-- 712   Number of drug exposure records with invalid provider_id
insert into ACHILLES_results (analysis_id, count_value)
select 712 as analysis_id,  
   count(de1.PERSON_ID) as count_value
from drug_exposure de1
   left join provider p1 on p1.provider_id = de1.provider_id
where de1.provider_id is not null
   and p1.provider_id is null
;


-- 713   Number of drug exposure records with invalid visit_id
insert into ACHILLES_results (analysis_id, count_value)
select 713 as analysis_id,  
   count(de1.PERSON_ID) as count_value
from drug_exposure de1
   left join visit_occurrence vo1 on de1.visit_occurrence_id = vo1.visit_occurrence_id
where de1.visit_occurrence_id is not null and vo1.visit_occurrence_id is null
;


-- 715   Distribution of days_supply by drug_concept_id
insert into ACHILLES_results_dist (analysis_id, stratum_1, count_value, min_value, max_value, avg_value, stdev_value, median_value, p10_value, p25_value, p75_value, p90_value)
with rawData as
(
  select drug_concept_id as stratum_id,
      days_supply as count_value
   from drug_exposure 
   where days_supply is not null
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
select 715 as analysis_id,
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


-- 716   Distribution of refills by drug_concept_id
insert into ACHILLES_results_dist (analysis_id, stratum_1, count_value, min_value, max_value, avg_value, stdev_value, median_value, p10_value, p25_value, p75_value, p90_value)
with rawData as
(
  select drug_concept_id as stratum_id,
    refills as count_value
   from drug_exposure 
   where refills is not null
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
select 716 as analysis_id,
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


-- 717   Distribution of quantity by drug_concept_id
insert into ACHILLES_results_dist (analysis_id, stratum_1, count_value, min_value, max_value, avg_value, stdev_value, median_value, p10_value, p25_value, p75_value, p90_value)
with rawData as
(
  select drug_concept_id as stratum_id, quantity as count_value
  from drug_exposure 
   where quantity is not null
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
select 717 as analysis_id,
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


-- 720   Number of drug exposure records by condition occurrence start month
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 720 as analysis_id,   
   cast(YEAR(cast(drug_exposure_start_date as timestamp))*100 + month(cast(drug_exposure_start_date as timestamp)) as string) as stratum_1, 
   count(PERSON_ID) as count_value
from drug_exposure de1
group by YEAR(cast(drug_exposure_start_date as timestamp))*100 + month(cast(drug_exposure_start_date as timestamp))
;

