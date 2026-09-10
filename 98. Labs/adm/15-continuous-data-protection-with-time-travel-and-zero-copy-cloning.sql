
-- 15.0.0  Continuous Data Protection With Time Travel and Zero-Copy Cloning
--         This lab should take you approximately 10 minutes to complete.
--         By the end of this lab, you will be able to:
--         - Explain the purpose and function of Time Travel.
--         - Identify how Zero-Copy Cloning works.
--         - Use both Time Travel and Zero-Copy Cloning to restore data.
--         The activities of taking a physical backup can now be replaced by
--         making a clone, which is significantly faster and incurs fewer
--         storage charges ($0 at best). Combined with Snowflake’s Time Travel
--         feature, daily backups are no longer needed as Snowflake makes the
--         normally difficult task of doing Point in Time Recovery (PITR) a
--         simple matter.
--         Snowflake’s Continuous Data Protection encompasses a comprehensive
--         set of features that help protect data stored in Snowflake against
--         human error, malicious acts, and software or hardware failure. At
--         every stage within the data lifecycle, Snowflake enables your data to
--         be accessible and recoverable in the event of accidental or
--         intentional modification, removal, or corruption.

-- 15.1.0  Load Lab SQL File

-- 15.1.1  To load the SQL file, in the left navigation bar, select Projects,
--         then, under My Workspace, select the lab SQL file corresponding to
--         this lab exercise.

-- 15.1.2  Ensure your active role is set to adm_role in the bottom left corner
--         of the UI.

-- 15.1.3  Set query tag for this session.

ALTER SESSION SET query_tag = '(USERLAB) lab - TOPIC: Continuous Data Protection With Time Travel and Zero-Copy Cloning';


-- 15.2.0  Set the Context

USE ROLE SYSADMIN;
CREATE WAREHOUSE IF NOT EXISTS USERLAB_adm_wh;
USE WAREHOUSE USERLAB_adm_wh;

CREATE DATABASE USERLAB_cdp_db;
CREATE SCHEMA hr;
USE SCHEMA USERLAB_cdp_db.hr;


-- 15.2.1  Create EMPLOYEE table with the following columns:

-- 15.2.2  Run the following SQL to create the EMPLOYEE table:

CREATE OR REPLACE TABLE employee (
     emp_id     NUMBER,
     dept_id    NUMBER,
     first_name VARCHAR(50),
     last_name  VARCHAR(50),
     salary     NUMBER(12,2),
     bonus      NUMBER(12,2)
     );


-- 15.2.3  Insert the following four (4) rows into the EMPLOYEE table:

INSERT INTO hr.employee VALUES
    (100, 1, 'Josephine', 'Jones', 84000.00, 0),
    (200, 2, 'Art', 'Dawson', 65000.00, 0),
    (300, 1, 'Peter', 'Burch', 76000.00, 0),
    (400, 2, 'Tony', 'Brown', 62000.00, 0);


-- 15.3.0  Continuous Data Protection with Time Travel
--         This exercise demonstrates how Time Travel can restore tables that
--         are accidentally dropped. In other database platforms, dropping a
--         database, schema, or table is disastrous and requires that the
--         database be restored from backup (if one exists). In Snowflake,
--         however, since dropping objects is only a metadata-based operation,
--         restoring from a DROP statement can be completed in seconds by using
--         the UNDROP command.
--         The UNDROP command must be executed within the data retention time
--         (DATA_RETENTION_TIME_IN_DAYS) parameter value for the table. For
--         Standard Edition this can be 0 or 1 day (default 1). For Enterprise
--         Edition and above this can be 0 to 90 days for permanent tables and 0
--         or 1 day for temporary and transient tables (default is 1 unless a
--         different default value was specified at the schema, database, or
--         account level).

-- 15.3.1  Check the table created above and look at the data retention time.

-- 15.3.2  Use the SHOW TABLES SQL command to validate:

SHOW TABLES;
SHOW PARAMETERS LIKE '%DATA_RETENTION_TIME_IN_DAYS%' IN ACCOUNT;

--         EMPLOYEE table exists in the HR schema
--         EMPLOYEE table has four (4) rows
--         Retention time is one (1) day

-- 15.3.3  Run the following SQL to drop the table:

DROP TABLE hr.employee;


-- 15.3.4  Confirm the table was deleted by querying it and running a SHOW
--         TABLES command:
--         You will notice that SHOW TABLES does not return dropped tables.

SELECT * FROM hr.employee;
SHOW TABLES;


-- 15.3.5  List all tables, including those tables that have been dropped.
--         You can use the SHOW TABLES HISTORY command if you wish to view
--         dropped tables. Realize, however, that dropped tables will only
--         appear if they are still within their respective Time Travel
--         retention periods.

-- 15.3.6  Use the SHOW TABLES HISTORY command to see all the tables including
--         dropped tables:

SHOW TABLES HISTORY;


-- 15.3.7  Run the following command to UNDROP the employee table, i.e., restore
--         the table:

UNDROP TABLE hr.employee;


-- 15.3.8  Confirm that the table was restored by querying it again:

SELECT * FROM hr.employee;

--         This exercise demonstrates the UNDROP TABLE command. UNDROP DATABASE
--         and UNDROP SCHEMA restore databases and schemas, respectively, to
--         their previous state.

-- 15.3.9  For extra practice repeat this exercise by dropping and un-dropping
--         your database and then the HR schema.
--         SCHEMA

SHOW SCHEMAS;
DROP SCHEMA hr;
SHOW SCHEMAS;
SHOW SCHEMAS HISTORY;
UNDROP SCHEMA hr;
SHOW SCHEMAS;

--         DATABASE

-- Make sure your USERLAB is in ALL CAPS
SHOW DATABASES STARTS WITH 'USERLAB';

DROP DATABASE USERLAB_cdp_db;

-- Make sure your USERLAB is in ALL CAPS
SHOW DATABASES HISTORY STARTS WITH 'USERLAB';

UNDROP DATABASE USERLAB_cdp_db;

-- Make sure your USERLAB is in ALL CAPS
SHOW DATABASES HISTORY STARTS WITH 'USERLAB';


-- 15.4.0  Use Time Travel and Zero-Copy Cloning Together to Restore Data
--         This exercise uses Time Travel and Zero-Copy Cloning together to
--         restore data to a point in time.

-- 15.4.1  Use the CLONE option to restore a table to the point in time
--         immediately prior to an errant update.

-- 15.4.2  Update the new DEPT_ID column in HR.EMPLOYEE. You may need to reset
--         the context:

USE DATABASE USERLAB_cdp_db;
USE SCHEMA hr;
UPDATE hr.employee SET dept_id = 0
WHERE last_name = 'Jones';

--         Whoops, we made a mistake. We didn’t mean to move Jones to a
--         different department.

-- 15.4.3  Find the query ID that performed the UPDATE to HR.EMPLOYEE ID.
--         This can be done several ways including using the History tab in the
--         UI or using the LAST_QUERY_ID() function below or querying using the
--         QUERY_HISTORY function.
--         Option 1: LAST_QUERY_ID() function.

-- 15.4.4  If the query you want the ID for is the last query run, use the
--         function LAST_QUERY_ID().

SET qid = LAST_QUERY_ID();

--         Option 2: Query a QUERY_HISTORY table function to find the query.

SELECT query_id, query_text
FROM TABLE(information_schema.query_history_by_user(user_name=>'USERLAB'));


-- 15.4.5  Restore the table to the state prior to updating the dept_id column.

-- 15.4.6  Create a clone of the HR.EMPLOYEE table, as it was before the UPDATE
--         statement, named HR.EMPLOYEE_RESTORE, using the Query ID that you
--         identified using on of the two options shown above.

CREATE OR REPLACE TABLE hr.employee_restore CLONE hr.employee
BEFORE (STATEMENT => $qid);


-- 15.4.7  Query the HR.EMPLOYEE_RESTORE table to ensure that it was restored to
--         the point in time before the DEPT_ID column updates.

SELECT *
    FROM hr.employee_restore;


-- 15.4.8  Swap the hr.employee_restore with hr.employee table:

ALTER TABLE hr.employee_restore SWAP WITH hr.employee;


-- 15.4.9  Query the hr.employee table to confirm it now contains the restored
--         data:

SELECT *
   FROM hr.employee;


-- 15.4.10 Perform a clean up of your system by dropping the HR database:

DROP DATABASE USERLAB_cdp_db;


-- 15.4.11 Suspend the warehouse since it is no longer needed.

ALTER WAREHOUSE USERLAB_adm_wh SUSPEND;


-- 15.5.0  Key Takeaways
--         In this exercise, we explored the following areas:
--         - Explored the purpose and function of Time Travel.
--         - Demonstrated how Zero-Copy Cloning works.
--         - Used both Time Travel and Zero-Copy Cloning to restore data.
