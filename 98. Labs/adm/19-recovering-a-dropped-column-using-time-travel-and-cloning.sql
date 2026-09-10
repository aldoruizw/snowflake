
-- 19.0.0  Recovering a Dropped Column Using Time Travel and Cloning
--         This lab should take you approximately 20 minutes to complete.
--         By the end of this lab, you will be able to:
--         - Recover a table to a previous DDL state.
--         - Show table history, and note when it might have been dropped.
--         This lab shows how you can use time travel and cloning to recover a
--         table that has had one or more columns dropped.
--         This exercise is a use case involving recovering from DDL commands
--         such as ALTER TABLE...DROP COLUMN. To successfully recover a table
--         from a drop column DDL, you cannot simply use time travel by itself.
--         The recovery requires using time travel in conjunction with cloning,
--         in a similar way as for doing a database point-in-time recovery.

-- 19.1.0  Load Lab SQL file

-- 19.1.1  To load the SQL file, in the left navigation bar, select Projects,
--         then, under My Workspace, select the lab SQL file corresponding to
--         this lab exercise.

-- 19.1.2  Ensure your active role is set to adm_role in the bottom left corner
--         of the UI.

-- 19.1.3  Set query tag for this session.

ALTER SESSION SET query_tag = '(PONY) lab - TOPIC: Database Point-In-Time Recovery';


-- 19.2.0  Set Up a Test Table

-- 19.2.1  Set your context.

USE ROLE adm_role;
CREATE WAREHOUSE IF NOT EXISTS PONY_adm_wh;
USE WAREHOUSE PONY_adm_wh;
CREATE DATABASE IF NOT EXISTS PONY_adm_db;
USE SCHEMA PONY_adm_db.public;


-- 19.2.2  Set the Virtual Warehouse size for use in the lab.

ALTER WAREHOUSE PONY_adm_wh SET WAREHOUSE_SIZE=xsmall
WAIT_FOR_COMPLETION = TRUE;


-- 19.2.3  Create a 1.5M row table.

DROP TABLE IF EXISTS PONY_adm_db.public.customer;

-- Runs for about 5 secs with xsmall warehouse
CREATE TABLE PONY_adm_db.public.customer AS
SELECT * FROM "SNOWFLAKE_SAMPLE_DATA"."TPCH_SF10"."CUSTOMER";


-- 19.2.4  Show the row count for the table.

SELECT COUNT(*) FROM PONY_adm_db.public.customer; -- 1.5M rows


-- 19.2.5  Show some data in CUSTOMER table.

SELECT c_custkey,c_name,c_address,c_nationkey FROM PONY_adm_db.public.customer
LIMIT 15;


-- 19.2.6  Show CUSTOMER table history

SHOW TABLES HISTORY LIKE 'CUSTOMER';
SELECT "name"
      ,"created_on"
      ,"owner"
      ,"dropped_on"
    FROM TABLE(result_scan(last_query_id()))
ORDER BY "dropped_on" desc;

--         Note that DROPPED_ON=null means that this is the current (active)
--         table version

-- 19.2.7  Capture current timestamp.
--         Capture the current timestamp into an SQL variable to use to recover
--         the databases back to this point in time.
--         - The output of the command below for current timestamp will be used
--         to clone the CUSTOMER table prior to the dropping of the columns
--         C_NAME and C_ADDRESS.

SET recovery_ts = CURRENT_TIMESTAMP();

-- Show the captured timestamp
SELECT $recovery_ts;


-- 19.2.8  Drop the columns C_NAME and C_ADDRESS from CUSTOMER table.

ALTER TABLE  PONY_adm_db.public.customer DROP COLUMN c_name;
ALTER TABLE  PONY_adm_db.public.customer DROP COLUMN c_address;


-- 19.2.9  Verify that these two columns are dropped from CUSTOMER. Errors out.

SELECT c_custkey,c_name,c_address,c_nationkey FROM PONY_adm_db.public.customer
LIMIT 15;


-- 19.2.10 This query succeeds, but columns C_NAME and C_ADDRESS are gone.

SELECT * FROM PONY_adm_db.public.customer
LIMIT 15;


-- 19.3.0  Restore the Dropped Columns
--         To recover the two dropped columns in CUSTOMER, it is necessary to
--         clone CUSTOMER to a point in time before the columns were dropped.
--         - You can use TIMESTAMP or OFFSET for doing the clone, but using
--         QUERY_ID of the ALTER DDL statement (i.e., the BEFORE STATEMENT
--         option in time travel will NOT work as doing so will fail).
--         - You can use QUERY_ID for doing the clone if it is from a DML
--         statement, like our SELECT back earlier, when the data was correct.

-- 19.3.1  Clone table to a point before columns were dropped.
--         - $recovery_ts will represent a point-in-time prior to dropping the
--         two columns.

CREATE OR REPLACE TABLE PONY_adm_db.public.customer_clone
CLONE PONY_adm_db.public.customer
BEFORE (timestamp => $recovery_ts::TIMESTAMP_LTZ);


-- 19.3.2  Show that the clone contains the two dropped columns C_NAME,
--         C_ADDRESS and the data in those columns.

SELECT * FROM PONY_adm_db.public.customer_clone
LIMIT 15;


-- 19.3.3  Next, use the ALTER TABLE...SWAP command to swap CUSTOMER_CLONE with
--         CUSTOMER.
--         After the swap, CUSTOMER will be restored to its original state and
--         include both previously dropped columns and their data.

ALTER TABLE PONY_adm_db.public.customer SWAP WITH PONY_adm_db.public.customer_clone;


-- 19.3.4  Verify that CUSTOMER now contains the two dropped columns C_NAME,
--         C_ADDRESS.
--         Show that CUSTOMER now contains the two dropped columns C_NAME,
--         C_ADDRESS and the column data

SELECT c_custkey,c_name,c_address,c_nationkey FROM PONY_adm_db.public.customer
LIMIT 15;


-- 19.3.5  Verify that all 1.5M rows are in the CUSTOMER table.

SELECT COUNT(*) FROM PONY_adm_db.public.customer;

ALTER WAREHOUSE PONY_adm_wh set warehouse_size=xsmall WAIT_FOR_COMPLETION = TRUE;


-- 19.3.6  Run the commands below to clear out the objects used in this lab:

USE ROLE adm_role;
DROP TABLE IF EXISTS PONY_adm_db.public.customer;
DROP TABLE IF EXISTS PONY_adm_db.public.customer_clone;
ALTER WAREHOUSE PONY_adm_wh SUSPEND;


-- 19.4.0  Key Takeaways
--         - To successfully recover a table from a drop column DDL, you cannot
--         simply use time travel by itself.
--         - The recovery requires using time travel in conjunction with
--         cloning.
