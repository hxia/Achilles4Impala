
/********************************************
ACHILLES Analyses on DRUG_ERA table
*********************************************/

-- create raw data table based on DRUG_ERA for query simplification
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


-- 900   Number of persons with at least one drug occurrence, by drug_concept_id
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 900 as analysis_id, 
   cast(de1.drug_CONCEPT_ID as string) as stratum_1,
   count(distinct de1.PERSON_ID) as count_value
from drug_era de1
group by de1.drug_CONCEPT_ID
;


-- 901   Number of drug occurrence records, by drug_concept_id
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 901 as analysis_id, 
   cast(de1.drug_CONCEPT_ID as string) as stratum_1,
   count(de1.PERSON_ID) as count_value
from drug_era de1
group by de1.drug_CONCEPT_ID
;


-- 902   Number of persons by drug occurrence start month, by drug_concept_id
insert into ACHILLES_results (analysis_id, stratum_1, stratum_2, count_value)
select 902 as analysis_id,   
   cast(de1.drug_concept_id as string) as stratum_1,
   cast(year(cast(drug_era_start_date as timestamp))*100 + month(cast(drug_era_start_date as timestamp)) as string) as stratum_2, 
   count(distinct PERSON_ID) as count_value
from drug_era de1
group by de1.drug_concept_id, 
	year(cast(drug_era_start_date as timestamp))*100 + month(cast(drug_era_start_date as timestamp))
;


-- 903   Number of distinct drug era concepts per person
insert into ACHILLES_results_dist (analysis_id, count_value, min_value, max_value, avg_value, stdev_value, median_value, p10_value, p25_value, p75_value, p90_value)
with rawData as
(
  select count(distinct de1.drug_concept_id) as count_value
   from drug_era de1
   group by de1.person_id
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
select 903 as analysis_id,
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


-- 904   Number of persons with at least one drug occurrence, by drug_concept_id by calendar year by gender by age decile
insert into ACHILLES_results (analysis_id, stratum_1, stratum_2, stratum_3, stratum_4, count_value)
select 904 as analysis_id,   
   cast(drug_concept_id as string) as stratum_1,
   cast(year(cast(drug_era_start_date as timestamp)) as string) as stratum_2,
   cast(gender_concept_id as string) as stratum_3,
   cast(floor(year(cast(drug_era_start_date as timestamp)) - year_of_birth)/10 as string) as stratum_4, 
   count(distinct p1.PERSON_ID) as count_value
from PERSON p1
	inner join drug_era de1 on p1.person_id = de1.person_id
group by drug_concept_id, 
	year(cast(drug_era_start_date as timestamp)), 
	gender_concept_id, 
	floor(year(cast(drug_era_start_date as timestamp)) - year_of_birth)/10
;


-- 906   Distribution of age by drug_concept_id
insert into ACHILLES_results_dist (analysis_id, stratum_1, stratum_2, count_value, min_value, max_value, avg_value, stdev_value, median_value, p10_value, p25_value, p75_value, p90_value)
with rawData as 
(
	select de.drug_concept_id as subject_id,
	  p1.gender_concept_id,
	  de.drug_start_year - p1.year_of_birth as count_value
	from PERSON p1
	inner join
	(
	   select person_id, drug_concept_id, min(year(cast(drug_era_start_date as timestamp))) as drug_start_year
	   from drug_era
	   group by person_id, drug_concept_id
	) de on p1.person_id =de.person_id
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
select 906 as analysis_id,
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


-- 907   Distribution of drug era length, by drug_concept_id
insert into ACHILLES_results_dist (analysis_id, stratum_1, count_value, min_value, max_value, avg_value, stdev_value, median_value, p10_value, p25_value, p75_value, p90_value)
with rawData as
(
  select drug_concept_id as stratum1_id, 
		datediff(cast(drug_era_end_date as timestamp), cast(drug_era_start_date as timestamp)) as count_value
  from drug_era de1
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
select 907 as analysis_id,
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


-- 908   Number of drug eras with invalid person
insert into ACHILLES_results (analysis_id, count_value)
select 908 as analysis_id,  
   count(de1.PERSON_ID) as count_value
from drug_era de1
   left join PERSON p1 on p1.person_id = de1.person_id
where p1.person_id is null
;


-- 909   Number of drug eras outside valid observation period
insert into ACHILLES_results (analysis_id, count_value)
select 909 as analysis_id,
   count(de1.PERSON_ID) as count_value
from
   drug_era de1
   left join observation_period op1
   on op1.person_id = de1.person_id
   and cast(de1.drug_era_start_date as timestamp) >= cast(op1.observation_period_start_date as timestamp)
   and cast(de1.drug_era_start_date as timestamp) <= cast(op1.observation_period_end_date as timestamp)
where op1.person_id is null
;


-- 910   Number of drug eras with end date < start date
insert into ACHILLES_results (analysis_id, count_value)
select 910 as analysis_id,
   count(de1.PERSON_ID) as count_value
from
   drug_era de1
where cast(de1.drug_era_end_date as timestamp) < cast(de1.drug_era_start_date as timestamp)
;


-- 920   Number of drug era records by drug era start month
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 920 as analysis_id,   
   cast(year(cast(drug_era_start_date as timestamp))*100 + month(cast(drug_era_start_date as timestamp)) as string) as stratum_1, 
   count(PERSON_ID) as count_value
from drug_era de1
group by year(cast(drug_era_start_date as timestamp))*100 + month(cast(drug_era_start_date as timestamp))
;

