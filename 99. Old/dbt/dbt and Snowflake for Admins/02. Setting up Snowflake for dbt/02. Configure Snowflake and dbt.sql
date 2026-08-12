--02. Setting up Snowflake for dbt -> Configure Snowflake for dbt

use role SYSADMIN;
create database if not exists ANALYTICS;
create warehouse if not exists TRANSFORMING with warehouse_size = 'XSMALL';

use role SECURITYADMIN;
create role if not exists TRANSFORMER;

use role ACCOUNTADMIN;
grant imported privileges on database SNOWFLAKE_SAMPLE_DATA to role TRANSFORMER;
--grant usage on schema SNOWFLAKE_SAMPLE_DATA.TPCH_SF10 to role TRANSFORMER;
grant select on all tables in schema SNOWFLAKE_SAMPLE_DATA.TPCH_SF10 to role TRANSFORMER;

use role SYSADMIN;
grant usage on database ANALYTICS to role TRANSFORMER;
--grant reference_usage on database ANALYTICS to role TRANSFORMER;
grant modify on database ANALYTICS to role TRANSFORMER;
grant monitor on database ANALYTICS to role TRANSFORMER;
grant create schema on database ANALYTICS to role TRANSFORMER;

grant operate on warehouse TRANSFORMING to role TRANSFORMER;
grant usage on warehouse TRANSFORMING to role TRANSFORMER;

use role SECURITYADMIN;
grant role TRANSFORMER to user ARUIZ;

use role USERADMIN;
create user if not exists ARUIZ_2
--email = 'aldo.ruiz@dbtlabs.com'
password = 'Supersecret123!'
default_role = TRANSFORMER
default_warehouse = TRANSFORMING
--must_change_password = true
;

use role SECURITYADMIN;
grant role TRANSFORMER to user ARUIZ_2;

use role USERADMIN;
create user if not exists DBT_PROD
--email = 'dbt.prod@dbtlabs.com'
password = 'Supersecret123!'
default_role = TRANSFORMER
default_warehouse = TRANSFORMING
--must_change_password = true
;

use role SECURITYADMIN;
grant role TRANSFORMER to user DBT_PROD;

-- Test
use role TRANSFORMER;
use warehouse TRANSFORMING;

select * from SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER limit 10;

create schema if not exists ANALYTICS.DBT_ARUIZ;

create table if not exists ANALYTICS.DBT_ARUIZ.CUSTOMER as (
select * from SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER limit 10);

drop schema ANALYTICS.DBT_ARUIZ cascade;
