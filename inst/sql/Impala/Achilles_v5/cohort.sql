
/********************************************
  ACHILLES Analyses on COHORT table
*********************************************/

-- 1700   Number of records by cohort_concept_id
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 1700 as analysis_id, 
   cast(cohort_definition_id as string) as stratum_1, 
   count(subject_ID) as count_value
from cohort c1
group by cohort_definition_id
;


-- 1701   Number of records with cohort end date < cohort start date
insert into ACHILLES_results (analysis_id, count_value)
select 1701 as analysis_id, 
   count(subject_ID) as count_value
from cohort c1
where cast(c1.cohort_end_date  as timestamp) < cast(c1.cohort_start_date as timestamp)
;
