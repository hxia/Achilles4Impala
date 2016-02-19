
/*********************************************************
ACHILLES Analyses on PAYOR_PLAN_PERIOD table
**********************************************************/

-- 1406   Length of payer plan (days) of first payer plan period by gender
insert into ACHILLES_results_dist (analysis_id, stratum_1, count_value, min_value, max_value, avg_value, stdev_value, median_value, p10_value, p25_value, p75_value, p90_value)
with rawData as
(
  select p1.gender_concept_id as stratum1_id,
    DATEDIFF(cast(ppp1.payer_plan_period_end_date as timestamp), cast(ppp1.payer_plan_period_start_date as timestamp)) as count_value
  from PERSON p1
   inner join 
   (select person_id, 
      payer_plan_period_START_DATE, 
      payer_plan_period_END_DATE, 
      ROW_NUMBER() over (PARTITION by person_id order by payer_plan_period_start_date asc) as rn1
    from payer_plan_period
   ) ppp1
   on p1.PERSON_ID = ppp1.PERSON_ID
   where ppp1.rn1 = 1
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
select 1406 as analysis_id,
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


-- 1407   Length of payer plan (days) of first payer plan period by age decile
insert into ACHILLES_results_dist (analysis_id, stratum_1, count_value, min_value, max_value, avg_value, stdev_value, median_value, p10_value, p25_value, p75_value, p90_value)
with rawData as
(
  select floor((year(cast(ppp1.payer_plan_period_START_DATE as timestamp)) - p1.YEAR_OF_BIRTH)/10) as stratum_id,
    DATEDIFF(cast(ppp1.payer_plan_period_end_date as timestamp), cast(ppp1.payer_plan_period_start_date as timestamp)) as count_value
  from PERSON p1
   inner join 
   (select person_id, 
      payer_plan_period_START_DATE, 
      payer_plan_period_END_DATE, 
      ROW_NUMBER() over (PARTITION by person_id order by payer_plan_period_start_date asc) as rn1
       from payer_plan_period
   ) ppp1
   on p1.PERSON_ID = ppp1.PERSON_ID
   where ppp1.rn1 = 1
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
select 1407 as analysis_id,
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


-- 1408   Number of persons by length of payer plan period, in 30d increments
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 1408 as analysis_id,  
   cast(floor(DATEDIFF(cast(ppp1.payer_plan_period_end_date as timestamp), cast(ppp1.payer_plan_period_start_date as timestamp))/30) as string) as stratum_1, 
   count(distinct p1.person_id) as count_value
from PERSON p1
   inner join 
   (select person_id, 
      payer_plan_period_START_DATE, 
      payer_plan_period_END_DATE, 
      ROW_NUMBER() over (PARTITION by person_id order by payer_plan_period_start_date asc) as rn1
       from payer_plan_period
   ) ppp1
   on p1.PERSON_ID = ppp1.PERSON_ID
   where ppp1.rn1 = 1
group by floor(DATEDIFF(cast(ppp1.payer_plan_period_end_date as timestamp), cast(ppp1.payer_plan_period_start_date as timestamp))/30)
;


-- 1409   Number of persons with continuous payer plan in each year
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
with rawData as 
(
	select distinct YEAR(cast(payer_plan_period_start_date as timestamp)) as obs_year 
	from payer_plan_period
)
select 1409 as analysis_id,  
   cast(t1.obs_year as string) as stratum_1, count(distinct p1.PERSON_ID) as count_value
from
   PERSON p1 inner join payer_plan_period ppp1 on p1.person_id = ppp1.person_id,
   rawdata t1 
where year(cast(ppp1.payer_plan_period_START_DATE as timestamp)) <= t1.obs_year
   and year(cast(ppp1.payer_plan_period_END_DATE as timestamp)) >= t1.obs_year
group by t1.obs_year
;


-- 1410   Number of persons with continuous payer plan in each month
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
with rawData as
(
	SELECT DISTINCT 
	  YEAR(cast(payer_plan_period_start_date as timestamp))*100 + MONTH(cast(payer_plan_period_start_date as timestamp)) AS obs_month,
	  CAST(concat_ws('-', cast(YEAR(cast(payer_plan_period_start_date as timestamp)) as string), 
				lpad(cast(MONTH(cast(payer_plan_period_start_date as timestamp)) as string), 2, '0'), '01') as timestamp) AS obs_month_start,  
	  days_add(months_add(CAST(concat_ws('-', cast(YEAR(cast(payer_plan_period_start_date as timestamp)) as string), 
						lpad(cast(MONTH(cast(payer_plan_period_start_date as timestamp)) as string), 2, '0'), '01') as timestamp), 1), -1) AS obs_month_end
	FROM payer_plan_period
)
select 
  1410 as analysis_id, 
   cast(obs_month as string) as stratum_1, 
   count(distinct p1.PERSON_ID) as count_value
from PERSON p1
   inner join 
  payer_plan_period ppp1
   on p1.person_id = ppp1.person_id
   ,
   rawdata
where cast(ppp1.payer_plan_period_START_DATE as timestamp) <= obs_month_start
   and cast(ppp1.payer_plan_period_END_DATE as timestamp) >= obs_month_end
group by obs_month
;


-- 1411   Number of persons by payer plan period start month
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 1411 as analysis_id, 
   concat_ws('-', cast(YEAR(cast(payer_plan_period_start_date as timestamp)) as string), lpad(CAST(month(cast(payer_plan_period_START_DATE as timestamp)) as string), 2, '0'), '01') as stratum_1,
   count(distinct p1.PERSON_ID) as count_value
from PERSON p1
   inner join payer_plan_period ppp1
   on p1.person_id = ppp1.person_id
group by concat_ws('-', cast(YEAR(cast(payer_plan_period_start_date as timestamp)) as string), lpad(CAST(month(cast(payer_plan_period_START_DATE as timestamp)) as string), 2, '0'), '01') 
;


-- 1412   Number of persons by payer plan period end month
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 1412 as analysis_id,  
   concat_ws('-', cast(YEAR(cast(payer_plan_period_end_date as timestamp)) as string), lpad(cast(month(cast(payer_plan_period_end_DATE as timestamp)) as string), 2, '0'), '01' ) as stratum_1, 
   count(distinct p1.PERSON_ID) as count_value
from PERSON p1
   inner join payer_plan_period ppp1
   on p1.person_id = ppp1.person_id
group by concat_ws('-', cast(YEAR(cast(payer_plan_period_end_date as timestamp)) as string), lpad(cast(month(cast(payer_plan_period_end_DATE as timestamp)) as string), 2, '0'), '01')
;


-- 1413   Number of persons by number of payer plan periods
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 1413 as analysis_id,  
   cast(ppp1.num_periods as string) as stratum_1, 
   count(distinct p1.PERSON_ID) as count_value
from PERSON p1
   inner join (select person_id, count(payer_plan_period_start_date) as num_periods from payer_plan_period group by PERSON_ID) ppp1
   on p1.person_id = ppp1.person_id
group by ppp1.num_periods
;


-- 1414   Number of persons with payer plan period before year-of-birth
insert into ACHILLES_results (analysis_id, count_value)
select 1414 as analysis_id,  
   count(distinct p1.PERSON_ID) as count_value
from PERSON p1
   inner join (select person_id, min(year(cast(payer_plan_period_start_date as timestamp))) as first_obs_year from payer_plan_period group by PERSON_ID) ppp1
   on p1.person_id = ppp1.person_id
where p1.year_of_birth > ppp1.first_obs_year
;


-- 1415   Number of persons with payer plan period end < start
insert into ACHILLES_results (analysis_id, count_value)
select 1415 as analysis_id,  
   count(ppp1.PERSON_ID) as count_value
from
   payer_plan_period ppp1
where cast(ppp1.payer_plan_period_end_date as timestamp) < cast(ppp1.payer_plan_period_start_date as timestamp)
;

