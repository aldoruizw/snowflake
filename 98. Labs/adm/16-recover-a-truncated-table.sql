
-- 16.0.0  Recover a Truncated Table
--         This optional lab should take you approximately 10 minutes to
--         complete.
--         By the end of this lab, you will be able to:
--         - Recover a truncated table to restore the rows that were removed.
--         - Determine why rollback command does not always work.
--         This lab shows how you can recover a table after a TRUNCATE using
--         time travel.
--         In this exercise, you will create a table with 600 Million rows and
--         then truncate it. Truncate command removes all the rows from a table,
--         but leaves the table intact.

-- 16.1.0  Load Lab SQL file

-- 16.1.1  To load the SQL file, in the left navigation bar, select Projects,
--         then, under My Workspace, select the lab SQL file corresponding to
--         this lab exercise.

-- 16.1.2  Ensure your active role is set to adm_role in the bottom left corner
--         of the UI.

-- 16.1.3  Set query tag for this session.

ALTER SESSION SET query_tag = '(USERLAB) lab - TOPIC: Recover a Truncated Table';


-- 16.2.0  Set Up a Large Test Table

-- 16.2.1  Set your context.

USE ROLE SYSADMIN;
CREATE WAREHOUSE IF NOT EXISTS USERLAB_adm_wh;
USE WAREHOUSE USERLAB_adm_wh;
CREATE DATABASE IF NOT EXISTS USERLAB_adm_db;
USE SCHEMA USERLAB_adm_db.public;


-- 16.2.2  Increase warehouse size to extra extra large.

ALTER WAREHOUSE USERLAB_adm_wh SET warehouse_size=xxlarge
WAIT_FOR_COMPLETION = true;


-- 16.2.3  Create a 600M row table.

DROP TABLE IF EXISTS USERLAB_trunctbl;

-- Runs for about 16 secs with XXL WH
CREATE TABLE USERLAB_trunctbl AS
SELECT * FROM "SNOWFLAKE_SAMPLE_DATA"."TPCH_SF100"."LINEITEM";

-- Verify 600,037,902 rows
SELECT COUNT(*) FROM USERLAB_trunctbl;

--         The table size will be 600,037,902 rows.

-- 16.3.0  Remove All the Rows in the Table

-- 16.3.1  Truncate the table you just created, which will remove all the rows
--         of data.
--         Recall that in Snowflake, TRUNCATE is a DML operation, not DDL.

TRUNCATE TABLE USERLAB_trunctbl;
-- Set Query ID variable
SET truncate_var=LAST_QUERY_ID();


-- 16.3.2  Try Rollback which will not get the data back due to AUTOCOMMIT=TRUE
--         (default parameter value).

ROLLBACK;
-- All rows are still gone
SELECT COUNT(*) FROM USERLAB_trunctbl;


-- 16.3.3  Restore all 600,037,902 rows using the Query ID we saved previously
--         in the variable truncate_var (runs for about 16 secs with XXL WH).

INSERT INTO USERLAB_trunctbl
SELECT * FROM USERLAB_trunctbl
BEFORE(statement => $truncate_var);


-- 16.3.4  Check that all data is back (600,037,902 rows).

SELECT COUNT(*) FROM USERLAB_trunctbl;


-- 16.4.0  Using Rollback to Restore Table Data

-- 16.4.1  Set autocommit=false before doing the TRUNCATE.
--         Note: If we had first set autocommit=false BEFORE doing the TRUNCATE,
--         a ROLLBACK would have restored all table data without usage of time
--         travel, since TRUNCATE is a DML statement (not DDL like it is in some
--         other database systems)

ALTER SESSION SET AUTOCOMMIT=false;


-- 16.4.2  Show the session parameters to verify autocommit is set to false.

SHOW PARAMETERS LIKE 'autocommit' IN SESSION;


-- 16.4.3  Truncate the table again and verify rows are gone.

TRUNCATE TABLE USERLAB_trunctbl;

-- Verify all rows are gone
SELECT COUNT(*) FROM USERLAB_trunctbl;


-- 16.4.4  Rollback will get the data back due to AUTOCOMMIT=FALSE

ROLLBACK;


-- 16.4.5  Verify the rows are back.

-- Verify 600,037,902 rows are back
SELECT COUNT(*) FROM USERLAB_trunctbl;


-- 16.4.6  Reset autocommit, resize WH back to XS, and suspend that WH.

ALTER SESSION UNSET AUTOCOMMIT;

SHOW PARAMETERS LIKE 'autocommit' IN SESSION;

ALTER WAREHOUSE USERLAB_adm_wh SET WAREHOUSE_SIZE=xsmall;
ALTER WAREHOUSE USERLAB_adm_wh SUSPEND;


-- 16.5.0  Key Takeaways
--         - Rollback will not get the data back due to AUTOCOMMIT=TRUE (default
--         parameter value).
--         - TRUNCATE is a DML statement (not DDL like it is in some other
--         database systems).
--         - You can use Time Travel to recover a table that may have been
--         truncated (all rows removed) by mistake.
