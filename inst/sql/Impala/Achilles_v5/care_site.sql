
/********************************************
ACHILLES Analyses on CARE_SITE table
*********************************************/

-- 1200   Number of persons by place of service
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 1200 as analysis_id,  
   cast(cs1.place_of_service_concept_id as string) as stratum_1, count(person_id) as count_value
from PERSON p1
   inner join care_site cs1 on p1.care_site_id = cs1.care_site_id
where p1.care_site_id is not null and cs1.place_of_service_concept_id is not null
group by cs1.place_of_service_concept_id;


-- 1201   Number of visits by place of service
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 1201 as analysis_id,  
   cast(cs1.place_of_service_concept_id as string) as stratum_1, count(visit_occurrence_id) as count_value
from visit_occurrence vo1
   inner join care_site cs1 on vo1.care_site_id = cs1.care_site_id
where vo1.care_site_id is not null and cs1.place_of_service_concept_id is not null
group by cs1.place_of_service_concept_id;


-- 1202   Number of care sites by place of service
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 1202 as analysis_id,  
   cast(cs1.place_of_service_concept_id as string) as stratum_1, 
   count(care_site_id) as count_value
from care_site cs1
where cs1.place_of_service_concept_id is not null
group by cs1.place_of_service_concept_id;


