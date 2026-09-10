
-- 17.0.0  Database Point-In-Time Recovery
--         This optional lab should take you approximately 15 minutes to
--         complete.
--         By the end of this lab, you will be able to:
--         - Recover a corrupted database back to an earlier point in time.
--         This lab shows how you can use time travel and cloning to recover a
--         corrupted database back to an earlier point in time.
--         This exercise is a use case involving recovering a database that got
--         corrupted to an earlier point in time. To successfully do this, you
--         cannot simply use time travel by itself. The recovery requires using
--         time travel in conjunction with cloning.

-- 17.1.0  Load Lab SQL file

-- 17.1.1  To load the SQL file, in the left navigation bar, select Projects,
--         then, under My Workspace, select the lab SQL file corresponding to
--         this lab exercise.

-- 17.1.2  Ensure your active role is set to adm_role in the bottom left corner
--         of the UI.

-- 17.1.3  Set query tag for this session.

ALTER SESSION SET query_tag = '(USERLAB) lab - TOPIC: Database Point-In-Time Recovery';


-- 17.2.0  Set Up a Database and Schema for Test Tables

-- 17.2.1  Set your context.

USE ROLE SYSADMIN;
CREATE WAREHOUSE IF NOT EXISTS USERLAB_adm_wh;
USE WAREHOUSE USERLAB_adm_wh;
CREATE DATABASE IF NOT EXISTS USERLAB_adm_db;
USE SCHEMA USERLAB_adm_db.public;


-- 17.2.2  Create TAXDATA_DB database.

DROP DATABASE IF EXISTS USERLAB_taxapp_db;
DROP DATABASE IF EXISTS USERLAB_taxapp_clone_db;

CREATE DATABASE USERLAB_taxapp_db;
CREATE SCHEMA USERLAB_taxapp_db.taxapp_schema;

USE SCHEMA USERLAB_taxapp_db.taxapp_schema;


-- 17.2.3  Create TAXAPP_DB.TAXAPP_SCHEMA tables.

CREATE OR REPLACE TABLE USERLAB_taxapp_db.taxapp_schema.taxpayer
AS SELECT * FROM training_tax_db.taxschema.taxpayer;

CREATE OR REPLACE TABLE USERLAB_taxapp_db.taxapp_schema.taxpayer_dependents
AS SELECT * FROM training_tax_db.taxschema.taxpayer_dependents;

CREATE OR REPLACE TABLE USERLAB_taxapp_db.taxapp_schema.taxpayer_wages
AS SELECT * FROM training_tax_db.taxschema.taxpayer_wages;


-- 17.2.4  Verify that the data has been successfully loaded into the
--         TAXAPP_SCHEMA tables.

SELECT * FROM USERLAB_taxapp_db.taxapp_schema.taxpayer; -- 36 rows
SELECT * FROM USERLAB_taxapp_db.taxapp_schema.taxpayer_dependents; -- 20 rows
SELECT * FROM USERLAB_taxapp_db.taxapp_schema.taxpayer_wages; -- 30 rows


-- 17.2.5  Find current database version.

SHOW DATABASES LIKE 'USERLAB_TAXAPP%';


-- 17.2.6  Show all database history for USERLAB_taxapp_db.

SHOW DATABASES HISTORY LIKE 'USERLAB_TAXAPP%';
SELECT "name"
      ,"created_on"
      ,"owner"
      ,"dropped_on"
    FROM TABLE(result_scan(last_query_id()))
    WHERE "dropped_on" is null;


--         Note that DROPPED_ON=null means that this is the current (active)
--         database version

-- 17.2.7  Capture current timestamp.
--         Capture the current timestamp into an SQL variable to use to recover
--         the databases back to this point in time.
--         - The output of the command below for current timestamp will be used
--         to clone the TAXAPP_DB database prior to the data corruption.

SET recovery_ts = CURRENT_TIMESTAMP();

-- Show the captured timestamp
SELECT $recovery_ts;


-- 17.3.0  Corrupt the Data in the Tables in Your Test Database

-- 17.3.1  Corrupt the database (run these updates multiple times if desired to
--         corrupt the data many times over).

USE SCHEMA USERLAB_taxapp_db.taxapp_schema;

UPDATE USERLAB_taxapp_db.taxapp_schema.taxpayer
SET taxpayer_id=UNIFORM(10000,99999,ABS(RANDOM())),lastname=RANDSTR(30,RANDOM()),
firstname=RANDSTR(30,RANDOM());

UPDATE USERLAB_taxapp_db.taxapp_schema.taxpayer_dependents
SET taxpayer_id=UNIFORM(10000,99999,ABS(RANDOM())),
dependent_ssn=UNIFORM(10000,99999,ABS(RANDOM())),
dep_lastname=RANDSTR(30,RANDOM()),dep_firstname=RANDSTR(30,RANDOM());

UPDATE USERLAB_taxapp_db.taxapp_schema.taxpayer_wages
SET taxpayer_id=UNIFORM(10000,99999,ABS(RANDOM())),state=RANDSTR(2,RANDOM()),
tax_year=UNIFORM(1000,9999,ABS(RANDOM())),
w2_total_income=UNIFORM(10000,99999,ABS(RANDOM()));



-- 17.3.2  Show the corrupted data.

SELECT taxpayer_id,lastname,firstname
FROM USERLAB_taxapp_db.taxapp_schema.taxpayer
ORDER BY taxpayer_id asc;

SELECT taxpayer_id,dependent_ssn,
dep_lastname,dep_firstname
FROM USERLAB_taxapp_db.taxapp_schema.taxpayer_dependents
ORDER BY taxpayer_id asc;

SELECT taxpayer_id,state,tax_year,w2_total_income
FROM USERLAB_taxapp_db.taxapp_schema.taxpayer_wages
ORDER BY taxpayer_id asc;


-- 17.4.0  Recover the Database
--         We will recover the database to the point just before the data
--         corruption occurred based on the timestamp we captured earlier in the
--         demo.
--         - This is the timestamp we will use for the point-in-time recovery of
--         the database.

-- 17.4.1  Create a clone of the database at the desired point-in-time.

DROP DATABASE IF EXISTS USERLAB_taxapp_clone_db;

CREATE OR REPLACE DATABASE USERLAB_taxapp_clone_db
CLONE USERLAB_taxapp_db
BEFORE (timestamp => $recovery_ts::TIMESTAMP_LTZ);


-- 17.4.2  Verify that the pre-corruption tax data shows up in the database
--         clone.

SELECT taxpayer_id,lastname,firstname
FROM USERLAB_taxapp_clone_db.taxapp_schema.taxpayer
ORDER BY taxpayer_id asc;

SELECT taxpayer_id,dependent_ssn,
dep_lastname,dep_firstname
FROM USERLAB_taxapp_clone_db.taxapp_schema.taxpayer_dependents
ORDER BY taxpayer_id asc;

SELECT taxpayer_id,state,w2_total_income
FROM USERLAB_taxapp_clone_db.taxapp_schema.taxpayer_wages
ORDER BY taxpayer_id asc;


-- 17.4.3  Show current information for USERLAB_taxapp_db and
--         USERLAB_taxapp_clone_db before the swap.

SELECT database_name,created
FROM information_schema.databases
WHERE database_name like 'USERLAB_TAXAPP%'
ORDER BY database_name desc;


-- 17.4.4  Swap the clone database with the source database.

ALTER DATABASE USERLAB_taxapp_clone_db
SWAP WITH USERLAB_taxapp_db;


-- 17.4.5  Verify that database USERLAB_taxapp_db now contains the original
--         (non-corrupted) data.

SELECT taxpayer_id,lastname,firstname
FROM USERLAB_taxapp_db.taxapp_schema.taxpayer
ORDER BY taxpayer_id asc;

SELECT taxpayer_id,dependent_ssn,
dep_lastname,dep_firstname
FROM USERLAB_taxapp_db.taxapp_schema.taxpayer_dependents
ORDER BY taxpayer_id asc;

SELECT taxpayer_id,state,w2_total_income
FROM USERLAB_taxapp_db.taxapp_schema.taxpayer_wages
ORDER BY taxpayer_id asc;


-- 17.4.6  Verify that DB IDs have been swapped for USERLAB_taxapp_db and
--         USERLAB_taxapp_clone_db.
--         Note that again there is a 5-10 minute latency (possibly shorter) on
--         the DB IDs showing up as swapped

SELECT database_id,database_name,created
FROM snowflake.account_usage.databases
WHERE database_name like 'USERLAB_TAXAPP%'
ORDER BY database_name desc;


-- 17.4.7  Finally, show that the CORRUPTED tax data now shows up in the
--         database clone.

SELECT taxpayer_id,lastname,firstname
FROM USERLAB_taxapp_clone_db.taxapp_schema.taxpayer
ORDER BY taxpayer_id asc;

SELECT taxpayer_id,dependent_ssn,
dep_lastname,dep_firstname
FROM USERLAB_taxapp_clone_db.taxapp_schema.taxpayer_dependents
ORDER BY taxpayer_id asc;

SELECT taxpayer_id,state,w2_total_income
FROM USERLAB_taxapp_clone_db.taxapp_schema.taxpayer_wages
ORDER BY taxpayer_id asc;


-- 17.4.8  Since the clone contains corrupt tax data, drop it since it’s no
--         longer needed.

DROP DATABASE IF EXISTS USERLAB_taxapp_clone_db;


-- 17.5.0  Clean Up

-- 17.5.1  Run the commands below to clear out the objects used in this lab:

USE ROLE SYSADMIN;
USE SCHEMA USERLAB_adm_db.public;
DROP DATABASE IF EXISTS USERLAB_taxapp_db;

ALTER WAREHOUSE USERLAB_adm_wh SUSPEND;


-- 17.6.0  Key Takeaways
--         - To successfully recover a corrupted database back to an earlier
--         point in time, you cannot simply use time travel by itself.
--         - The recovery requires using time travel in conjunction with
--         cloning.
