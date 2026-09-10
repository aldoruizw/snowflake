
-- 11.0.0  Snowflake Data Objects and Models
--         By the end of this lab, you will be able to:
--         - Use Snowflake’s extended SQL.
--         - Create and use key Snowflake database objects.
--         - Use the SHOW command to list different object types and their
--         parameters.
--         - Identify and implement different types of tables within a database.
--         - Distinguish between views and view types as well as Snowflake data
--         types.

-- 11.1.0  Load Lab SQL file

-- 11.1.1  To load the SQL file, in the left navigation bar, select Projects,
--         then, under My Workspace, select the lab SQL file corresponding to
--         this lab exercise.

-- 11.1.2  Set query tag for this session.

ALTER SESSION SET query_tag = '(USERLAB) lab - TOPIC: Snowflake Data Objects and Models';


-- 11.1.3  Create the database.
USE ROLE SYSADMIN;
CREATE DATABASE IF NOT EXISTS USERLAB_adm_db 
COMMENT='Database for Admin course labs';


-- 11.1.4  Create the warehouse.

CREATE WAREHOUSE IF NOT EXISTS USERLAB_adm_query_wh
    WAREHOUSE_SIZE=XSmall
    INITIALLY_SUSPENDED=True
    AUTO_SUSPEND=300
    COMMENT='Warehouse for Admin course labs';


-- 11.2.0  Using SHOW Commands to Explore Snowflake Parameters
--         The SHOW command is one of the most frequently used commands to
--         determine the various features and parameters of Snowflake.

-- 11.2.1  Set the following as context within this worksheet.

USE ROLE SYSADMIN;
ALTER SESSION SET USE_CACHED_RESULT = false;
USE WAREHOUSE USERLAB_adm_query_wh;
--USE SCHEMA training_db.traininglab;


-- 11.2.2  Use the SHOW command to display all parameters available at the
--         account level.

SHOW PARAMETERS IN ACCOUNT;

--         This command displays many parameters configured by Snowflake with
--         out-of-the-box default values. Many of these parameters can be
--         overridden and customized at the session or object level depending on
--         the use cases.

-- 11.2.3  Use the SHOW command again to display parameters set in the current
--         session.

SHOW PARAMETERS IN SESSION;


-- 11.2.4  SHOW all the parameters available in the SNOWFLAKE_SAMPLE_DATA
--         database.

SHOW PARAMETERS IN DATABASE snowflake_sample_data;


-- 11.3.0  Show Databases, Schemas, and Tables

-- 11.3.1  First create a few databases and some tables for later use in the
--         lab.

CREATE DATABASE IF NOT EXISTS USERLAB_adm_temp_db COMMENT='Admin labs: Temp database';

CREATE DATABASE IF NOT EXISTS USERLAB_adm_test_db COMMENT='Admin labs: Test database';

USE DATABASE USERLAB_adm_test_db;

USE SCHEMA PUBLIC;

CREATE OR REPLACE TABLE nation_2
AS SELECT * FROM snowflake_sample_data.tpch_sf1.nation;

CREATE OR REPLACE TABLE nation_3
AS SELECT * FROM snowflake_sample_data.tpch_sf1.nation;

CREATE OR REPLACE TABLE orders_sample_25
AS SELECT * FROM snowflake_sample_data.tpch_sf1.orders LIMIT 25;

SHOW TABLES;


-- 11.3.2  Drop a database and a table.

DROP DATABASE USERLAB_adm_temp_db;

DROP TABLE nation_2;


-- 11.3.3  Lists the databases for which you have access privileges across your
--         entire account.

SHOW DATABASES HISTORY;

--         The previous command lists the databases to which you have access
--         privileges across your entire account. In our training account, this
--         will include databases created by other users on the account. The
--         HISTORY command option will also display any dropped databases that
--         are still within the Time Travel retention period and shows when the
--         databases were dropped.

-- 11.3.4  Show all of the SCHEMAS in the SNOWFLAKE_SAMPLE_DATA database.

SHOW SCHEMAS IN DATABASE snowflake_sample_data;

--         This command lists schemas for the SNOWFLAKE_SAMPLE_DATA database.
--         The output returns schema metadata and properties, ordered
--         lexicographically by schema name. This is important to note if you
--         wish to filter the results using the provided filters.

-- 11.3.5  Show all tables in the TPCH_SF1 schema of the SNOWFLAKE_SAMPLE_DATA
--         database.

SHOW TABLES IN SCHEMA snowflake_sample_data.tpch_sf1;


-- 11.3.6  Show the details on the TRAINING_DB.TRAININGLAB.LINEITEM table.

SHOW COLUMNS IN TABLE snowflake_sample_data.tpch_sf1.lineitem;
DESC TABLE snowflake_sample_data.tpch_sf1.lineitem;

--         It is also possible to use SHOW PARAMETERS IN TABLE
--         training_db.traininglab.lineitem if the current role has OWNERSHIP
--         privileges on the table/view. In our case ADM_ROLE does not have
--         OWNERSHIP privileges on this table therefore the command will fail.
--         These commands display key attributes for each important object. For
--         instance, in the case of the table, the property,
--         DATA_RETENTION_TIME_IN_DAYS, is important for performing Time Travel
--         queries and undropping tables due to mistakes.

-- 11.3.7  Display and provide details on views.

USE SCHEMA information_schema;
SHOW VIEWS;
SHOW TERSE VIEWS;

--         TERSE views return only a subset of the output columns:
--         created_on,name,kind,database_name,schema_name

SHOW views LIKE 'tables';


-- 11.4.0  Show Objects and Warehouse Information

-- 11.4.1  Display information about additional objects including the following
--         subsets.

SHOW OBJECTS;
SHOW FUNCTIONS;
SHOW USER FUNCTIONS;
SHOW PIPES;
SHOW STAGES;
SHOW TRANSACTIONS;
SHOW VARIABLES;
SHOW SHARES;


-- 11.4.2  Show warehouses and other SHOW commands to display warehouse
--         information.

SHOW WAREHOUSES;
SHOW PARAMETERS IN WAREHOUSE USERLAB_adm_query_wh;
SHOW WAREHOUSES LIKE '%QUERY_WH';

--         Use the RESULT_SCAN function with SHOW command output.
--         The RESULT_SCAN function returns the result set of a previous command
--         (provided the result is still in the query result cache, which
--         typically is within 24 hours of when you executed the query) as if
--         the result was a table. This is useful if you need to process command
--         output such as the SHOW command and other metadata query statements;
--         e.g., DESCRIBE commands and INFORMATION_SCHEMA queries.

-- 11.4.3  Run a show warehouses command.
--         The SHOW WAREHOUSES command supports a LIKE command to limit the list
--         to one or more warehouses. Show the warehouse information for the
--         current user.

SHOW WAREHOUSES;

-- Capture the query id from the SHOW WAREHOUSES command. 
SET qid = last_query_id();

-- Use the result_scan function to show the results from the query cache.
SELECT * FROM TABLE(result_scan($qid));

-- SHOW and DESCRIBE commands do not support a WHERE clause but the result_scan will. 
--  Use the cached output from the SHOW WAREHOUSES command to find all the warehouses with an AUTO_SUSPEND less than 5 minutes.
-- NOTE: The column names in the SHOW commands are in lower case and case sensitive and must be quoted. 
SELECT * FROM TABLE(result_scan($qid))
    WHERE "auto_suspend" < 300;

-- In addition to using the columns in a WHERE clause, we can also limit the column lists. 
--  Use the query above but select just the name, size, and auto_suspend columns. 
SELECT "name", "size", "auto_suspend" FROM TABLE(result_scan($qid))
    WHERE "auto_suspend" < 300;


-- 11.5.0  Set Session Result Parameter
--         There are many parameters you can set at the session level and object
--         level. In this step you will adjust the ROWS_PER_RESULTSET at the
--         session level. This is a parameter that functions at the account,
--         user and session levels.

-- 11.5.1  Run a simple query that returns 20 rows from the lineitem table.

USE ROLE SYSADMIN;
SELECT * FROM snowflake_sample_data.tpch_sf1.lineitem LIMIT 20;


-- 11.5.2  Set the session variable ROWS_PER_RESULTSET to 10.

ALTER SESSION SET ROWS_PER_RESULTSET=10;


-- 11.5.3  Rerun the query.

SELECT * FROM snowflake_sample_data.tpch_sf1.lineitem LIMIT 20;

--         Note that only ten (10) rows were returned. The limit clause is
--         different from limiting the ROWS_PER_RESULT parameter. The limit
--         clause affects the execution of the query. The ROWS_PER_RESULT
--         parameter executes the full query only limiting the rows returned to
--         the client.

-- 11.5.4  Open the query profile and see that the limit of 20 rows was used.

-- 11.5.5  Reset the ROWS_PER_RESULTSET parameter. Be certain to run the next
--         step, or the following labs may not work correctly:

ALTER SESSION UNSET ROWS_PER_RESULTSET;


-- 11.5.6  Run the query again.

SELECT * FROM snowflake_sample_data.tpch_sf1.lineitem LIMIT 20;

--         The ROWS_PER_RESULTSET parameter is useful in performance testing. It
--         limits the amount of data returned over a network and reduces the
--         likelihood that your performance test is just measuring network time.

-- 11.6.0  Create a Database and Three (3) Types of Tables
--         This lab will cover the three (3) basic types of tables within
--         Snowflake;
--         - Permanent Tables
--         - Temporary Tables
--         - Transient Tables

-- 11.6.1  Create a database for future lab exercises named USERLAB_adm_db.

CREATE DATABASE IF NOT EXISTS USERLAB_adm_db;


-- 11.6.2  Set the defaults for your user.
USE ROLE SECURITYADMIN;
ALTER USER USERLAB SET
   DEFAULT_ROLE = SYSADMIN
   DEFAULT_WAREHOUSE = USERLAB_adm_wh
   DEFAULT_NAMESPACE =USERLAB_adm_db.public;


-- 11.6.3  Create a permanent table.
--         You will use the PUBLIC schema in your USERLAB_adm_db database for
--         labs, unless instructed otherwise.
--         Create a table inside the PUBLIC schema with the following column
--         definitions with a data retention period of 10 days:
USE ROLE SYSADMIN;
USE SCHEMA USERLAB_adm_db.public;
CREATE OR REPLACE TABLE USERLAB_tbl (
     ID NUMBER(38,0)
   , NAME STRING(10)
   , COUNTRY VARCHAR (20)
   , ORDER_DATE DATE
   )
   DATA_RETENTION_TIME_IN_DAYS = 10
   COMMENT = 'CUSTOMER INFORMATION';

--         Transient and temporary tables
--         The key differentiator for temporary and transient tables is that the
--         DATA_RETENTION_TIME_IN_DAYS parameter (used to determine how far back
--         you can go with time travel) can only be set to 0 or 1 days. This
--         saves on storage costs in situations where maximum data protection is
--         not required.

-- 11.6.4  Create a temporary table and insert some rows.
--         We are setting the retention period property to 0, from the standard
--         default of 1.

CREATE OR REPLACE TEMPORARY TABLE temp_tbl(
    C1 INTEGER, C2 INTEGER
    )  DATA_RETENTION_TIME_IN_DAYS = 0;
INSERT INTO temp_tbl VALUES (1,1),(2,2);
SELECT * FROM temp_tbl;


-- 11.6.5  Create a transient table

CREATE OR REPLACE TRANSIENT TABLE transient_tbl(
    C1 INTEGER, C2 INTEGER
    ) DATA_RETENTION_TIME_IN_DAYS = 2;

--         The previous CREATE TABLE command will generate an error. The key
--         idea for transient and temporary tables is that they cannot have a
--         retention period longer than one (1) day; again, this is to provide
--         storage (and cost) savings.

-- 11.6.6  Repeat the CREATE TRANSIENT TABLE statement with the default data
--         retention settings and add some rows:

CREATE OR REPLACE TRANSIENT TABLE tran_tbl(
    C1 INTEGER, C2 INTEGER
    );
INSERT INTO tran_tbl VALUES (1,1),(2,2);
SELECT * FROM tran_tbl;


-- 11.6.7  Open a new .SQL file in your current Workspace and label it
--         SECOND_FILE:
--         This exercise demonstrates that a transient table exists in both
--         sessions. This, however, is not the case for a temporary table.
--         Remember each SQL file in workspaces is its own session. You need to
--         specify the context for each worksheet individually.
--         In the left navigation bar, select Projects, then, under My
--         Workspace, click the + Add new button. Select SQL File from the drop-
--         down menu, then name the file SECOND_FILE.
--         Run the 5 SQL statements below in the current SQL file, then copy and
--         paste the same 5 SQL statements into the newly-opened SECOND_FILE and
--         run the commands in that SQL file. Once these SQL commands are run in
--         the SECOND_FILE, return to the original lab SQL file and answer the
--         questions below.

USE ROLE SYSADMIN;
USE WAREHOUSE USERLAB_adm_query_wh;
USE DATABASE USERLAB_adm_db;

SELECT * FROM tran_tbl;

SELECT * FROM temp_tbl;

--         Which one of the two (2) queries returned a result set?
--         - Answer: SELECT * FROM tran_tbl;
--         Can you explain why?
--         - Answer: Temporary tables are tied to a specific session. A
--         different session will not be able to query the temporary table.

-- 11.7.0  Constraints and enforcement properties
--         Snowflake supports and maintains many types of constraints but only
--         enforces the NOT NULL constraint for standard tables. For Hybrid
--         tables constraints are enforced.

-- 11.7.1  Return to the original worksheet.

-- 11.7.2  Create a parent table with several constraints, including NOT NULL
--         and a PRIMARY KEY:

CREATE table parent(
    id integer primary key
  , v1 integer not null
  , v2 integer unique
  , v3 string
);


-- 11.7.3  Insert several rows and check the results.
--         The second INSERT statement below will fail because Snowflake does
--         enforce the NOT NULL constraint. The third INSERT statement below
--         will not fail, because Snowflake does not enforce PRIMARY KEYs.

INSERT INTO parent values(1,1,1,'first row');
INSERT INTO parent values(2,null,1,'second row');
INSERT INTO parent values(1,2,1,'third row');
SELECT * FROM parent;


-- 11.7.4  Create a referential constraint by creating a child table with
--         referential constraints to the PARENT table.

CREATE table child(
    v1 integer primary key references parent(id)
  , v4 integer unique
  , v5 string
);


-- 11.7.5  Insert additional rows into the parent table.

INSERT INTO parent VALUES
   (2,5,10,'fourth row'),
   (3,2,25,'fifth row'),
   (4,6,30,'sixth row');

SELECT * FROM parent;


-- 11.7.6  Insert rows into the CHILD table, using multiple insert statements.

INSERT INTO child values(1,4,'child 1');
INSERT INTO child values(1,5,'child 2');
INSERT INTO child values(2,9,'child 3');
INSERT INTO child values(10,1,'child 4');

SELECT * FROM parent;


-- 11.7.7  Demonstrate Snowflake does not enforce referential integrity.
--         Note that the last insert above into the CHILD table was successful,
--         even though the parent ID of 10 does not exist in the PARENT table.



SELECT * FROM child;
SELECT p.id, c.v1 as "child_key", p.v1, p.v2, p.v3, c.v4, c.v5
  FROM parent p JOIN child c ON p.id=c.v1;
-- Join parent and child tables and you can see rows for parent.id 1 and 2.


SELECT p.id as "PARENT KEY", c.v1 AS "CHILD_KEY"
  FROM PARENT p FULL OUTER JOIN child c on p.id=c.v1;

-- With   FULL OUTER JOIN you can see parent id 1,2 and null. Row with null is for child key 10.


-- 11.8.0  Views and View Types
--         This exercise compares the difference between a standard view and a
--         materialized view.

-- 11.8.1  Use the following context.

USE SCHEMA USERLAB_adm_db.public;
USE ROLE SYSADMIN;


-- 11.8.2  Create a standard view.

CREATE OR REPLACE VIEW v_lab1 AS
 SELECT c.c_name, n_name, r_name
  FROM snowflake_sample_data.tpch_sf1.customer c JOIN snowflake_sample_data.tpch_sf1.nation n
     ON c.c_nationkey = n.n_nationkey
  JOIN snowflake_sample_data.tpch_sf1.region r
     ON n.n_regionkey = r.r_regionkey
  WHERE r.r_name IN ('AMERICA', 'AFRICA');

SELECT COUNT(*) FROM V_LAB1;


-- 11.8.3  Create a standard view with aggregates.

CREATE OR REPLACE VIEW v_lab1_agg AS
 SELECT r.r_name
    , n.n_name
    , sum(o.o_totalprice) as tot_order_dollars
    , avg(o.o_totalprice) as avg_order_dollars
    , count(*) as numb_orders
  FROM snowflake_sample_data.tpch_sf1.orders o
     JOIN snowflake_sample_data.tpch_sf1.customer c
       on o.o_custkey = c.c_custkey
     JOIN snowflake_sample_data.tpch_sf1.nation n
       ON c.c_nationkey = n.n_nationkey
     JOIN snowflake_sample_data.tpch_sf1.region r
       ON n.n_regionkey = r.r_regionkey
  GROUP BY r.r_name, n.n_name
  ORDER BY r.r_name, n.n_name;


-- 11.8.4  Set a session parameter on the result set size.

ALTER SESSION SET ROWS_PER_RESULTSET=20;

SELECT * FROM V_LAB1_AGG;


-- 11.8.5  Create a materialized View using the lineitem table.

CREATE OR REPLACE MATERIALIZED VIEW MV_LINEITEM_AGG
AS
  SELECT
     L_ORDERKEY
   , L_PARTKEY
   , L_SUPPKEY
   , AVG(L_QUANTITY) AS AVG_QTY
   , SUM(L_EXTENDEDPRICE) AS TOTAL_EXT_PRICE
   , SUM(L_TAX) AS TOT_TAX
   , SUM(L_DISCOUNT) AS TOT_DISC
  FROM snowflake_sample_data.tpch_sf1.lineitem
  GROUP BY L_ORDERKEY, L_PARTKEY, L_SUPPKEY;

SELECT * FROM mv_lineitem_agg;


-- 11.8.6  Use the materialized view created in the previous step to join with
--         other tables and generate some insights on total and average dollars
--         per region, per nation.

SELECT
   R.R_NAME AS REGION
 , N.N_NAME AS NATION
 , SUM(L.TOTAL_EXT_PRICE) AS TOT_DOLLARS
 , AVG(L.TOTAL_EXT_PRICE) AS AVG_DOLLARS
FROM mv_lineItem_agg L
   JOIN snowflake_sample_data.tpch_sf1.ORDERS O
     ON L.L_ORDERKEY = O.O_ORDERKEY
   JOIN snowflake_sample_data.tpch_sf1.CUSTOMER C
     ON O.O_CUSTKEY = C.C_CUSTKEY
   JOIN snowflake_sample_data.tpch_sf1.NATION N
     ON C.C_NATIONKEY = N.N_NATIONKEY
   JOIN snowflake_sample_data.tpch_sf1.REGION R
     ON N.N_REGIONKEY = R.R_REGIONKEY
GROUP BY R.R_NAME, N.N_NAME;


-- 11.8.7  Remember to Reset the ROWS_PER_RESULTSET parameter.

ALTER SESSION UNSET ROWS_PER_RESULTSET;


-- 11.9.0  Snowflake Data Types
--         Many Snowflake data types conform to the ANSI standard. This lab does
--         not cover that information; it does, however, explain how to use
--         Snowflake extensions such as the variant data types, time, and the
--         handling of binary data.

-- 11.9.1  Configure Date and Time Data Types by setting the context.

USE ROLE SYSADMIN;
USE WAREHOUSE USERLAB_adm_query_wh;
--USE DATABASE training_db;
--USE SCHEMA traininglab;

--         As a cloud-based solution, the underlying infrastructure might not
--         reside in the same timezone as the Snowflake client programs.
--         Snowflake provides time parameters at the account, session, and user
--         levels.

-- 11.9.2  List the time parameters for each of these.

SHOW PARAMETERS LIKE '%TIMEZONE%' IN ACCOUNT;
SHOW PARAMETERS LIKE '%TIMEZONE%' IN SESSION;
SHOW PARAMETERS LIKE '%TIMEZONE%' IN USER USERLAB;

--         Notice that the TIMEZONE parameter is set to America/Los_Angeles and
--         the default time formats for the account.

-- 11.9.3  Run a query to select the current time, and then change the session
--         time zone to America/Chicago:
--         See Time Zone Wiki for a list of time zones.

-- 11.9.4  Run the SELECT command on the current time again.

SELECT CURRENT_TIME();
ALTER SESSION SET TIMEZONE='America/Chicago';
SELECT CURRENT_TIME();


-- 11.9.5  Run the following commands to obtain the current date and time.

SELECT CURRENT_DATE();
SELECT CURRENT_TIMESTAMP();


-- 11.9.6  Compare the three (3) TIMESTAMP types and the output of the following
--         query.

SELECT
  CURRENT_TIMESTAMP()::TIMESTAMP_TZ AS TZ
  , CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS NTZ
  , CURRENT_TIMESTAMP()::TIMESTAMP_LTZ AS LTZ;

--         Take note of the differences between each of the time zones listed
--         here. How do they differ from each other?
--         - TIMESTAMP_LTZ internally stores UTC time with a specified
--         precision. However, all operations are performed in the current
--         session’s time zone, controlled by the TIMEZONE session parameter.
--         - TIMESTAMP_NTZ internally stores wallclock time with a specified
--         precision. All operations are performed without taking any time zone
--         into account. If the output format contains a time zone, the UTC
--         indicator (Z) is displayed.
--         - TIMESTAMP_TZ internally stores UTC time together with an associated
--         time zone offset. When a time zone is not provided, the session time
--         zone offset is used. All operations are performed with the time zone
--         offset specific to each record.
--         Snowflake Variant Data Types
--         Snowflake supports several semi-structured data types. This activity
--         walks you through the basics of the variant data type using JSON
--         data. The example data used in this lab is sourced out of the
--         TRAINING_DB.WEATHER schema.

-- 11.9.7  Set the following context.

USE ROLE SYSADMIN;
USE DATABASE training_db;
USE SCHEMA weather;
USE WAREHOUSE USERLAB_adm_query_wh;
ALTER SESSION SET ROWS_PER_RESULTSET=10;


-- 11.9.8  Once you have set the context, run the following query on
--         ISD_2019_TOTAL table.

--SELECT * FROM isd_2019_total;


-- 11.9.9  Click on one (1) of the JSON fields in the result window and observe
--         an improved presentation of the JSON data.
--         When you click on the JSON field you will see the data displayed in
--         an easier to read format in the far right area.

-- 11.9.10 Use the GET_DDL function to retrieve the current DDL associated with
--         the table.

--SELECT get_ddl('table', 'training_db.weather.isd_2019_total');

--create or replace TABLE ISD_2019_TOTAL (
--	V VARIANT,
--	T TIMESTAMP_NTZ(9)
--);

--         This function produces the following output when you click on the
--         result field:

-- 11.9.11 Run a simple query against this table using a filter while isolating
--         selected columns from the JSON weather data:

--SELECT T, V:STATION.COUNTRY::STRING, V
--  FROM isd_2019_total
--  WHERE T >= TO_DATE('2019-07-04')
--    and V:STATION:COUNTRY::STRING like 'US';

--         Did you get the results you expected?
--         - Answer: No. You would have received the error Query produced no
--         results.

-- 11.9.12 Try a different version of the query with slight changes to the case.

--SELECT T, V:station.country::STRING, V
--  FROM isd_2019_total
--  WHERE T >= TO_DATE('2019-07-04')
--    and V:station:country::STRING like 'US';

--         As is evident in the two (2) differing results, the JSON schema is
--         case sensitive.
--         Snowflake also supports an Array data type.

-- 11.9.13 Run the following SQL commands and identify the functions and
--         capabilities of the ARRAY data type.

SELECT ARRAY_CONSTRUCT('E1','E2','E3','E4','E5','E6');

SELECT ARRAY_TO_STRING(ARRAY_CONSTRUCT('E1','E2','E3','E4'),'|');

SELECT ARRAY_SLICE(ARRAY_CONSTRUCT('E1','E2','E3','E4','E5','E6'),3,5);


-- 11.9.14 Data type conversions.
--         Snowflake provides several approaches to cast and convert between
--         data types.

-- 11.9.15 Use the CAST function or the CAST operator ( CAST (source data as
--         target data type) or ::)

SELECT CAST(12.12345 AS FLOAT), CAST(12.12345 AS INTEGER), CAST(12.12345 AS STRING);

-- Note that in Snowflake, casting 12.5 as an integer rounds up to 13.
SELECT CAST(12.5 AS FLOAT), CAST(12.5 AS INTEGER), CAST(12.5 AS STRING);


-- 11.9.16 Use the :: operator:

SELECT 12.12345::FLOAT, 12.12345::INTEGER, 12.12345::STRING;


-- 11.9.17 In addition to the two (2) ways of using cast, Snowflake supports
--         many conversion functions such as the following:

SELECT TO_NUMBER('11.543', 6, 2);

SELECT DATEDIFF(DAY, CURRENT_DATE(),TO_DATE('2019-07-04'));


-- 11.10.0 Operators
--         Snowflake supports several different operators; including numeric
--         operators, query operators, Boolean operators, set operators, and
--         subquery operators. You will work with a small number of the
--         available operators.

-- 11.10.1 Here are some examples of selected arithmetic operators.

SELECT 3.2 + 5;

SELECT '4' + 2;

SELECT MOD(3, 2) AS MOD1, MOD(4.5, 1.2) AS MOD2;


-- 11.10.2 Run an example of a query operator.

USE SCHEMA USERLAB_adm_db.public;
CREATE OR REPLACE TABLE T1 (V VARCHAR);
CREATE OR REPLACE TABLE T2 (I INTEGER);
INSERT INTO T1 (V) VALUES ('Adams, Douglas');
INSERT INTO T2 (I) VALUES (42);

--         The following operation will fail because the data types do not match
--         in the first select and the second select

SELECT V FROM T1
  UNION
SELECT I FROM T2;

--         The following operation will succeed because the data type VARCHAR is
--         specified as part of the select

SELECT V::VARCHAR FROM t1
  UNION
SELECT I::VARCHAR FROM t2;


-- 11.10.3 Cleanup objects.
USE ROLE SYSADMIN;
DROP DATABASE  IF EXISTS USERLAB_adm_temp_db;
DROP DATABASE  IF EXISTS USERLAB_adm_test_db;
DROP WAREHOUSE IF EXISTS USERLAB_adm_query_wh;


-- 11.11.0 Key Takeaways
--         - Snowflake supports ANSI standard SQL with some extensions.
--         - Snowflake supports four types of tables, permanent, transient,
--         temporary, and external.
--         - It is possible to query against JSON semi-structured data stored in
--         a VARIANT data type.
