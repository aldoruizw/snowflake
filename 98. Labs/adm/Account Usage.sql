--The following queries can be useful to identify issues in your environment.  We're going to be using the account_usage schema in the Snowflake database, so there can be some latency for some views.

--set context
--by default access to the snowflake database is restricted to the account admin role.  To grant access to other roles, you can use the following syntax:
--GRANT IMPORTED PRIVILEGES ON DATABASE snowflake TO ROLE [customrole1];
--in our class account, we have access to the snowflake database
use database snowflake;
use schema account_usage;
 
--About queries
--longest running queries
select   query_id
, query_type
, warehouse_size
, total_elapsed_time
, bytes_spilled_to_local_storage
, bytes_spilled_to_remote_storage
, query_load_percent
from query_history
order by total_elapsed_time desc
;

--queries with spillage by warehouse/warehouse size
select  
  warehouse_name
, warehouse_size
, query_id
, query_type
, total_elapsed_time
, bytes_spilled_to_local_storage
, bytes_spilled_to_remote_storage
, query_load_percent
from query_history
where bytes_spilled_to_local_storage > 0
order by warehouse_name, warehouse_size desc
;

--query on users per warehouse and cache usage
select 
    warehouse_name
    ,warehouse_size
    ,count(distinct user_name)
    ,count(query_id) as number_of_queries
    ,sum(percentage_scanned_from_cache) as cache_usage
from query_history
where start_time >= date_trunc(month, current_date)
group by warehouse_name, warehouse_size 
order by cache_usage;

--average query execution time by query type and warehouse size (month-to-date)
select query_type,
       warehouse_size,
       avg(execution_time/1000) as average_execution_time_in_sec
from query_history
where start_time >= date_trunc(month, current_date)
and warehouse_size is not null
group by 1,2
order by 3 desc;

--obtain a query count for every login
select l.user_name,
       l.event_timestamp as login_time,
       l.client_ip,
       l.reported_client_type,
       l.first_authentication_factor,
       l.second_authentication_factor,
       count(q.query_id)
from snowflake.account_usage.login_history l
join snowflake.account_usage.sessions s on l.event_id = s.login_event_id
join snowflake.account_usage.query_history q on q.session_id = s.session_id
group by 1,2,3,4,5,6
order by l.user_name
;

--most expensive queries
WITH
filtered_queries AS (
    SELECT
        query_id,
        query_text AS original_query_text,

        -- First, we remove comments enclosed by /* <comment text> */
        REGEXP_REPLACE(query_text, '(/\*.*\*/)') AS _cleaned_query_text,
        -- Next, removes single line comments starting with --
        -- and either ending with a new line or end of string
        REGEXP_REPLACE(_cleaned_query_text, '(--.*$)|(--.*\n)') AS cleaned_query_text,
        warehouse_id,
        TIMEADD(
            'millisecond',
            queued_overload_time + compilation_time +
            queued_provisioning_time + queued_repair_time +
            list_external_files_time,
            start_time
        ) AS execution_start_time,
        end_time
    FROM snowflake.account_usage.query_history AS q
    WHERE TRUE
        AND warehouse_size IS NOT NULL
        AND start_time >= DATEADD('day', -30, DATEADD('day', -1, CURRENT_DATE))
),
-- 1 row per hour from 30 days ago until the end of today
hours_list AS (
    SELECT
        DATEADD(
            'hour',
            '-' || row_number() over (order by null),
            DATEADD('day', '+1', CURRENT_DATE)
        ) as hour_start,
        DATEADD('hour', '+1', hour_start) AS hour_end
    FROM TABLE(generator(rowcount => (24*31))) t
),
-- 1 row per hour a query ran
query_hours AS (
    SELECT
        hl.hour_start,
        hl.hour_end,
        queries.*
    FROM hours_list AS hl
    INNER JOIN filtered_queries AS queries
        ON hl.hour_start >= DATE_TRUNC('hour', queries.execution_start_time)
        AND hl.hour_start < queries.end_time
),
query_seconds_per_hour AS (
    SELECT
        *,
        DATEDIFF('millisecond', GREATEST(execution_start_time, hour_start), LEAST(end_time, hour_end)) AS num_milliseconds_query_ran,
        SUM(num_milliseconds_query_ran) OVER (PARTITION BY warehouse_id, hour_start) AS total_query_milliseconds_in_hour,
        num_milliseconds_query_ran/total_query_milliseconds_in_hour AS fraction_of_total_query_time_in_hour,
        hour_start AS hour
    FROM query_hours
),
credits_billed_per_hour AS (
    SELECT
        start_time AS hour,
        warehouse_id,
        credits_used_compute
    FROM snowflake.account_usage.warehouse_metering_history
),
query_cost AS (
    SELECT
        query.*,
        credits.credits_used_compute*2.28 AS actual_warehouse_cost,
        credits.credits_used_compute*fraction_of_total_query_time_in_hour*2.28 AS query_allocated_cost_in_hour
    FROM query_seconds_per_hour AS query
    INNER JOIN credits_billed_per_hour AS credits
        ON query.warehouse_id=credits.warehouse_id
        AND query.hour=credits.hour
),
cost_per_query AS (
    SELECT
        query_id,
        ANY_VALUE(MD5(cleaned_query_text)) AS query_signature,
        SUM(query_allocated_cost_in_hour) AS query_cost,
        ANY_VALUE(original_query_text) AS original_query_text,
        ANY_VALUE(warehouse_id) AS warehouse_id,
        SUM(num_milliseconds_query_ran) / 1000 AS execution_time_s
    FROM query_cost
    GROUP BY 1
)
SELECT
    query_signature,
    COUNT(*) AS num_executions,
    AVG(query_cost) AS avg_cost_per_execution,
    SUM(query_cost) AS total_cost_last_30d,
    ANY_VALUE(original_query_text) AS sample_query_text
FROM cost_per_query
GROUP BY 1
limit 25;


--Long running tasks
SELECT DATEDIFF(seconds, query_start_time,completed_time) AS duration_seconds,*
FROM snowflake.account_usage.task_history
WHERE state = 'SUCCEEDED'
  AND query_start_time >= DATEADD (week, -1, CURRENT_TIMESTAMP())
ORDER BY duration_seconds DESC;


--Warehouse usage
--credits used by each warehouse in your account 
select warehouse_name,
       sum(credits_used) as total_credits_used
from warehouse_metering_history
group by 1
order by 2 desc
;

--Timing distribution of queries for a particular warehouse
SELECT
  CASE
    WHEN Q.total_elapsed_time <= 1000 THEN 'Less than 1 second'
    WHEN Q.total_elapsed_time <= 6000 THEN '1 second to 1 minute'
    WHEN Q.total_elapsed_time <= 30000 THEN '1 minute to 5 minutes'
    ELSE 'more than 5 minutes'
  END AS BUCKETS,
  COUNT(query_id) AS number_of_queries
FROM snowflake.account_usage.query_history Q
WHERE TO_DATE(Q.START_TIME) > DATEADD(month,-1,TO_DATE(CURRENT_TIMESTAMP()))
  AND total_elapsed_time > 0
  AND warehouse_name = '<your_warehouse_name>'
GROUP BY 1;


--find warehouses that do not have auto resume

show warehouses;
select * from table(result_scan(last_query_id()))
where 'AUTO_RESUME' = false or
'AUTO_SUSPEND' is null ;

--check for warehouses that are using more credits than the average for the last seven days
select warehouse_name, date(start_time) as date, 
sum(credits_used) as credits_used,
avg(sum(credits_used)) over (partition by warehouse_name order by date rows 7 preceding) as credits_used_7_day_avg,
(to_numeric(sum(credits_used)/credits_used_7_day_avg*100,10,2)-100)::string || '%' as variance_to_7_day_average
from snowflake.account_usage.warehouse_metering_history
group by date, warehouse_name
order by variance_to_7_day_average desc;

--credits used over time by each warehouse in your account
select start_time::date as usage_date,
       warehouse_name,
       sum(credits_used) as total_credits_used
from warehouse_metering_history
where start_time >= date_trunc(month, current_date)
group by 1,2
order by 2,1
;

--total queries executed by all warehouses in your account (month-to-date)
select count(*) as number_of_queries
from query_history
where start_time >= date_trunc(month, current_date);

--total queries executed per warehouse (month-to-date)
select warehouse_name,
       count(*) as number_of_queries
from query_history
where start_time >= date_trunc(month, current_date)
and warehouse_name is not null
group by 1
order by 2 desc;

-- find warehouses without resource monitors
show warehouses;
select * from table(result_scan(last_query_id()))
where 'resource_monitor' = 'null';

--detect warehouse queueing delays
SELECT start_time, warehouse_name,
       AVG(avg_running) AS avg_running,
       AVG(avg_queued_load) AS avg_queued_load,
       AVG(avg_queued_provisioning) AS avg_provisioning_delay
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY
WHERE start_time > DATEADD(day, -7, CURRENT_TIMESTAMP())
GROUP BY start_time, warehouse_name
ORDER BY avg_queued_load DESC
LIMIT 10;

--warehouse workload queries
--set context 
use arch_role
use warehouse instructor1_arch_wh;
use schema instructor1_arch_db;

--create runctions used in future queries
-- Format as bytes (1 decimal place)
CREATE OR REPLACE FUNCTION public.format_bytes (BYTES float)
  returns varchar
  language javascript
as
// Converts bytes into 50TB or 50GB or 50MB or 50K
// Used to format a number of bytes into human readable form
$$
var tb = 1024*1024*1024*1024;
var gb = 1024*1024*1024;
var mb = 1024*1024;
var kb = 1024;
var out = '';

if (BYTES > tb)  {
   out = out.concat(Math.trunc(BYTES/tb), 'TB');
} else if (BYTES > gb)  {
   out = out.concat(Math.trunc(BYTES/gb), 'GB');
} else if (BYTES > mb)  {
   out = out.concat(Math.trunc(BYTES/mb), 'MB');
} else if (BYTES > kb)  {
   out = out.concat(Math.trunc(BYTES/kb), 'KB');   
} else {
   out = Math.trunc(BYTES);
}
return out;
$$;

-- Format as NUMBER (1 decimal place)
CREATE OR REPLACE FUNCTION public.format_number (row_count number)
returns varchar
comment = 'Formats a numeric NUMBER into T, B, M or K'
as
'select
       case
         when row_count >= power(10, 12) then to_char(round(row_count / power(10, 12), 1)) || '' Trillion''
         when row_count >= power(10, 9)  then to_char(round(row_count / power(10, 9), 1))  || '' Billion''
         when row_count >= power(10, 6)  then to_char(round(row_count / power(10, 6), 1))  || '' Million''
         when row_count >= power(10, 3)  then to_char(round(row_count / power(10, 3), 1))  || '' K''
           else to_char(row_count)
        end as r_count'
;


-- Milliseconds to Time
--  Converts a number of milliseconds seconds into HH:MM:SS

CREATE OR REPLACE FUNCTION public.mseconds_to_time(MSECONDS double)
  returns varchar
  language javascript
as
// Converts a number of seconds into h:m:s
// Used to format a number of seconds into an elapsed time in human readable form
$$
var secs     = Math.trunc(MSECONDS / 1000);
var hrs       = Math.trunc(secs /60/60);
var mins    = Math.trunc((secs - (hrs*60*60))/60);
var f_secs  = Math.trunc((secs - (hrs*60*60))-mins*60);
var time     = '';

if (hrs > 0)  {
   time = time.concat(hrs, 'h ', mins, 'm ', f_secs,'s');
} else if (mins > 0)  {
      time = time.concat(mins, 'm ', f_secs,'s');
} else if (secs > 0)  {
   time = time.concat(secs,'s');
} else {
   time = time.concat(MSECONDS,'ms');
}
return time;
$$;

-- Credits Per Hour
-- Returns the number of nodes depending upon warehouse size

CREATE OR REPLACE FUNCTION public.credits_per_hour(SIZE varchar)
  returns double
  language javascript
as
// Returns the credits per hour charge for a given warehouse size
// eg. utl.node_count('4XLARGE') returns 128
$$
var size  = SIZE.toUpperCase();

if (size == 'X-SMALL')  {
   return 1;
} else if (size == 'SMALL')  {
   return 2;
} else if (size == 'MEDIUM')  {
   return 4;
} else if (size == 'LARGE')  {
   return 8;
} else if (size == 'X-LARGE')  {
   return 16;
} else if (size == '2X-LARGE')  {
   return 32;
} else if (size == '3X-LARGE')  {
   return 64;
} else if (size == '4X-LARGE')  {
   return 128;
} else if (size == '5X-LARGE')  {
   return 256;
} else if (size == '6X-LARGE')  {
   return 512;
} else {
   return 0;
}
$$;

--Measuring used and idle time
with agg as(
select
    start_time::date    as start_date,
    warehouse_name,
    sum(credits_used)   as credits_total,
    sum(credits_attributed_compute_queries) as credits_attributed,
    sum(credits_used_cloud_services)    as credits_cloud
from snowflake.account_usage.warehouse_metering_history
group by 1,2
)
select 
    start_date,
    warehouse_name,
    round(credits_total * 3,2)  as dollars_billed,
    round(credits_attributed * 3, 2) as dollars_billed_actual,
    round((credits_total - credits_attributed - credits_cloud) / credits_total) * 100,2) as pct_idle
from agg
order by start_date asc;


--Copy workloads - identifying large files
SELECT TABLE_catalog_name           AS database
,      table_schema_name            AS schema_name
,      file_name
,      table_name                   AS table_name
,      status
,      format_bytes(SUM(file_size)) AS total_file_size
,      file_size                    as File_size_bytes
FROM   snowflake.account_usage.copy_history
WHERE  status in ('Loaded', 'Partially loaded')
AND    pipe_name is null -- Ignore Snowpipe
GROUP BY 1, 2, 3,4,5,8
ORDER BY database, File_size_bytes desc;

--Copy workloads - time taken to load
with loaded_files 
as (
    select distinct file_name , file_size
    from snowflake.account_usage.copy_history
    where  status in ('loaded', 'partially loaded')
    and    pipe_name is null -- ignore snowpipe
    and file_size >= 250000000
),
file_queries as (
    select
        t2.file_name as loaded_filename_match,
        t2.file_size/(1024*1024) as file_size_mb,
        t1.query_id,
        t1.query_tag,
      --  t1.start_time,
        t1.user_name,
        t1.total_elapsed_time / 1000 as elapsed_time_sec,
        t1.warehouse_name
    from
        snowflake.account_usage.query_history t1,
        loaded_files t2
    where
        t1.start_time >= dateadd(day, -30, current_timestamp())
        and t1.query_text ilike ('%' || t2.file_name || '%')
        and t1.query_type in ('select', 'insert', 'copy')
        and t1.query_tag = 'job_load_lineitem_all'
)
select *
from file_queries
order by elapsed_time_sec desc;

--copy workload cost and utilization
with agg as (
  select
    start_time,
    warehouse_name,
    sum(credits_used)                       as credits_total,      -- compute + cloud svcs
    sum(credits_attributed_compute_queries) as credits_attributed, -- productive compute
    sum(credits_used_cloud_services)        as credits_cloud       -- cloud svcs
  from snowflake.account_usage.warehouse_metering_history
  group by all
)
select
  start_time,
  warehouse_name,
  round(credits_total * 3, 2)                                              as dollars_billed,
  round(credits_attributed * 3, 2)                                         as dollars_billed_actual,
  round( (credits_total - credits_attributed - credits_cloud) * 3, 2)      as dollars_billed_idle,
  -- % idle of total billed (compute + cloud)
  round( nullifzero((credits_total - credits_attributed - credits_cloud) / credits_total) * 100, 2)
                                                                           as pct_idle,
from agg
where warehouse_name = 'arch_xs'
order by start_time desc ;

--automated workloads - key metrics
select query_tag 
, 	warehouse_name 
, 	warehouse_size 
, 	count(*) as count_queries 
, 	mseconds_to_time(median(total_elapsed_time)) as median_elapsed_time 
, 	mseconds_to_time(percentile_cont(.90) within group(order by total_elapsed_time)) as p90_elapsed 
, 	format_bytes(median(bytes_scanned)) as median_bytes_scanned 
, 	format_bytes(avg(bytes_spilled_to_local_storage))  avg_spilled_to_local_storage 
, 	format_bytes(avg(bytes_spilled_to_remote_storage)) avg_spilled_to_remote_storage 
from snowflake.account_usage.query_history
where warehouse_size is not null
and query_tag is not null
group by 1, 2, 3
order by query_tag, warehouse_name;


-- Serverless compute credits
select date_trunc(month, wmh.usage_date) as Month,
       sum(decode(service_type,
                 'PIPE', credits_billed)) as pipe_credits,
       sum(decode(service_type,
                 'MATERIALIZED_VIEW', credits_billed)) as Snowpipe,
       sum(decode(service_type,
                 'AUTO_CLUSTERING', credits_billed)) as Automatic_Clustering,
        sum(decode(service_type, 
                'CORTEX_CODE_SNOWSIGHT',credits_billed)) as Wnowsight_CoCo,
        sum(decode(service_type, 
                'AI_SERVICES',credits_billed)) as AI_Services,
        sum(decode(service_type, 
                'CORTEX_AGENTS',credits_billed)) as Cortex_Agents,
        sum(decode(service_type, 
                'CORTEX_CODE_CLI',credits_billed)) as Cortex_Code_CLI,
        sum(decode(service_type, 
                'SNOWFLAKE_INTELLIGENCE',credits_billed)) as Snowflake_CoWork,             sum(decode(service_type, 
                'AI_INFERENCE',credits_billed)) as AI_Inference,   
        sum(decode(service_type, 
                'WAREHOUSE_METERING_READER', credits_billed)) as Reader_credits,
        sum(decode(service_type,
                 'SEARCH_OPTIMIZATION', credits_billed)) as Search_optimization,
      sum(decode(service_type,
                 'QUERY_ACCELERATION', credits_billed)) as query_acceleration,
        sum(decode(service_type,
                 'REPLICATION', credits_billed)) as Replication,
        sum(decode(service_type,
                 'SERVERLESS_TASK', credits_billed)) as Serverless_tasks
from snowflake.account_usage.metering_daily_history wmh
where wmh.usage_date >= dateadd(month, -12, current_date())
group by date_trunc(month,wmh.usage_date)
order by date_trunc(month,wmh.usage_date);

-- Storage
--billable terabytes stored in your account over time:
select date_trunc(month, usage_date) as usage_month
  , avg(storage_bytes + stage_bytes + failsafe_bytes) / power(1024, 4) as billable_tb
from storage_usage
group by 1
order by 1;


--get overall storage metrics
select * 
from instructor1_db.information_schema.table_storage_metrics
; 

--storage per database per day
select du.usage_date,  
tsm.table_catalog as database_name,
su.stage_bytes /  (1024 * 1024 * 1024) as stage_gb, 
sum(tsm.active_bytes + tsm.failsafe_bytes + tsm.time_travel_bytes + tsm.retained_for_clone_bytes) / (1024 * 1024 * 1024) as table_storage_gb, 
sum(tsm.active_bytes) /  (1024 * 1024 * 1024) as active_gb, 
sum(tsm.failsafe_bytes) /  (1024 * 1024 * 1024) as failsafe_gb, 
sum(tsm.time_travel_bytes) /  (1024 * 1024 * 1024) as timetravel_gb,
sum(tsm.retained_for_clone_bytes) /  (1024 * 1024 * 1024) as retained_for_cloned_gb  
from snowflake.account_usage.database_storage_usage_history as du
join snowflake.account_usage.storage_usage as su on du.usage_date = su.usage_date
left join snowflake.account_usage.table_storage_metrics as tsm
on du.database_id = tsm.table_catalog_id //joining through the database id
group by tsm.table_catalog,du.usage_date, su.stage_bytes  
order by du.usage_date;




--get total, clone, time travel and failsafe bytes for tables
with failsafe as
  (
    select sum(failsafe_bytes) as bytes
    from snowflake.account_usage.table_storage_metrics 
    where table_entered_failsafe is not null
  ),
  Active as 
  (
    select sum(active_bytes) as bytes
    from snowflake.account_usage.table_storage_metrics 
    where table_entered_failsafe is null
  ),
  time_travel as 
  (
    select sum(time_travel_bytes) as bytes
    from snowflake.account_usage.table_storage_metrics
  ),
  clones as 
    (select active_bytes as bytes
    from snowflake.account_usage.table_storage_metrics 
    where id <> clone_group_id)
SELECT
   active.bytes as All_Storage,
   clones.bytes as Clone_Storage,
   time_travel.bytes as TT_Storage,
   failsafe.bytes as Failsafe_Storage
FROM
   active,
   clones,
   time_travel,
   failsafe
   limit 1;
   
--find storage metrics for each internal stage in a schema
declare
  res RESULTSET;
  rpt VARIANT;
  name VARCHAR;
  err varchar := '';
  total_size NUMBER;
  res_query VARCHAR DEFAULT 'select KEY STAGE_NAME,VALUE TOTAL_BYTES from table(flatten(parse_json(?))) order by 2 DESC';
  c1 cursor for select concat_ws( '.', stage_catalog, stage_schema, stage_name ) name 
                 from snowflake.account_usage.stages 
                 where stage_type = 'Internal Named' and deleted is NULL;
begin
  rpt := object_construct();
  for record in c1 do
      begin
          name := record.name;
          res := (execute immediate 'ls @' || name);
          let c2 cursor for res;
          total_size := 0;
          for inner_record in c2 do
              begin
                  total_size := total_size + inner_record."size";
              EXCEPTION 
                  WHEN OTHER THEN
                      err := concat_ws('\n', err , SQLERRM );
              end;
           end for;
           rpt := object_insert( rpt, name, total_size );
      EXCEPTION 
          WHEN OTHER THEN
              err := concat_ws('\n', err , SQLERRM );
      end;
  end for;
  res := (execute immediate :res_query using (rpt));
  return table(res);
  --return err;
end;

-- Logins by User
select
    user_name,
    sum(iff(is_success = 'NO', 1, 0)) as Failed,
    count(*) as Success,
    sum(iff(is_success = 'NO', 1, 0)) / nullif(count(*), 0) as login_failure_rate
from
    snowflake.account_usage.login_history
where
    event_timestamp = :daterange
group by
    1
order by
    4 desc;

-- Logins by Client
select
    reported_client_type as Client,
    user_name,
    sum(iff(is_success = 'NO', 1, 0)) as Failed,
    count(*) as Success,
    sum(iff(is_success = 'NO', 1, 0)) / nullif(count(*), 0) as login_failure_rate
from
    snowflake.account_usage.login_history
where
    event_timestamp = :daterange
group by
    1,
    2
order by
    5 desc;



--unused tables
--dml from the information schema to identify table sizes and last updated timestamps
select table_catalog || '.' || table_schema || '.' || table_name as table_path, 
    table_name, table_schema as schema,
    table_catalog as database, bytes,
    to_number(bytes / power(1024,3),10,2) as gb, 
    last_altered as last_use,
    datediff('day',last_use,current_date) as days_since_last_use
from information_schema.tables
where days_since_last_use > 90 --use your days threshold
order by bytes desc;
 
-- last dml on object
select (system$last_change_commit_time(
[database].[schema].[table_name])/1000)::timestamp_ntz;


 
-- queries on object in last nn days
select count(*) from snowflake.account_usage.query_history
where contains(upper(query_text),['table_name'])
and datediff('day',start_time,current_date) < 90;
 
-- last query on object in last nn days
set table_name = '[my_table]';
 
select start_time, query_id, query_text
from snowflake.account_usage.query_history
where contains(upper(query_text),$table_name) 
and query_id = (
     select top 1 query_id 
     from snowflake.account_usage.query_history
     where contains(upper(query_text),$table_name)
     order by start_time desc)
and datediff('day',start_time,current_date) < 90;
 
-- object used in a view definition in last nn days
select * from information_schema.views
where contains(view_definition,'[table_name]')
and datediff('day',last_altered,current_date) < 90;

--dormant users
--never logged in users
select *
from users
where last_success_login is null
and datediff('day', created_on, current_date())>30;

--Stale Users

select *
from users 
where last_success_login > (current_date() - 30);




