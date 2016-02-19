

drop table achilles_heel_results;

create table achilles_heel_results stored as parquet as
select * from achilles_heel_results_1
where 1=2
;


drop table achilles_results;

create table achilles_results stored as parquet as
select * from achilles_results_1
where 1=2
;


drop table achilles_results_dist;

create table achilles_results_dist stored as parquet as
select * from achilles_results_dist_1
where 1=2
;

invalidate metadata;

exit;



