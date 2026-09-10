
-- 18.0.0  Recovering a Prior Version of a Dropped Schema
--         This lab should take you approximately 15 minutes to complete.
--         By the end of this lab, you will be able to:
--         - Recover a dropped schema to a prior version.
--         - Show schema history, and note when it might have been dropped.
--         This lab shows how you can recover an older version of a dropped
--         schema.

-- 18.1.0  Scenario
--         In this exercise, you will do the following:
--         You will create a schema and refer to it as version V1.
--         You will then drop the schema and create the schema again, and refer
--         to it as V2. However, in this version you will intentionally corrupt
--         the data.
--         Next, you will drop the schema and create the schema with a different
--         structure, which you will refer to as V3. Like before you will drop
--         the schema.
--         Since you want to get back to version V1 of the schema, you will walk
--         through the steps to get back to the correct version (V1).

-- 18.2.0  Load Lab SQL file

-- 18.2.1  To load the SQL file, in the left navigation bar, select Projects,
--         then, under My Workspace, select the lab SQL file corresponding to
--         this lab exercise.

-- 18.2.2  Ensure your active role is set to adm_role in the bottom left corner
--         of the UI.

-- 18.2.3  Set query tag for this session.

ALTER SESSION SET query_tag = '(PONY) lab - TOPIC: Database Point-In-Time Recovery';


-- 18.3.0  Set Up a Database and Schema for Test Table

-- 18.3.1  Set your context.

USE ROLE adm_role;
CREATE WAREHOUSE IF NOT EXISTS PONY_adm_wh;
USE WAREHOUSE PONY_adm_wh;
CREATE DATABASE IF NOT EXISTS PONY_adm_db;
USE SCHEMA PONY_adm_db.public;


-- 18.3.2  Create TAXDATA_DB database.

DROP DATABASE IF EXISTS PONY_taxdata_db;

CREATE DATABASE PONY_taxdata_db;


-- 18.4.0  Create Schema V1 Version
--         This is the correct schema version that we will want to recover.

CREATE SCHEMA dropSchema 
    COMMENT = 'V1';
USE SCHEMA dropSchema;


-- 18.4.1  Add taxpayer table to the first schema.

CREATE OR REPLACE TABLE PONY_taxdata_db.dropSchema.taxpayer
   AS SELECT * FROM training_tax_db.taxschema.taxpayer;


-- 18.4.2  Show TAXPAYER V1 data. This is the baseline table structure and data
--         that we will want to recover.

SELECT * FROM PONY_taxdata_db.dropSchema.taxpayer; -- 36 rows


-- 18.4.3  Capture the query_id from this query in a session variable. This will
--         be used to show the query history and get the SCHEMA_ID in a later
--         step.

SET first_qid =  last_query_id();


-- 18.4.4  Show dropSchema schema history.

SHOW SCHEMAS HISTORY LIKE 'dropSchema';
SELECT "name"
      ,"created_on"
      ,"owner"
      ,"comment"
      ,"dropped_on"
  FROM TABLE(result_scan(last_query_id()))
ORDER BY "dropped_on" DESC;

--         Note: DROPPED_ON=null means that this is the currently active (non-
--         dropped) schema version.

-- 18.4.5  DROP your dropSchema V1 schema.

DROP SCHEMA PONY_taxdata_db.dropSchema;


-- 18.4.6  Show schemas and show schemas history, and compare the output
--         columns.

SHOW SCHEMAS LIKE 'DROPSCHEMA';
SHOW SCHEMAS HISTORY LIKE 'DROPSCHEMA';


-- 18.4.7  Note the value of the dropped_on column from the SHOW SCHEMAS
--         HISTORY.

SELECT "name"
      ,"created_on"
      ,"owner"
      ,"comment"
      ,"dropped_on"
  FROM TABLE(result_scan(last_query_id()))
ORDER BY "dropped_on" DESC;


-- 18.5.0  Create Schema V2 Version

CREATE SCHEMA dropSchema 
    COMMENT = 'V2';
USE SCHEMA dropschema;


-- 18.5.1  Re-create TAXPAYER with the same structure as V1, but with corrupted
--         data.

CREATE OR REPLACE TABLE PONY_taxdata_db.dropSchema.taxpayer
   AS SELECT * FROM training_tax_db.taxschema.taxpayer;


-- 18.5.2  Corrupt the TAXPAYER V2 table data.

UPDATE PONY_taxdata_db.dropSchema.taxpayer
SET taxpayer_id=UNIFORM(10000,99999,ABS(RANDOM())),lastname=RANDSTR(30,RANDOM()),
firstname=RANDSTR(30,RANDOM());


-- 18.5.3  Show TAXPAYER V2 data, and note the corrupted data in the
--         TAXPAYER_ID, LASTNAME, & FIRSTNAME columns.

SELECT taxpayer_id,lastname,firstname,filing_status
FROM PONY_taxdata_db.dropSchema.taxpayer;


-- 18.5.4  Capture the query_id from this query in a session variable. This will
--         be used to show the query history and get the SCHEMA_ID in a later
--         step.

SET second_qid =  last_query_id();


-- 18.5.5  Show schemas history, you should see two schema versions.
--         Note the value of DROPPED_ON column.
--         - dropSchema V1: Has oldest creation date and shows a non-null value
--         of DROPPED_ON
--         - dropSchema V2: Has most current creation date, shows null value of
--         DROPPED_ON (since V2 is current version)

SHOW SCHEMAS HISTORY LIKE 'dropSchema';

SELECT "name"
      ,"created_on"
      ,"owner"
      ,"comment"
      ,"dropped_on"
    FROM TABLE(result_scan(last_query_id()))
ORDER BY "dropped_on" DESC;


-- 18.5.6  DROP your dropSchema V2 schema.

DROP SCHEMA PONY_taxdata_db.dropSchema;


-- 18.5.7  Show schemas history, you should see two schema versions.
--         Note the values of DROPPED_ON column again.
--         - dropSchema V1: Has oldest drop date
--         - dropSchema V2: Has most recent drop date

SHOW SCHEMAS HISTORY LIKE 'dropSchema';
SELECT "name"
      ,"created_on"
      ,"owner"
      ,"comment"
      ,"dropped_on"
  FROM TABLE(result_scan(last_query_id()))
ORDER BY "dropped_on" DESC;


-- 18.6.0  Create Schema V3 Version

CREATE SCHEMA dropSchema 
    COMMENT = 'V3';
USE SCHEMA dropschema;


-- 18.6.1  Re-create dropSchema with a different structure than V1 and V2, and
--         with corrupted data.

CREATE OR REPLACE TABLE PONY_taxdata_db.dropSchema.taxpayer
(
  id varchar(9),
  name1 varchar(30),
  name2 varchar(30),
  place varchar(20)
);


-- 18.6.2  Load corrupted data into dropSchema V3 schema.

INSERT INTO PONY_taxdata_db.dropSchema.taxpayer
SELECT uniform(10000,99999,abs(random())) as id, randstr(30,random()) as name1,
randstr(30,random()) as name2, randstr(20,random()) AS place
FROM TABLE(generator(rowcount => 5000));


-- 18.6.3  Show dropSchema V3 data, and note the different column structure.
--         Also corrupted data in the ID, NAME1, NAME2,and PLACE columns.

SELECT id,name1,name2,place
FROM PONY_taxdata_db.dropSchema.taxpayer;


-- 18.6.4  Capture the query_id from this query in a session variable. This will
--         be used to show the query history and get the SCHEMA_ID in a later
--         step.

SET third_qid =  last_query_id();


-- 18.6.5  Show schemas history, you should see 3 schema versions.
--         Note the value of DROPPED_ON column again.
--         - dropSchema V1: Has oldest drop date, shows non-null value of
--         DROPPED_ON
--         - dropSchema V2: Has next oldest drop date, shows non-null value of
--         DROPPED_ON
--         - dropSchema V3: Has most current creation date, and shows null value
--         of DROPPED_ON (the current version)

SHOW SCHEMAS HISTORY LIKE 'dropSchema';
SELECT "name"
      ,"created_on"
      ,"owner"
      ,"comment"
      ,"dropped_on"
  FROM TABLE(result_scan(last_query_id()))
ORDER BY "dropped_on" DESC;


-- 18.6.6  DROP your dropSchema V3 schema.

DROP SCHEMA PONY_taxdata_db.dropSchema;


-- 18.6.7  Show schemas history, you should see 3 schema versions.
--         Note value of DROPPED_ON.
--         - dropSchema V1: Has oldest drop date, shows non-null value of
--         DROPPED_ON
--         - dropSchema V2: Has next oldest drop date, shows non-null value of
--         DROPPED_ON
--         - dropSchema V3: Has most recent drop date, shows non-null value of
--         DROPPED_ON

SHOW SCHEMAS HISTORY LIKE 'DROPSCHEMA';
SELECT "name"
      ,"created_on"
      ,"owner"
      ,"comment"
      ,"dropped_on"
    FROM TABLE(result_scan(last_query_id()))
ORDER BY "dropped_on" DESC;

--         We want to restore dropSchema to version V1, since V1 was the correct
--         table structure and data.
--         Recall: If you issue an UNDROP SCHEMA, you will restore the most
--         recently dropped table version, which is V3 (a version that we do not
--         want).
--         At this point, you will want to see the results of the SCHEMATA view
--         for all three schemas. This may require some time to let the system
--         catch up. There can be a 5-6 minute latency before this information
--         is updated. We can also get the information we need with less
--         latency. The latency on the QUERY_HISTORY is less than the SCHEMATA
--         view but there is still some. In this query, you will not see the
--         schema version. You will want to select the version with the lowest
--         SCHEMA_ID.

-- 18.6.8  Verify (via schema_version column) that you see three versions of
--         DROPSCHEMA:
--         DROPSCHEMA V1: the oldest version of DROPSCHEMA (had correct data,
--         this is the one we will restore)
--         DROPSCHEMA V2: next oldest version of DROPSCHEMA (contains corrupt
--         data)
--         DROPSCHEMA V3: latest dropped version of DROPSCHEMA (has nex table
--         structure and incorrect data)
--         This query should return three rows. If it doesn’t, run it again
--         until it does.

SELECT  query_id, query_text,  schema_id, schema_name, end_time
FROM   SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE query_id IN ($first_qid, $second_qid, $third_qid)
ORDER BY end_time asc;


-- 18.6.9  Restore DROPSCHEMA V1 using the UNDROP command.
--         Replace  with the value of the schema_id column identified from the
--         prior query. Use the version with the lowest END_TIME.

UNDROP SCHEMA identifier(979);


-- 18.6.10 Verify that you have restored the correct DROPSCHEMA schema by
--         running SHOW SCHEMAS.

SHOW SCHEMAS history LIKE 'DROPSCHEMA';
SELECT  "name"
      ,to_timestamp_ntz(dateadd(hour, 8,"created_on")) as "created"
      ,to_timestamp_ntz(dateadd(hour, 8,"dropped_on")) as "dropped"
      ,"comment"
      ,"owner"
    FROM   table(result_scan(last_query_id()))
ORDER BY "dropped" DESC;

--         Notice DROPSCHEMA V2 and V3 still have a delete date but DROPSCHEMA
--         version 1’s delete date is NULL.

-- 18.6.11 View table contents of restored table. If it’s the first version of
--         the schema, it will have the TAXPAYER table with uncorrupted data.

SHOW TABLES IN SCHEMA DROPSCHEMA;

--- Verify the data is uncorrupted version.

select * from PONY_taxdata_db.dropschema.taxpayer;


-- 18.6.12 (Optional) Query the SCHEMATA view to see if the updated schema
--         history can be obtained.

SELECT  schema_id,
  schema_name,
  comment as schema_version,
  to_timestamp_ntz(dateadd(hour, 8,created)) as created,
  to_timestamp_ntz(dateadd(hour, 8,deleted)) as dropped,
  catalog_name AS database_name
FROM   SNOWFLAKE.ACCOUNT_USAGE.SCHEMATA
WHERE database_name = 'PONY_TAXDATA_DB'
AND  schema_name = 'DROPSCHEMA'
AND  dropped is not null
ORDER BY deleted DESC;

--         Note: It is possible that this still has not updated yet as there can
--         be a 5-6 minute latency on this view.

-- 18.6.13 Run the commands below to clear out the objects used in this lab:

USE ROLE adm_role;
USE SCHEMA PONY_adm_db.public;
DROP DATABASE PONY_taxdata_db;

ALTER WAREHOUSE PONY_adm_wh SUSPEND;


-- 18.7.0  Key Takeaways
--         - This lab shows how to use the newer UNDROP feature of using an
--         identifier to selectively UNDROP an object instead of having to
--         UNDROP and rename until the correct object is UNDROPPED.
--         - This feature will work with tables, schemas, and databases.
