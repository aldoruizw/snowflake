
-- 8.0.0   Managed Access Schemas
--         In this lab you will practice the following:
--         - Creating managed access and regular schemas
--         - Granting privileges to objects in managed access and regular
--         schemas

-- 8.1.0   Load Lab SQL File

-- 8.1.1   To load the SQL file, in the left navigation bar, select Projects,
--         then, under My Workspace, select the lab SQL file corresponding to
--         this lab exercise.

-- 8.1.2   Set query tag for this session.

ALTER SESSION SET query_tag = '(USERLAB) lab - TOPIC: Managed Access Schemas';
USE SECONDARY ROLE NONE;

-- 8.2.0   Create Database And Warehouse

-- 8.2.1   Create database.

USE ROLE SYSADMIN;
CREATE DATABASE IF NOT EXISTS USERLAB_adm_db 
COMMENT='Database for Admin course labs';


-- 8.2.2   Create warehouse.

CREATE WAREHOUSE IF NOT EXISTS USERLAB_adm_wh
    WAREHOUSE_SIZE=XSmall
    INITIALLY_SUSPENDED=True
    AUTO_SUSPEND=300
    COMMENT='Warehouse for Admin course labs';


-- 8.2.3   Set pre-reqs for this lab.

ALTER WAREHOUSE USERLAB_adm_wh SET WAREHOUSE_SIZE = 'xsmall';
ALTER SESSION SET use_cached_result = false;


-- 8.3.0   Creating Schemas

-- 8.3.1   Create the schemas.

-- Note that ADM_ROLE is used to created both schemas.
CREATE OR REPLACE SCHEMA USERLAB_adm_db.managed_access_no;
CREATE OR REPLACE SCHEMA USERLAB_adm_db.managed_access_yes with managed access;

-- Since the ADM_ROLE created both schemas, it owns both schemas.
SHOW SCHEMAS LIKE '%managed_access%' IN DATABASE USERLAB_adm_db;


-- 8.4.0   Issuing Grants and Creating Roles
--         In this section, we will build out the infrastructure that we will
--         use for the remainder of the lab.

-- 8.4.1   Grant PUBLIC role privileges.
--         Use the public role to create tables in both schemas.
USE ROLE SECURITYADMIN;
GRANT USAGE ON WAREHOUSE USERLAB_adm_wh TO ROLE public;
GRANT USAGE ON DATABASE USERLAB_adm_db TO ROLE public;

-- Grant usage and create table permissions on the manged_access_yes schema
GRANT USAGE ON SCHEMA USERLAB_adm_DB.managed_access_yes TO ROLE public;
GRANT CREATE TABLE ON SCHEMA USERLAB_adm_DB.managed_access_yes TO ROLE public;

-- Grant usage and create table permissions on the manged_access_no schema
GRANT USAGE ON SCHEMA USERLAB_adm_DB.managed_access_no TO ROLE public;
GRANT CREATE TABLE ON SCHEMA USERLAB_adm_DB.managed_access_no TO ROLE public;


-- 8.4.2   Create a new role for testing.

USE ROLE SECURITYADMIN;
CREATE OR REPLACE ROLE USERLAB_x;
GRANT ROLE USERLAB_x TO USER USERLAB;


-- 8.4.3   Create a table in each schema using role PUBLIC.

USE ROLE public;

CREATE OR REPLACE TABLE USERLAB_adm_DB.managed_access_yes.test
(c1 integer);

CREATE OR REPLACE TABLE USERLAB_adm_DB.managed_access_no.test
(c1 integer);


-- 8.5.0   Granting Privileges on Objects to Roles
--         In this section, we will test under which conditions the owner of the
--         two tables (public role) can and cannot grant privileges on the
--         tables to other roles.

-- note that PUBLIC owns both tables.
SHOW TABLES LIKE 'TEST' IN DATABASE USERLAB_adm_db;


-- 8.5.1   Try using PUBLIC to grant permissions on both tables.

-- This will work in the schema that doesn't have managed access set.
GRANT SELECT ON USERLAB_adm_DB.managed_access_no.test TO ROLE USERLAB_x;

-- But fails in the schema that has managed access set.
GRANT SELECT ON USERLAB_adm_DB.managed_access_yes.test TO ROLE USERLAB_x;

-- The schema owner, ADM_ROLE can grant permissions in the schema with
-- managed access set.

USE ROLE SYSADMIN;
GRANT SELECT ON USERLAB_adm_db.managed_access_yes.test TO ROLE USERLAB_x;


-- 8.6.0   Cleanup

-- use the adm_role role to drop the USERLAB_x role
USE ROLE SECURITYADMIN;
DROP ROLE IF EXISTS USERLAB_x;

-- Since adm_role owns the database and warehouse
-- Use it to revoke the public permissions from the database and warehouse
USE ROLE SYSADMIN;

REVOKE USAGE ON WAREHOUSE USERLAB_adm_wh FROM ROLE public;
REVOKE USAGE ON DATABASE USERLAB_adm_db FROM ROLE public;

-- Drop the two schemas created for this lab
DROP SCHEMA IF EXISTS USERLAB_adm_db.managed_access_yes;
DROP SCHEMA IF EXISTS USERLAB_adm_db.managed_access_no;

-- As a best practice, set the warehouse back to xsmall and suspend it.
ALTER WAREHOUSE USERLAB_adm_wh SET WAREHOUSE_SIZE = 'xsmall';
ALTER WAREHOUSE USERLAB_adm_wh SUSPEND;


-- 8.6.1   Unset the query tag.

ALTER SESSION UNSET query_tag;
USE SECONDARY ROLE ALL;

-- 8.7.0   Key Takeaways
--         - Managed access schemas centralize privilege management with the
--         schema owner.
--         - In regular schemas, the owner of an object (i.e. the role that has
--         the OWNERSHIP privilege on the object) can grant further privileges
--         on their objects to other roles.
--         - In managed access schemas, the schema owner manages all privilege
--         grants, including future grants, on objects in the schema. Object
--         owners retain the OWNERSHIP privileges on the objects; however, only
--         the schema owner can manage privilege grants on the objects.
