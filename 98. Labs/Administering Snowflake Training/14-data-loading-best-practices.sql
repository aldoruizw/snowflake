
-- 14.0.0  Data Loading Best Practices
--         By the end of this lab, you will be able to:
--         - Compare the performance difference between loading many smaller
--         files compared to a single large file.
--         Snowflake recommends aiming to produce data files roughly 100-250 MB
--         compressed for more optimal price/performance. This lab exercise
--         shows the pitfall of loading large files (i.e., Larger than 250MB
--         compressed), which does not scale linearly.

-- 14.1.0  Scenario
--         In this exercise, you will create an empty table and first load 30
--         files, each about 100 MB compressed in size. Then you will remove the
--         rows and load one large file of about the same number of rows. You
--         will see a significant difference in the performance.

-- 14.2.0  Load Lab SQL file

-- 14.2.1  To load the SQL file, in the left navigation bar, select Projects,
--         then, under My Workspace, select the lab SQL file corresponding to
--         this lab exercise.

-- 14.2.2  Set query tag for this session.

ALTER SESSION SET query_tag = '(PONY) lab - TOPIC: Data Loading Best Practices';


-- 14.3.0  Create Database And Warehouse

-- 14.3.1  Create database.

USE ROLE adm_role;
CREATE DATABASE IF NOT EXISTS PONY_adm_db 
COMMENT='Database for Admin course labs';


-- 14.3.2  Create warehouse.

CREATE WAREHOUSE IF NOT EXISTS PONY_adm_wh
WAREHOUSE_SIZE=XSmall
INITIALLY_SUSPENDED=True
AUTO_SUSPEND=300
COMMENT='Warehouse for Admin course labs';


-- 14.4.0  Set context and list files to load

-- 14.4.1  Set your context.

USE SCHEMA PONY_adm_db.public;
ALTER SESSION SET USE_CACHED_RESULT = FALSE;


-- 14.4.2  Run the following list command to review the set of input files for
--         data loading.

ls @training_db.traininglab.ed_stage/load_file_size_100mb;

--         Notice there is a set of files that are split into reasonable size
--         for efficient ingestion (total of 30 100MB files)

-- 14.4.3  Note there is one file that is very large (3GB size for this one
--         file).

ls @training_db.traininglab.ed_stage/load_file_size_3gb;


-- 14.5.0  Create and load a table using many files

-- 14.5.1  Create an empty line item table.

CREATE OR REPLACE TABLE PONY_lineitem_fs like training_Db.tpch_sf1.lineitem;


-- 14.5.2  Alter the warehouse and set it to size large.

ALTER WAREHOUSE PONY_adm_wh SET warehouse_size = large WAIT_FOR_COMPLETION = TRUE;
USE WAREHOUSE PONY_adm_wh;

--         Note: For this lab you will set the initial warehouse size to large.
--         However, later in the lab you will try using a smaller warehouse
--         size.

-- 14.5.3  Load the set of data files that follow the best practice file size
--         recommendation.
--         This will run for about 20 seconds with the large warehouse size.

COPY INTO PONY_lineitem_fs
FROM @training_db.traininglab.ed_stage/load_file_size_100mb
FILE_FORMAT = (FORMAT_NAME = training_db.traininglab.MYGZIPPIPEFORMAT)
PATTERN='.*[.]tbl[.]gz';


-- 14.5.4  Check that about 84 million rows were added.

SELECT COUNT(*) FROM PONY_lineitem_fs;


-- 14.5.5  Delete the rows using the TRUNCATE command.

TRUNCATE TABLE PONY_lineitem_fs;


-- 14.5.6  Suspend and Resume the warehouse to flush the warehouse cache.

ALTER WAREHOUSE PONY_adm_wh suspend;

ALTER WAREHOUSE PONY_adm_wh resume;


-- 14.6.0  Load The Table Using One Large File

-- 14.6.1  Load a single large file (containing a similar number of records as
--         the thirty 100MB files above).
--         Observe the data loading job takes significantly longer and runs for
--         about 8 minutes with a large warehouse size. This step is optional.

COPY INTO PONY_lineitem_fs
FROM @training_db.traininglab.ed_stage/load_file_size_3gb
FILE_FORMAT = (FORMAT_NAME = training_db.traininglab.MYGZIPPIPEFORMAT)
PATTERN='.*[.]tbl[.]gz';


-- 14.6.2  Check that about 86 million rows were added.

SELECT COUNT(*) FROM PONY_lineitem_fs;


-- 14.7.0  Re-run exercise using smaller warehouse size

-- 14.7.1  Reset WAREHOUSE size back to XSmall.

ALTER WAREHOUSE PONY_adm_wh SET warehouse_size = xsmall WAIT_FOR_COMPLETION = TRUE;


-- 14.7.2  Suspend and Resume the warehouse to flush the warehouse cache.

ALTER WAREHOUSE PONY_adm_wh suspend;

ALTER WAREHOUSE PONY_adm_wh resume;


-- 14.7.3  Delete the rows using the TRUNCATE command.

TRUNCATE TABLE PONY_lineitem_fs;


-- 14.7.4  Load the set of data files that follow the best practice file size
--         recommendation.
--         This will run for about 1 minute 7 seconds with the xsmall warehouse
--         size.

COPY INTO PONY_lineitem_fs
FROM @training_db.traininglab.ed_stage/load_file_size_100mb
FILE_FORMAT = (FORMAT_NAME = training_db.traininglab.MYGZIPPIPEFORMAT)
PATTERN='.*[.]tbl[.]gz';


-- 14.7.5  Check that about 84 million rows were added.

SELECT COUNT(*) FROM PONY_lineitem_fs;


-- 14.7.6  Delete the rows using the TRUNCATE command.

TRUNCATE TABLE PONY_lineitem_fs;


-- 14.8.0  Load the table using one large file

-- 14.8.1  Suspend and resume the warehouse to flush the warehouse cache.

ALTER WAREHOUSE PONY_adm_wh SUSPEND;

ALTER WAREHOUSE PONY_adm_wh RESUME;


-- 14.8.2  Load single large file (containing a similar number of records as the
--         thirty 100MB files above).
--         Observe that using an xsmall warehouse to load one large file takes
--         roughly the same amount of time as it takes to load the same file
--         using a large warehouse.

COPY INTO PONY_lineitem_fs
FROM @training_db.traininglab.ed_stage/load_file_size_3gb
FILE_FORMAT = (FORMAT_NAME = training_db.traininglab.MYGZIPPIPEFORMAT)
PATTERN='.*[.]tbl[.]gz';


-- 14.8.3  Check that about 86 million rows were added.

SELECT COUNT(*) FROM PONY_lineitem_fs;


-- 14.8.4  Run the commands below to clear out the objects used in this lab:

USE ROLE adm_role;
USE SCHEMA PONY_adm_db.public;
DROP TABLE PONY_lineitem_fs;

ALTER WAREHOUSE PONY_adm_wh SUSPEND;


-- 14.9.0  Key Takeaways
--         - It is more efficient to load many right-sized files rather than one
--         large file.
--         - Selecting a larger warehouse may not dramatically improve data
--         loading times.
