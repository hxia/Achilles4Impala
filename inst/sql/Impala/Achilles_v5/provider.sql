
/********************************************
ACHILLES Analyses on PROVIDER table
*********************************************/

-- 300   Number of providers
insert into ACHILLES_results (analysis_id, count_value)
select 300 as analysis_id,  count(distinct provider_id) as count_value
from provider
;

-- 301   Number of providers by specialty concept_id
insert into ACHILLES_results (analysis_id, stratum_1, count_value)
select 301 as analysis_id,  specialty_concept_id as stratum_1, count(distinct provider_id) as count_value
from provider
group by specialty_CONCEPT_ID
;

-- 302   Number of providers with invalid care site id
insert into ACHILLES_results (analysis_id, count_value)
select 302 as analysis_id,  count(provider_id) as count_value
from provider p1
   left join care_site cs1
   on p1.care_site_id = cs1.care_site_id
where p1.care_site_id is not null
   and cs1.care_site_id is null
;

exit;
