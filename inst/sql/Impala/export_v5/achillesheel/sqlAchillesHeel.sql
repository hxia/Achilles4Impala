select analysis_id as AttributeName, ACHILLES_HEEL_warning as AttributeValue
from @results_database_schema.ACHILLES_HEEL_results
order by case when substr(ACHILLES_HEEL_warning, 1, 5) = 'Error' then 1 else 2 end, analysis_id