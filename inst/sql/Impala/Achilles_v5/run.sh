
impala-shell -f start.sql -d omop

impala-shell -f person.sql -d omop

impala-shell -f observation_period.sql -d omop

impala-shell -f visit_occurrence.sql -d omop

impala-shell -f provider.sql -d omop

impala-shell -f condition_occurrence.sql -d omop

impala-shell -f death.sql -d omop

impala-shell -f procedure_occurrence.sql -d omop

impala-shell -f drug_exposure.sql -d omop

impala-shell -f observation.sql -d omop

impala-shell -f drug_era.sql -d omop

impala-shell -f condition_era.sql -d omop

impala-shell -f location.sql -d omop

impala-shell -f care_site.sql -d omop

impala-shell -f payer_plan_period.sql -d omop

impala-shell -f drug_cost.sql -d omop

impala-shell -f procedure_cost.sql -d omop

impala-shell -f cohort.sql -d omop

impala-shell -f measurement.sql -d omop

impala-shell -f AchillesHeel_v5.sql -d omop
