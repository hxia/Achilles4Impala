select c2.concept_name as category,
	ard1.min_value as min_value,
	ard1.p10_value as P10_value,
	ard1.p25_value as P25_value,
	ard1.median_value as median_value,
	ard1.p75_value as P75_value,
	ard1.p90_value as P90_value,
	ard1.max_value as max_value
from @results_database_schema.ACHILLES_results_dist ard1
	inner join
	@cdm_database_schema.concept c2 on ard1.stratum_1 = CAST(c2.concept_id as VARCHAR)
where ard1.analysis_id = 506