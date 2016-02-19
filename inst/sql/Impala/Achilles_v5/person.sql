
/*******************************************************************
Achilles - database profiling summary statistics generation
SQL for OMOP CDM v5
*******************************************************************/

-- 0   Number of persons
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 0 as analysis_id,  'CMS' as stratum_1, count(distinct person_id) as count_value
from PERSON;

insert into ACHILLES_results_dist (analysis_id, stratum_1, count_value)
select 0 as analysis_id, 'CMS' as stratum_1, count(distinct person_id) as count_value
from PERSON;


/********************************************
ACHILLES Analyses on PERSON table
*********************************************/

-- 1   Number of persons
insert into ACHILLES_results (analysis_id, count_value)
select 1 as analysis_id,  count(distinct person_id) as count_value
from PERSON;


-- 2   Number of persons by gender
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 2 as analysis_id,  
	cast(gender_concept_id as string) as stratum_1, 
	count(distinct person_id) as count_value
from PERSON
group by GENDER_CONCEPT_ID;


-- 3   Number of persons by year of birth
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 3 as analysis_id,  
	cast(year_of_birth as string) as stratum_1, 
	count(distinct person_id) as count_value
from PERSON
group by YEAR_OF_BIRTH;


-- 4   Number of persons by race
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 4 as analysis_id,  
	cast(RACE_CONCEPT_ID as string) as stratum_1, 
	count(distinct person_id) as count_value
from PERSON
group by RACE_CONCEPT_ID;


-- 5   Number of persons by ethnicity
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 5 as analysis_id,  
	cast(ETHNICITY_CONCEPT_ID as string) as stratum_1, 
	count(distinct person_id) as count_value
from PERSON
group by ETHNICITY_CONCEPT_ID;


-- 7   Number of persons with invalid provider_id
insert into ACHILLES_results (analysis_id, count_value)
select 7 as analysis_id,  count(p1.person_id) as count_value
from PERSON p1
   left join provider pr1
   on p1.provider_id = pr1.provider_id
where p1.provider_id is not null
   and pr1.provider_id is null
;


-- 8   Number of persons with invalid location_id
insert into ACHILLES_results (analysis_id, count_value)
select 8 as analysis_id,  count(p1.person_id) as count_value
from PERSON p1
   left join location l1
   on p1.location_id = l1.location_id
where p1.location_id is not null
   and l1.location_id is null
;


-- 9   Number of persons with invalid care_site_id
insert into ACHILLES_results (analysis_id, count_value)
select 9 as analysis_id,  count(p1.person_id) as count_value
from PERSON p1
   left join care_site cs1
   on p1.care_site_id = cs1.care_site_id
where p1.care_site_id is not null
   and cs1.care_site_id is null
;

