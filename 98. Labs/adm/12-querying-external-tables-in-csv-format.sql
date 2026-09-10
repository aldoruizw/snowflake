
-- 12.0.0  Querying External Tables in CSV Format
--         - Get to know your external data files
--         - Create a file format appropriate for the CSV data files
--         - Example 1: Schema on Read - simplest DDL example to get started
--         with external tables, no knowledge of schema required
--         - Learn how to query this first version of external table
--         - Understand query result cache for external tables
--         - Example 2: Virtual Columns scenario for when you are familiar with
--         the schema of the source data files
--         - Learn how to query this second version of an external table
--         - Learn query optimization techniques such as LIMIT - pushdown is
--         applied to external tables as well
--         - Example 3: Create an example of a partitioned external table for
--         better query performance
--         - Learn how to query this third version of an external table
--         - Partition feature is a common technique to improve query
--         performance of external tables

-- 12.1.0  Load Lab SQL file

-- 12.1.1  To load the SQL file, in the left navigation bar, select Projects,
--         then, under My Workspace, select the lab SQL file corresponding to
--         this lab exercise.

-- 12.1.2  Set query tag for this session.

ALTER SESSION SET query_tag = '(PONY) lab - TOPIC: Querying External Tables in CSV format';


-- 12.2.0  Create Database And Warehouse

-- 12.2.1  Create database.

USE ROLE adm_role;
CREATE DATABASE  IF NOT EXISTS PONY_adm_db
COMMENT='Database for Admin course labs';


-- 12.2.2  Create warehouse.

CREATE WAREHOUSE IF NOT EXISTS PONY_adm_wh
    WAREHOUSE_SIZE=XSmall
    INITIALLY_SUSPENDED=True
    AUTO_SUSPEND=300
    COMMENT='Warehouse for Admin course labs';


-- 12.3.0  Set the Context

-- 12.3.1  Execute the following SQL statements to set context and lab
--         configuration properties.

USE SCHEMA PONY_adm_db.public;
ALTER SESSION SET USE_CACHED_RESULT = true;


-- 12.3.2  Familiarize yourself with data files staged on an external stage.

-- 12.3.3  Examine the location of the following staged files:

LIST @training_db.traininglab.ed_stage/finwire;


-- 12.3.4  Now let’s take a look at how these files are formatted:

SELECT $1 
FROM @training_db.traininglab.ed_stage/finwire limit 10;


-- 12.3.5  Create the appropriate file format for the CSV data files:

CREATE OR REPLACE FILE FORMAT TXT_FIXED_WIDTH
  TYPE = CSV
  COMPRESSION = 'AUTO'
  FIELD_DELIMITER = NONE
  RECORD_DELIMITER = '\\n' -- if this string is found treat as a new line
  SKIP_HEADER = 0
  TRIM_SPACE = FALSE
  ERROR_ON_COLUMN_COUNT_MISMATCH = TRUE
  NULL_IF = ('\\N'); -- if this string is found treat as a null value.


-- 12.4.0  Create a Simple CREATE EXTERNAL TABLE DDL Example

-- 12.4.1  Demonstrate schema on read.
--         You are only required to have some knowledge of the file format and
--         record format of the source data files. No knowledge of the schema of
--         the data files is required at this point.

CREATE OR REPLACE EXTERNAL TABLE finwire
  LOCATION = @training_db.traininglab.ed_stage/finwire
  FILE_FORMAT = (FORMAT_NAME = 'txt_fixed_width');

SHOW EXTERNAL TABLES;


-- 12.5.0  Query an External Table.
--         All external tables include the following column:
--         - VALUE: a VARIANT type column that represents a single row in the
--         external file.

-- 12.5.1  When queried external tables cast all regular or semi-structured data
--         to a VARIANT in the VALUE column.

SELECT * FROM finwire
LIMIT 10;

--         – Check the output of the query by describing the results – Notice
--         that even though the data is coming from CSV files, the output is a
--         VARIANT.

DESC RESULT LAST_QUERY_ID();


-- 12.5.2  Re-execute the above query again. Does a query on an external table
--         make use of the result cache?.

SELECT * FROM finwire
LIMIT 10;


--         Review the Query Profile for this external table query to confirm
--         QUERY RESULT REUSE.
--         While external files are not cached, query results on an external
--         table are cached by Snowflake.

-- 12.6.0  Query Individual Parts in a Column List

SELECT
SUBSTR($1, 8, 15) AS PTS,
SUBSTR($1, 23, 3) AS REC_TYPE,
SUBSTR($1, 26, 60) AS COMPANY_NAME
FROM finwire
LIMIT 10;

-- Compare the output of this query to the one above by describing the result
-- Notice using a SUBSTR function converts the data type to a VARCHAR. 
 
DESC RESULT LAST_QUERY_ID();


-- 12.7.0  Review the Query Profile

-- 12.7.1  Run the following query and then review the Query Profile.

SELECT
SUBSTR($1, 8, 15) AS PTS,
SUBSTR($1, 23, 3) AS REC_TYPE,
SUBSTR($1, 26, 60) AS COMPANY_NAME
FROM finwire
WHERE rec_type = 'FIN' limit 10;

--         There is no runtime data caching on a virtual warehouse for external
--         table queries.

-- 12.7.2  The pseudo-column identifying the name of each staged data file is
--         included in the external table.
--         Note that this pseudo-column also includes its path in the stage.

SELECT value, metadata$filename
FROM finwire
LIMIT 10;


-- 12.8.0  Create an External Table with Virtual Columns
--         We will use this external table in a later scenario once you are more
--         familiar with the schema of the source data files.
--         You can create additional virtual columns as expressions using the
--         VALUE column and/or the METADATA$FILENAME pseudo-column. When the
--         external data is scanned, the data types of any specified fields in
--         the data file must match the data types of these additional columns
--         in the external table. This allows strong type checking and schema
--         validation over the external data.

-- 12.8.1  Execute the following DDL.

CREATE OR  REPLACE EXTERNAL TABLE finwire2
(
  PTS VARCHAR(15) AS SUBSTR($1, 8, 15)
, REC_TYPE VARCHAR(3) AS SUBSTR($1, 23, 3)
, COMPANY_NAME VARCHAR(60) AS SUBSTR($1, 26, 60)
, CIK VARCHAR(10) AS SUBSTR($1, 86, 10)
, STATUS VARCHAR(4) AS IFF(SUBSTR($1, 23, 3)
    = 'CMP', SUBSTR($1, 96, 4),SUBSTR($1, 47, 4))
, INDUSTRY_ID VARCHAR(2) AS SUBSTR($1, 100, 2)
, SP_RATING VARCHAR(4) AS SUBSTR($1, 102, 4)
, FOUNDING_DATE VARCHAR(8) AS SUBSTR($1, 106, 8)
, ADDR_LINE1 VARCHAR(80) AS SUBSTR($1, 114, 80)
, ADDR_LINE2 VARCHAR(80) AS SUBSTR($1, 194, 80)
, POSTAL_CODE VARCHAR(12) AS SUBSTR($1, 274, 12)
, CITY VARCHAR(25) AS SUBSTR($1, 286, 25)
, STATE_PROVINCE VARCHAR(20) AS SUBSTR($1, 311, 20)
, COUNTRY VARCHAR(24) AS SUBSTR($1, 331, 24)
, CEO_NAME VARCHAR(46) AS SUBSTR($1, 355, 46)
, DESCRIPTION VARCHAR(150) AS SUBSTR($1, 401, 150)
, YEAR VARCHAR(4) AS SUBSTR($1, 8, 4)
, QUARTER VARCHAR(1) AS SUBSTR($1, 30, 1)
, QTR_START_DATE VARCHAR(8) AS SUBSTR($1, 31, 8)
, POSTING_DATE VARCHAR(8) AS SUBSTR($1, 39, 8)
, REVENUE VARCHAR(17) AS SUBSTR($1, 47, 17)
, EARNINGS VARCHAR(17) AS SUBSTR($1, 64, 17)
, EPS VARCHAR(12) AS SUBSTR($1, 81, 12)
, DILUTED_EPS VARCHAR(12) AS SUBSTR($1, 93, 12)
, MARGIN VARCHAR(12) AS SUBSTR($1, 105, 12)
, INVENTORY VARCHAR(17) AS SUBSTR($1, 117, 17)
, ASSETS VARCHAR(17) AS SUBSTR($1, 134, 17)
, LIABILITIES VARCHAR(17) AS SUBSTR($1, 151, 17)
, SH_OUT VARCHAR(13)AS IFF(SUBSTR($1, 23, 3)
    = 'FIN', SUBSTR($1, 168, 13), SUBSTR($1, 127, 13))
, DILUTED_SH_OUT VARCHAR(13) AS SUBSTR($1, 181, 13)
, CO_NAME_OR_CIK VARCHAR(60) AS IFF(SUBSTR($1, 23, 3)
    = 'FIN', SUBSTR($1, 194, 10), SUBSTR($1, 168, 10))
, SYMBOL VARCHAR(15) AS SUBSTR($1, 26, 15)
, ISSUE_TYPE VARCHAR(6) AS SUBSTR($1, 41, 6)
, NAME VARCHAR(70) AS SUBSTR($1, 51, 70)
, EX_ID VARCHAR(6) AS SUBSTR($1, 121, 6)
, FIRST_TRADE_DATE VARCHAR(8) AS SUBSTR($1, 140, 8)
, FIRST_TRADE_EXCHG VARCHAR(8) AS SUBSTR($1, 148, 8)
, DIVIDEND VARCHAR(12) AS SUBSTR($1, 156, 12)
)
location = @training_db.traininglab.ed_stage/finwire
file_format = (format_name = 'txt_fixed_width');


-- 12.8.2  Execute the following query and review the Query Profile.

SELECT *
   FROM finwire2
   WHERE rec_type = 'FIN' limit 10;

--         Notice the pruning metric in the above query’s profile. The query is
--         not scanning the entire data set. Where did this optimization come
--         from? Hint: note the LIMIT clause.

-- 12.8.3  Add a filter for the year and quarter info and compute aggregate and
--         sum for the revenue total.

SELECT co_name_or_cik
 , year
 , quarter
 , sum(revenue::number) as revenue_total
  FROM finwire2
  WHERE rec_type='FIN'
  and year='1967' and quarter='2'
  GROUP BY 1,2,3;


-- 12.9.0  Create a Partitioned External Table Example
--         The partition column is defined by the PARTITION BY clause. This
--         clause can include any part of the external file path. Pruning for
--         performance is possible against expressions that are defined in the
--         PARTITION BY clause.
--         Before querying and examining the Query Profile (as outlined in the
--         next step), list the FINWIRE directory and confirm separate files
--         have been created based on the year and quarter. These should include
--         items such as FINWIRE2016Q3.
--         This should be relatable behavior for anyone who has worked with
--         other big data querying technologies, such as Hadoop (Hive, Impala,
--         Pig, etc.) all of which use a similar approach when partitioning
--         tables.

LIST @training_db.traininglab.ed_stage/finwire;


-- 12.9.1  Execute this new DDL command as follows.

CREATE OR REPLACE EXTERNAL TABLE finwire3
(
  YEAR  VARCHAR(4) AS SUBSTR(METADATA$FILENAME, 16, 4)
, QUARTER VARCHAR(1) AS SUBSTR(METADATA$FILENAME, 21, 1)
, thestring varchar(90) AS  SUBSTR(METADATA$FILENAME, 1, 50)
, PTS VARCHAR(15) AS SUBSTR($1, 8, 15)
, REC_TYPE VARCHAR(3) AS SUBSTR($1, 23, 3)
, COMPANY_NAME VARCHAR(60) AS SUBSTR($1, 26, 60)
, CIK VARCHAR(10) AS SUBSTR($1, 86, 10)
, STATUS VARCHAR(4) AS IFF(SUBSTR($1, 23, 3)
    = 'CMP', SUBSTR($1, 96, 4),SUBSTR($1, 47, 4))
, INDUSTRY_ID VARCHAR(2) AS SUBSTR($1, 100, 2)
, SP_RATING VARCHAR(4) AS SUBSTR($1, 102, 4)
, FOUNDING_DATE VARCHAR(8) AS SUBSTR($1, 106, 8)
, ADDR_LINE1 VARCHAR(80) AS SUBSTR($1, 114, 80)
, ADDR_LINE2 VARCHAR(80) AS SUBSTR($1, 194, 80)
, POSTAL_CODE VARCHAR(12) AS SUBSTR($1, 274, 12)
, CITY VARCHAR(25) AS SUBSTR($1, 286, 25)
, STATE_PROVINCE VARCHAR(20) AS SUBSTR($1, 311, 20)
, COUNTRY VARCHAR(24) AS SUBSTR($1, 331, 24)
, CEO_NAME VARCHAR(46) AS SUBSTR($1, 355, 46)
, DESCRIPTION VARCHAR(150) AS SUBSTR($1, 401, 150)
, QTR_START_DATE VARCHAR(8) AS SUBSTR($1, 31, 8)
, POSTING_DATE VARCHAR(8) AS SUBSTR($1, 39, 8)
, REVENUE VARCHAR(17) AS SUBSTR($1, 47, 17)
, EARNINGS VARCHAR(17) AS SUBSTR($1, 64, 17)
, EPS VARCHAR(12) AS SUBSTR($1, 81, 12)
, DILUTED_EPS VARCHAR(12) AS SUBSTR($1, 93, 12)
, MARGIN VARCHAR(12) AS SUBSTR($1, 105, 12)
, INVENTORY VARCHAR(17) AS SUBSTR($1, 117, 17)
, ASSETS VARCHAR(17) AS SUBSTR($1, 134, 17)
, LIABILITIES VARCHAR(17) AS SUBSTR($1, 151, 17)
, SH_OUT VARCHAR(13)AS IFF(SUBSTR($1, 23, 3)
    = 'FIN', SUBSTR($1, 168, 13), SUBSTR($1, 127, 13))
, DILUTED_SH_OUT VARCHAR(13) AS SUBSTR($1, 181, 13)
, CO_NAME_OR_CIK VARCHAR(60) AS IFF(SUBSTR($1, 23, 3)
    = 'FIN', SUBSTR($1, 194, 10), SUBSTR($1, 168, 10))
, SYMBOL VARCHAR(15) AS SUBSTR($1, 26, 15)
, ISSUE_TYPE VARCHAR(6) AS SUBSTR($1, 41, 6)
, NAME VARCHAR(70) AS SUBSTR($1, 51, 70)
, EX_ID VARCHAR(6) AS SUBSTR($1, 121, 6)
, FIRST_TRADE_DATE VARCHAR(8) AS SUBSTR($1, 140, 8)
, FIRST_TRADE_EXCHG VARCHAR(8) AS SUBSTR($1, 148, 8)
, DIVIDEND VARCHAR(12) AS SUBSTR($1, 156, 12)
)
partition by (year,quarter)
location = @training_db.traininglab.ed_stage/finwire
file_format = (format_name = 'txt_fixed_width');


-- 12.9.2  Execute the following query against the new external table finwire3.

SELECT co_name_or_cik
  ,year
  ,quarter
  ,sum(revenue::number) as revenue_total
FROM finwire3
WHERE rec_type='FIN'
AND year='1967' and quarter='2'
GROUP BY 1,2,3;


-- 12.9.3  Review the Query Profile after the query completes.
--         Notice the pruning metric which is a result of the performance
--         benefit of the PARTITION BY clause.

-- 12.10.0 Key Takeaways
--         - Snowflake supports using external tables to support data lake
--         access.
--         - External tables can use partitioning to improve performance access.
