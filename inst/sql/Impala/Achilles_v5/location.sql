
/********************************************
ACHILLES Analyses on LOCATION table
*********************************************/

-- 1100   Number of persons by location 3-digit zip
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 1100 as analysis_id,  
   substr(l1.zip, 1, 3) as stratum_1, count(distinct person_id) as count_value
from PERSON p1
   inner join `LOCATION` l1 on p1.location_id = l1.location_id
where p1.location_id is not null and l1.zip is not null
group by substr(l1.zip, 1, 3);


-- 1101   Number of persons by location state
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 1101 as analysis_id,  
   l1.state as stratum_1, count(distinct person_id) as count_value
from PERSON p1
   inner join `LOCATION` l1 on p1.location_id = l1.location_id
where p1.location_id is not null and l1.state is not null
group by l1.state;


-- 1102   Number of care sites by location 3-digit zip
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 1102 as analysis_id,  
   substr(l1.zip, 1, 3) as stratum_1, count(distinct care_site_id) as count_value
from care_site cs1
   inner join `LOCATION` l1 on cs1.location_id = l1.location_id
where cs1.location_id is not null and l1.zip is not null
group by substr(l1.zip, 1, 3);


-- 1103   Number of care sites by location state
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 1103 as analysis_id,  
   l1.state as stratum_1, count(distinct care_site_id) as count_value
from care_site cs1
   inner join `LOCATION` l1 on cs1.location_id = l1.location_id
where cs1.location_id is not null and l1.state is not null
group by l1.state;

