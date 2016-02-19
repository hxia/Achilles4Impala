
/*****************************************************************
ACHILLES Analyses on OBSERVATION_PERIOD table
******************************************************************/

-- 101   Number of persons by age, with age at first observation period
insert into ACHILLES_results (analysis_id, stratum_1, count_value)

select 101 as analysis_id,   
	cast(year(op1.index_date) - p1.YEAR_OF_BIRTH as string) as stratum_1, 
	count(p1.person_id) as count_value
from PERSON p1
   inner join (select person_id, MIN(cast(observation_period_start_date as timestamp)) as index_date from OBSERVATION_PERIOD group by PERSON_ID) op1
   on p1.PERSON_ID = op1.PERSON_ID
group by year(op1.index_date) - p1.YEAR_OF_BIRTH
;


-- 102   Number of persons by gender by age, with age at first observation period
insert into ACHILLES_results (analysis_id, stratum_1, stratum_2, count_value)
select 102 as analysis_id,  
	cast(p1.gender_concept_id as string) as stratum_1, 
	cast(year(op1.index_date) - p1.YEAR_OF_BIRTH as string) as stratum_2, 
	count(p1.person_id) as count_value
from PERSON p1
   inner join (select person_id, MIN(cast(observation_period_start_date as timestamp)) as index_date from OBSERVATION_PERIOD group by PERSON_ID) op1
   on p1.PERSON_ID = op1.PERSON_ID
group by p1.gender_concept_id, year(op1.index_date) - p1.YEAR_OF_BIRTH
;


-- 103   Distribution of age at first observation period
insert into ACHILLES_results_dist (analysis_id, count_value, min_value, max_value, avg_value, stdev_value, median_value, p10_value, p25_value, p75_value, p90_value)
with rawData as
( 
  select p.person_id,
		MIN(YEAR(cast(observation_period_start_date as timestamp))) - P.YEAR_OF_BIRTH as age_value
  from PERSON p
  JOIN OBSERVATION_PERIOD op on p.person_id = op.person_id
  group by p.person_id, p.year_of_birth
),
overallStats as
(
  select avg(1.0 * age_value) as avg_value,
  stddev(age_value) as stdev_value,
  min(age_value) as min_value,
  max(age_value) as max_value,
  count(*) as total
  from rawData
),
ageStats as
(
  select age_value, count(*) as total, row_number() over (order by age_value) as rn
  from rawData
  group by age_value
),
ageStatsPrior as
(
  select s.age_value, s.total, sum(p.total) as accumulated
  from ageStats s
  join ageStats p on p.rn <= s.rn
  group by s.age_value, s.total, s.rn
)
select 103 as analysis_id,
  o.total as count_value,
  o.min_value,
  o.max_value,
  cast(o.avg_value as float),
  cast(o.stdev_value as float),
  min(case when p.accumulated >= .50 * o.total then age_value end) as median_value,
  min(case when p.accumulated >= .10 * o.total then age_value end) as p10_value,
  min(case when p.accumulated >= .25 * o.total then age_value end) as p25_value,
  min(case when p.accumulated >= .75 * o.total then age_value end) as p75_value,
  min(case when p.accumulated >= .90 * o.total then age_value end) as p90_value
from ageStatsPrior p
cross join overallStats o
group by o.total, o.min_value, o.max_value, o.avg_value, o.stdev_value
;


-- 104   Distribution of age at first observation period by gender
insert into ACHILLES_results_dist (analysis_id, stratum_1, count_value, min_value, max_value, avg_value, stdev_value, median_value, p10_value, p25_value, p75_value, p90_value)
with rawData as
(
   select p.gender_concept_id, MIN(YEAR(cast(observation_period_start_date as timestamp))) - P.YEAR_OF_BIRTH as age_value
   from PERSON p
   JOIN OBSERVATION_PERIOD op on p.person_id = op.person_id
   group by p.person_id,p.gender_concept_id, p.year_of_birth
),
overallStats as
(
  select gender_concept_id,
    avg(1.0 *age_value) as avg_value,
    stddev(age_value) as stdev_value,
    min(age_value) as min_value,
    max(age_value) as max_value,
    count(*) as total
  from rawData
  group by gender_concept_id
),
ageStats as
(
  select gender_concept_id, age_value, count(*) as total, row_number() over (order by age_value) as rn
  from rawData
  group by gender_concept_id, age_value
),
ageStatsPrior as
(
  select s.gender_concept_id, s.age_value, s.total, sum(p.total) as accumulated
  from ageStats s
  join ageStats p on s.gender_concept_id = p.gender_concept_id and p.rn <= s.rn
  group by s.gender_concept_id, s.age_value, s.total, s.rn
)
select 104 as analysis_id,
  cast(o.gender_concept_id as string) as stratum_1,
  o.total as count_value,
  o.min_value,
  o.max_value,
  cast(o.avg_value as float),
  cast(o.stdev_value as float),
  min(case when p.accumulated >= .50 * o.total then age_value end) as median_value,
  min(case when p.accumulated >= .10 * o.total then age_value end) as p10_value,
  min(case when p.accumulated >= .25 * o.total then age_value end) as p25_value,
  min(case when p.accumulated >= .75 * o.total then age_value end) as p75_value,
  min(case when p.accumulated >= .90 * o.total then age_value end) as p90_value
from ageStatsPrior p
join overallStats o on p.gender_concept_id = o.gender_concept_id
group by o.gender_concept_id, o.total, o.min_value, o.max_value, o.avg_value, o.stdev_value
;


-- 105   Length of observation (days) of first observation period
insert into ACHILLES_results_dist (analysis_id, count_value, min_value, max_value, avg_value, stdev_value, median_value, p10_value, p25_value, p75_value, p90_value)
with rawData as
(
  select count_value
  FROM
  (
    select DATEDIFF(cast(op.observation_period_end_date as timestamp), cast(op.observation_period_start_date as timestamp)) as count_value,
       ROW_NUMBER() over (PARTITION by op.person_id order by op.observation_period_start_date asc) as rn
    from OBSERVATION_PERIOD op
   ) op
   where op.rn = 1
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
  select count_value, count(*) as total, row_number() over (order by count_value) as rn
  FROM
  (
    select DATEDIFF(cast(op.observation_period_end_date as timestamp), cast(op.observation_period_start_date as timestamp)) as count_value,
       ROW_NUMBER() over (PARTITION by op.person_id order by op.observation_period_start_date asc) as rn
    from OBSERVATION_PERIOD op
   ) op
  where op.rn = 1
  group by count_value
),
priorStats as
(
  select s.count_value, s.total, sum(p.total) as accumulated
  from status  s
  join status  p on p.rn <= s.rn
  group by s.count_value, s.total, s.rn
)
select 105 as analysis_id,
  o.total as count_value,
  o.min_value,
  o.max_value,
  cast(o.avg_value as float),
  cast(o.stdev_value as float),
  min(case when p.accumulated >= .50 * o.total then count_value end) as median_value,
  min(case when p.accumulated >= .10 * o.total then count_value end) as p10_value,
  min(case when p.accumulated >= .25 * o.total then count_value end) as p25_value,
  min(case when p.accumulated >= .75 * o.total then count_value end) as p75_value,
  min(case when p.accumulated >= .90 * o.total then count_value end) as p90_value
from priorStats p
cross join overallStats o
group by o.total, o.min_value, o.max_value, o.avg_value, o.stdev_value
;


-- 106   Length of observation (days) of first observation period by gender
insert into ACHILLES_results_dist (analysis_id, stratum_1, count_value, min_value, max_value, avg_value, stdev_value, median_value, p10_value, p25_value, p75_value, p90_value)
with rawData as
(
  select p.gender_concept_id, op.count_value
  FROM
  (
    select person_id, DATEDIFF(cast(op.observation_period_end_date as timestamp), cast(op.observation_period_start_date as timestamp)) as count_value,
      ROW_NUMBER() over (PARTITION by op.person_id order by op.observation_period_start_date asc) as rn
    from OBSERVATION_PERIOD op
   ) op
  JOIN PERSON p on op.person_id = p.person_id
   where op.rn = 1
),
overallStats as
(
  select gender_concept_id,
    avg(1.0 * count_value) as avg_value,
    stddev(count_value) as stdev_value,
    min(count_value) as min_value,
    max(count_value) as max_value,
    count(*) as total
  from rawData
  group by gender_concept_id
),
status  as
(
  select gender_concept_id, count_value, count(*) as total, row_number() over (order by count_value) as rn
  from rawData
  group by gender_concept_id, count_value
),
priorStats as
(
  select s.gender_concept_id, s.count_value, s.total, sum(p.total) as accumulated
  from status  s
  join status  p on s.gender_concept_id = p.gender_concept_id and p.rn <= s.rn
  group by s.gender_concept_id, s.count_value, s.total, s.rn
)
select 106 as analysis_id,
  cast(o.gender_concept_id as string),
  o.total as count_value,
  o.min_value,
  o.max_value,
  cast(o.avg_value as float),
  cast(o.stdev_value as float),
  min(case when p.accumulated >= .50 * o.total then count_value end) as median_value,
  min(case when p.accumulated >= .10 * o.total then count_value end) as p10_value,
  min(case when p.accumulated >= .25 * o.total then count_value end) as p25_value,
  min(case when p.accumulated >= .75 * o.total then count_value end) as p75_value,
  min(case when p.accumulated >= .90 * o.total then count_value end) as p90_value
from priorStats p
join overallStats o on p.gender_concept_id = o.gender_concept_id
group by o.gender_concept_id, o.total, o.min_value, o.max_value, o.avg_value, o.stdev_value
;


-- 107   Length of observation (days) of first observation period by age decile
insert into ACHILLES_results_dist (analysis_id, stratum_1, count_value, min_value, max_value, avg_value, stdev_value, median_value, p10_value, p25_value, p75_value, p90_value)
with rawData as
(
  select floor((year(cast(op.OBSERVATION_PERIOD_START_DATE as timestamp)) - p.YEAR_OF_BIRTH)/10) as age_decile,
    DATEDIFF(cast(op.observation_period_end_date as timestamp), cast(op.observation_period_start_date as timestamp)) as count_value
  FROM
  (
    select person_id,
        op.observation_period_start_date,
        op.observation_period_end_date,
        ROW_NUMBER() over (PARTITION by op.person_id order by op.observation_period_start_date asc) as rn
    from OBSERVATION_PERIOD op
  ) op
  JOIN PERSON p on op.person_id = p.person_id
  where op.rn = 1  
),
overallStats as
(
  select age_decile,
    avg(1.0 * count_value) as avg_value,
    stddev(count_value) as stdev_value,
    min(count_value) as min_value,
    max(count_value) as max_value,
    count(*) as total
  from rawData
  group by age_decile
),
status  as
(
  select age_decile,
    count_value, 
    count(*) as total, 
    row_number() over (order by count_value) as rn
  from rawData
  group by age_decile, count_value
),
priorStats as
(
  select s.age_decile, s.count_value, s.total, sum(p.total) as accumulated
  from status  s
  join status  p on s.age_decile = p.age_decile and p.rn <= s.rn
  group by s.age_decile, s.count_value, s.total, s.rn
)
select 107 as analysis_id,
  cast(o.age_decile as string),
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
join overallStats o on p.age_decile = o.age_decile
group by o.age_decile, o.total, o.min_value, o.max_value, o.avg_value, o.stdev_value
;


-- 108   Number of persons by length of observation period, in 30d increments
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 108 as analysis_id,  
	cast(floor(DATEDIFF(cast(op1.observation_period_end_date as timestamp), cast(op1.observation_period_start_date as timestamp))/30) as string) as stratum_1, 
	count(distinct p1.person_id) as count_value
from PERSON p1
   inner join
   (select person_id,
      OBSERVATION_PERIOD_START_DATE,
      OBSERVATION_PERIOD_END_DATE,
      ROW_NUMBER() over (PARTITION by person_id order by observation_period_start_date asc) as rn1
    from OBSERVATION_PERIOD
   ) op1
   on p1.PERSON_ID = op1.PERSON_ID
   where op1.rn1 = 1
group by floor(DATEDIFF(cast(op1.observation_period_end_date as timestamp), cast(op1.observation_period_start_date as timestamp))/30)
;


-- 109   Number of persons with continuous observation in each year
-- Fetched 0 row(s) in 2854.18s ?????
INSERT INTO ACHILLES_results (analysis_id, stratum_1, count_value)
with td as
(
	SELECT DISTINCT 
		YEAR(cast(observation_period_start_date as timestamp)) AS obs_year,
		CAST(concat_ws('-', cast(YEAR(cast(observation_period_start_date as timestamp)) as string), '01', '01') AS timestamp) AS obs_year_start,
		CAST(concat_ws('-', cast(YEAR(cast(observation_period_start_date as timestamp)) AS string), '12', '31') AS timestamp) AS obs_year_end
	FROM observation_period
)
SELECT
  109 AS analysis_id,
   cast(obs_year as string) AS stratum_1,
   count(DISTINCT person_id) AS count_value
FROM observation_period, td
WHERE
      cast(observation_period_start_date as timestamp) <= obs_year_start
   AND
      cast(observation_period_end_date as timestamp) >= obs_year_end
GROUP BY 
   obs_year
;


-- 110   Number of persons with continuous observation in each month
INSERT INTO ACHILLES_results (analysis_id, stratum_1, count_value)
with td as 
(
	SELECT DISTINCT YEAR(cast(observation_period_start_date as timestamp))*100 + MONTH(cast(observation_period_start_date as timestamp)) AS obs_month,
	  CAST(concat_ws('-', cast(YEAR(cast(observation_period_start_date as timestamp)) as string), lpad(cast(MONTH(cast(observation_period_start_date as timestamp)) as string), 2, '0'), '01') AS timestamp) AS obs_month_start,   
	  adddate(add_months(CAST(concat_ws('-', cast(YEAR(cast(observation_period_start_date as timestamp)) as string), lpad(cast(MONTH(cast(observation_period_start_date as timestamp)) as string), 2, '0'), '01') AS timestamp), 1), -1) AS obs_month_end
	FROM observation_period
)
SELECT 110 AS analysis_id, 
   cast(td.obs_month as string) AS stratum_1, 
   count(DISTINCT person_id) AS count_value
FROM observation_period op, td
WHERE cast(observation_period_start_date as timestamp) <= obs_month_start and  cast(observation_period_end_date as timestamp) >= obs_month_end
group by obs_month
;


-- 111   Number of persons by observation period start month
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 111 as analysis_id, 
	cast(YEAR(cast(observation_period_start_date as timestamp))*100 + MONTH(cast(observation_period_start_date as timestamp)) as string) as stratum_1, 
	count(distinct PERSON_ID) as count_value
from OBSERVATION_PERIOD_RAW 
group by YEAR(cast(observation_period_start_date as timestamp))*100 + MONTH(cast(observation_period_start_date as timestamp))
;


-- 112   Number of persons by observation period end month
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 112 as analysis_id,  
   cast(YEAR(cast(observation_period_end_date as timestamp))*100 + MONTH(cast(observation_period_end_date as timestamp)) as string) as stratum_1, 
   count(distinct PERSON_ID) as count_value
from observation_period 
group by YEAR(cast(observation_period_end_date as timestamp))*100 + MONTH(cast(observation_period_end_date as timestamp))
;


-- 113   Number of persons by number of observation periods
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 113 as analysis_id,
   cast(op1.num_periods as string) as stratum_1, 
   count(distinct op1.PERSON_ID) as count_value
from
   (select person_id, count(cast(OBSERVATION_period_start_date as timestamp)) as num_periods from OBSERVATION_PERIOD group by PERSON_ID) op1
group by op1.num_periods
;


-- 114   Number of persons with observation period before year-of-birth
insert into ACHILLES_results (analysis_id, count_value)
select 114 as analysis_id,
   count(distinct p1.PERSON_ID) as count_value
from
   PERSON p1
   inner join (select person_id, MIN(year(OBSERVATION_period_start_date)) as first_obs_year from OBSERVATION_PERIOD group by PERSON_ID) op1
   on p1.person_id = op1.person_id
where p1.year_of_birth > op1.first_obs_year
;


-- 115   Number of persons with observation period end < start
insert into ACHILLES_results (analysis_id, count_value)
select 115 as analysis_id,  count(op1.PERSON_ID) as count_value
from  observation_period op1
where cast(op1.observation_period_end_date as timestamp) < cast(op1.observation_period_start_date as timestamp)
;


-- 116   Number of persons with at least one day of observation in each year by gender and age decile
-- Fetched 0 row(s) in 2512.55s ???
insert into ACHILLES_results (analysis_id, stratum_1, stratum_2, stratum_3, count_value)
with t1 as 
(
	select distinct
	  YEAR(cast(observation_period_start_date as timestamp)) as obs_year
	from
	  OBSERVATION_PERIOD
)
select 116 as analysis_id,
        cast(t1.obs_year as string) as stratum_1,
        cast(p1.gender_concept_id as string) as stratum_2,
        cast(floor((t1.obs_year - p1.year_of_birth)/10) as string) as stratum_3,
        count(distinct p1.PERSON_ID) as count_value
from
        PERSON p1
        inner join
		observation_period op1
        on p1.person_id = op1.person_id
        ,
        t1
where year(cast(op1.OBSERVATION_PERIOD_START_DATE as timestamp)) <= t1.obs_year
        and year(cast(op1.OBSERVATION_PERIOD_END_DATE as timestamp)) >= t1.obs_year
group by t1.obs_year,
        p1.gender_concept_id,
        floor((t1.obs_year - p1.year_of_birth)/10)
;


-- 117   Number of persons with at least one day of observation in each year by gender and age decile
-- Fetched 0 row(s) in 2919.40s ???
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 117 as analysis_id,  
   cast(t1.obs_month as string) as stratum_1,
   count(distinct op1.PERSON_ID) as count_value
from
   observation_period op1,
   (select distinct YEAR(cast(observation_period_start_date as timestamp))*100 + month(cast(observation_period_start_date as timestamp)) as  obs_month 
    from observation_period) t1
where year(cast(op1.observation_period_start_date as timestamp))*100 + month(cast(op1.observation_period_start_date as timestamp)) <= t1.obs_month
   and YEAR(cast(observation_period_end_date as timestamp))*100 + MONTH(cast(observation_period_end_date as timestamp)) >= t1.obs_month
group by t1.obs_month
;


-- 118  Number of observation period records with invalid person_id
insert into ACHILLES_results (analysis_id, count_value)
select 118 as analysis_id,
  count(op1.PERSON_ID) as count_value
from
  observation_period op1
  left join PERSON p1
  on p1.person_id = op1.person_id
where p1.person_id is null
;
