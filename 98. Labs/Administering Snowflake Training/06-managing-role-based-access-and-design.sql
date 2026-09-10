
-- 6.0.0   Managing Role-Based Access and Design
--         By the end of this lab you will be able to:
--         - Create functional roles and grant to yourself to test.
--         - Use access roles to grant access to functional roles.
--         - Understand the outcome of granting access from access roles to
--         functional roles.
--         - Test access by switching roles, creating and querying tables.
--         - Create a table using one role which is instantly available for read
--         access by another role.
--         - Understand which SHOW commands can be used to quickly verify and
--         audit access to objects.

-- 6.1.0   Scenario
--         In this lab, a production environment will be created for a new
--         inventory system data store. The following access roles will be set
--         up for this new environment:
--         - USERLAB_adm_edw_useradmin - Role to create roles and users
--         - USERLAB_adm_edw_sysadmin - Role to create and manage the database
--         and database objects.
--         - USERLAB_adm_edw_inventory_rw - A role with read/write access to
--         load and manage the inventory data.
--         - USERLAB_adm_edw_inventory_r - A role with read access to the
--         inventory data.
--         In addition to the access roles above, there will be two function
--         based roles created.
--         NOTE: in the real world it is common for these roles to be setup and
--         synchronized through Azure Active Directory (AAD) or similar identity
--         provider. With AAD for instance, an AAD group and the users in the
--         group would be added as a role with users in Snowflake.
--         The following functional roles will be set up for this new
--         environment:
--         - USERLAB_adm_edw_elt - Role containing users tasked with managing
--         the data in the new inventory system.
--         - USERLAB_adm_edw_analyst - Role containing users tasked with
--         analyzing the inventory data.
--         The diagram below depicts the role hierarchy and the corresponding
--         privileges assigned to each role. For simplicity, only a selection of
--         privileges granted to each role is shown.
--         - To create the initial environment and ensure the functional roles
--         will work going forward, you will switch to each of these roles.
--         - Set up the roles for the environment.
--         - Create a small dataset.
--         - Use the roles to load and query the data.
--         Having set up access, you need to test each function based role works
--         as expected and explore the Snowflake SHOW commands used to verify
--         and audit access.
--         Finally, you’ll review the deployment script used by the system
--         administrator to help understand the configuration needed when
--         deploying schemas within a database.

-- 6.2.0   Initial and Target State

-- 6.2.1   You will be creating the deployment.
--         Notice this has three main sections:
--         - Create the environment and access roles using USERLAB_adm_role
--         - Creating the database, schema(s), tables and a warehouse using
--         USERLAB_adm_edw_sysadmin
--         - Grant access to the objects for the access roles.
--         The sample database will consist of 4 tables with test data. For this
--         lab, the tables and data will be created from the old system for
--         testing purposes. The new system is being designed and will be
--         implemented later in the year.
--         The tables are:
--         - Date_dim - Each row represents one calendar day
--         - Storage_warehouse - Each row represents a storage/shipping
--         warehouse
--         - Item - Each row represents an item stored in a storage_warehouse
--         - Inventory - Each row represents the quantity of an item in a
--         warehouse
--         This SQL code is not intended as a complete RBAC solution, but to
--         help provide a framework to deploy a scalable and simple
--         architecture.

-- 6.3.0   Load Lab SQL file

-- 6.3.1   To load the SQL file, in the left navigation bar, select Projects,
--         then, under My Workspace, select the lab SQL file corresponding to
--         this lab exercise.

-- 6.3.2   Set query tag for this session.

ALTER SESSION SET query_tag = '(USERLAB) lab - TOPIC: Data Security';
USE SECONDARY ROLE NONE;

-- 6.3.3   Next Create your database.

USE ROLE SYSADMIN;
CREATE DATABASE  IF NOT EXISTS USERLAB_adm_db
COMMENT='Database for Admin course labs';


-- 6.3.4   Create your warehouse.
USE ROLE SYSADMIN;
CREATE WAREHOUSE IF NOT EXISTS USERLAB_adm_wh
    WAREHOUSE_SIZE=XSmall
    INITIALLY_SUSPENDED=True
    AUTO_SUSPEND=300
    COMMENT='Warehouse for Admin course labs';


-- 6.3.5   Call the procedure training_db.admin.setup_adm_edw_roles_privs to
--         manage the grants using elevated privileges.
--         The Educational Services team has previously created a SQL stored
--         procedure to assist you with this lab. The procedure will do the
--         following:
--         - Drop custom roles previously created - Create custom roles for
--         USERLAB_adm_edw_useradmin, USERLAB_adm_edw_sysadmin - Grant custom
--         roles to SYSADMIN - Grant create database on account
--         USERLAB_adm_edw_sysadmin - Grant create warehouse on account to
--         USERLAB_adm_edw_sysadmin - Grant create role on account to
--         USERLAB_adm_edw_useradmin - Grant custom roles to animal name

USE ROLE SYSADMIN;
USE DATABASE USERLAB_adm_db;
USE WAREHOUSE USERLAB_adm_wh;



SHOW  PROCEDURES IN SCHEMA training_db.admin ;
SELECT "name", "arguments" FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
WHERE "name" like 'SETUP%'
  ;

-- Cleanup any previously created edw roles/objects if you are rerunning this lab. 
CALL training_db.admin.setup_adm_edw_roles_privs(p_username=>'USERLAB', p_operation=>'DROP');

-- Create new EDWS roles for USERLAB_adm_edw_sysadmin, USERLAB_adm_useradmin
CALL training_db.admin.setup_adm_edw_roles_privs(p_username=>'USERLAB', p_operation=>'ADD');
SHOW ROLES LIKE  '%USERLAB_%edw%';


-- 6.3.6   Using the USERLAB_adm_edw_sysadmin role, create a database called
--         USERLAB_adm_edw_db and a managed access schema with some sample data.
--         It is best practice to create a Managed Access schema to support
--         future grants without using the SECURITYADMIN role. Managed Access
--         schemas are covered in a later lesson in this course. Every schema
--         must be owned by the environment’s sysadmin role, as this will manage
--         all objects.

-- Create USERLAB_adm_edw_db
USE ROLE USERLAB_adm_edw_sysadmin;
CREATE DATABASE IF NOT EXISTS  USERLAB_adm_edw_db 
COMMENT = ' Database for Admin labs';


-- Create managed access schema 
USE DATABASE USERLAB_adm_edw_db;
CREATE OR REPLACE SCHEMA inventory WITH MANAGED ACCESS;
USE SCHEMA inventory;
CREATE TABLE date_dim  LIKE         snowflake_sample_data.tpcds_sf10tcl.date_dim;
CREATE TABLE storage_warehouse LIKE snowflake_sample_data.tpcds_sf10tcl.warehouse;
CREATE TABLE item      LIKE         snowflake_sample_data.tpcds_sf10tcl.item;
CREATE TABLE inventory LIKE         snowflake_sample_data.tpcds_sf10tcl.inventory;



-- 6.3.7   Create database access roles that will secure access to the schema
--         and grant access roles to USERLAB_edw_sysadmin role to be able to
--         manage these.

USE ROLE USERLAB_adm_edw_useradmin;

CREATE OR REPLACE ROLE USERLAB_adm_edw_inventory_r       comment = 'Admin labs - Access Role: Grants READ access to all objects in schema';
CREATE OR REPLACE ROLE USERLAB_adm_edw_inventory_rw      comment = 'Admin labs - Access Role: Grants READ/WRITE access to all objects in schema';

GRANT ROLE USERLAB_adm_edw_inventory_R to role USERLAB_adm_edw_sysadmin;
GRANT ROLE USERLAB_adm_edw_inventory_RW to role USERLAB_adm_edw_sysadmin;


-- 6.3.8   Grant privileges on the USERLAB_adm_edw_db to access roles.

USE ROLE USERLAB_adm_edw_sysadmin;

-- Database usage
GRANT USAGE ON DATABASE USERLAB_adm_edw_db to role USERLAB_adm_edw_inventory_r;
GRANT USAGE ON DATABASE USERLAB_adm_edw_db to role USERLAB_adm_edw_inventory_rw;

-- Schema usage
GRANT USAGE ON SCHEMA INVENTORY to role USERLAB_adm_edw_inventory_r;
GRANT USAGE ON SCHEMA INVENTORY to role USERLAB_adm_edw_inventory_rw;


-- 6.3.9   Grant privileges on current grants to access roles.

-- As USERLAB_adm_edw_sysadmin role, grant read/usage privileges to USERLAB_edw_inventory_r role 

GRANT SELECT ON ALL TABLES IN               SCHEMA inventory TO ROLE USERLAB_adm_edw_inventory_r;
GRANT SELECT ON ALL VIEWS  IN               SCHEMA inventory TO ROLE USERLAB_adm_edw_inventory_r;
GRANT SELECT ON ALL MATERIALIZED VIEWS  IN  SCHEMA inventory TO ROLE USERLAB_adm_edw_inventory_r;
GRANT USAGE, READ ON ALL STAGES IN          SCHEMA inventory TO ROLE USERLAB_adm_edw_inventory_r;
GRANT USAGE ON ALL FILE FORMATS IN          SCHEMA inventory TO ROLE USERLAB_adm_edw_inventory_r;
GRANT SELECT ON ALL STREAMS IN              SCHEMA inventory TO ROLE USERLAB_adm_edw_inventory_r;
GRANT USAGE ON ALL FUNCTIONS IN             SCHEMA inventory TO ROLE USERLAB_adm_edw_inventory_r;
GRANT USAGE ON ALL PROCEDURES IN            SCHEMA inventory TO ROLE USERLAB_adm_edw_inventory_r;
GRANT USAGE ON ALL SEQUENCES IN             SCHEMA inventory TO ROLE USERLAB_adm_edw_inventory_r;

-- Grant read, insert, update, delete, references, write, usage privileges to  USERLAB_adm_edw_inventory_rw role

GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES ON ALL TABLES IN schema inventory TO ROLE USERLAB_adm_edw_inventory_rw;
GRANT SELECT ON ALL VIEWS  IN               schema inventory TO ROLE USERLAB_adm_edw_inventory_rw;
GRANT SELECT ON ALL MATERIALIZED VIEWS  IN  schema inventory TO ROLE USERLAB_adm_edw_inventory_rw;
GRANT USAGE, READ, WRITE ON ALL STAGES IN   schema inventory TO ROLE USERLAB_adm_edw_inventory_rw;
GRANT USAGE ON ALL FILE FORMATS IN          schema inventory TO ROLE USERLAB_adm_edw_inventory_rw;
GRANT SELECT ON ALL STREAMS IN              schema inventory TO ROLE USERLAB_adm_edw_inventory_rw;
GRANT USAGE ON ALL FUNCTIONS IN             schema inventory TO ROLE USERLAB_adm_edw_inventory_rw;
GRANT USAGE ON ALL PROCEDURES IN            schema inventory TO ROLE USERLAB_adm_edw_inventory_rw;
GRANT USAGE ON ALL SEQUENCES IN             schema inventory TO ROLE USERLAB_adm_edw_inventory_rw;


-- 6.3.10  FUTURE Grants: Automatically re-grant if new objects created.



-- As USERLAB_adm_edw_sysadmin role , grant read, usage privileges to USERLAB_edw_inventory_r role for future objects

GRANT SELECT ON FUTURE TABLES IN               SCHEMA inventory TO ROLE USERLAB_adm_edw_inventory_r;
GRANT SELECT ON FUTURE VIEWS  IN               SCHEMA inventory TO ROLE USERLAB_adm_edw_inventory_r;
GRANT SELECT ON FUTURE MATERIALIZED VIEWS  IN  SCHEMA inventory TO ROLE USERLAB_adm_edw_inventory_r;
GRANT USAGE, READ ON FUTURE STAGES IN          SCHEMA inventory TO ROLE USERLAB_adm_edw_inventory_r;
GRANT USAGE ON FUTURE FILE FORMATS IN          SCHEMA inventory TO ROLE USERLAB_adm_edw_inventory_r;
GRANT SELECT ON FUTURE STREAMS IN              SCHEMA inventory TO ROLE USERLAB_adm_edw_inventory_r;
GRANT USAGE ON FUTURE FUNCTIONS IN             SCHEMA inventory TO ROLE USERLAB_adm_edw_inventory_r;
GRANT USAGE ON FUTURE PROCEDURES IN            SCHEMA inventory TO ROLE USERLAB_adm_edw_inventory_r;
GRANT USAGE ON FUTURE SEQUENCES IN             SCHEMA inventory TO ROLE USERLAB_adm_edw_inventory_r;


-- Grant read, insert, update, delete, references, write, usage privileges to USERLAB_adm_edw_inventory_rw role for future objects

GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES
      ON FUTURE TABLES IN                      SCHEMA inventory TO ROLE USERLAB_adm_edw_inventory_rw;
GRANT SELECT ON FUTURE VIEWS  IN               SCHEMA inventory TO ROLE USERLAB_adm_edw_inventory_rw;
GRANT SELECT ON FUTURE MATERIALIZED VIEWS  IN  SCHEMA inventory TO ROLE USERLAB_adm_edw_inventory_rw;
GRANT USAGE, READ, WRITE ON FUTURE STAGES IN   SCHEMA inventory TO ROLE USERLAB_adm_edw_inventory_rw;
GRANT USAGE ON FUTURE FILE FORMATS IN          SCHEMA inventory TO ROLE USERLAB_adm_edw_inventory_rw;
GRANT SELECT ON FUTURE STREAMS IN              SCHEMA inventory TO ROLE USERLAB_adm_edw_inventory_rw;
GRANT USAGE ON FUTURE FUNCTIONS IN             SCHEMA inventory TO ROLE USERLAB_adm_edw_inventory_rw;
GRANT USAGE ON FUTURE PROCEDURES IN            SCHEMA inventory TO ROLE USERLAB_adm_edw_inventory_rw;
GRANT USAGE ON FUTURE SEQUENCES IN             SCHEMA inventory TO ROLE USERLAB_adm_edw_inventory_rw;



-- 6.3.11  Grant usage on your USERLAB_adm_wh warehouse to the access roles you
--         created.

USE ROLE SYSADMIN;
GRANT USAGE ON WAREHOUSE USERLAB_adm_wh TO USERLAB_adm_edw_inventory_r;
GRANT USAGE ON WAREHOUSE USERLAB_adm_wh TO USERLAB_adm_edw_inventory_rw;
GRANT USAGE ON WAREHOUSE USERLAB_adm_wh TO USERLAB_adm_edw_sysadmin;


-- 6.4.0   Create Roles and Grants

-- 6.4.1   Create roles.
--         Create function based for each group of users. Typically these roles
--         describe the employee role or a class of automated access (for
--         example, ELT job). In this case, everyone on the training course will
--         share access to these roles.

-- 6.4.2   Requirements for roles.
--         For this test version of the new inventory system, only two roles
--         will be required:
--         - The function based role USERLAB_ADM_EDW_ELT needs read/write access
--         to the objects in the INVENTORY schema
--         - The function based role USERLAB_ADM_EDW_ANALYST needs only Read
--         access to the objects in the INVENTORY schema
--         - Both roles need Usage access to the warehouse

USE ROLE USERLAB_adm_edw_useradmin;
CREATE  ROLE IF NOT EXISTS USERLAB_adm_edw_analyst COMMENT= 'Admin labs - Access role: analyst role';
CREATE  ROLE IF NOT EXISTS USERLAB_adm_edw_elt COMMENT= 'Admin labs - Access role : elt role';


-- Grant roles to current user
GRANT ROLE USERLAB_adm_edw_analyst   TO USER USERLAB;
GRANT ROLE USERLAB_adm_edw_elt       TO USER USERLAB;


-- 6.4.3   Grant the required access role for each function based role.

GRANT ROLE USERLAB_adm_edw_inventory_r TO ROLE USERLAB_adm_edw_analyst;
GRANT ROLE USERLAB_adm_edw_inventory_rw TO ROLE USERLAB_adm_edw_elt;


-- 6.5.0   Use the show command to show the access available to each role.
--         Starting at the bottom of the hierarchy with the access roles since
--         these are the roles with access to the database object (ie:
--         databases, schemas, tables, etc.).

-- 6.5.1   Show roles.
--         Use the show roles to show the roles created above.

USE ROLE USERLAB_adm_edw_analyst;
USE WAREHOUSE USERLAB_adm_wh;
SHOW ROLES LIKE '%USERLAB%';

-- Format output
SELECT "name"
,      "owner"
,      "comment"
FROM TABLE(result_scan(last_query_id()));

--         The output from the query above shows the list of roles created. The
--         comments are highly recommended to ensure there’s a record of the
--         purpose of each role.

-- 6.5.2   Show grants on the readonly access role.

SHOW GRANTS TO ROLE USERLAB_adm_edw_inventory_r;

--         The USERLAB_adm_edw_inventory_r shows usage on the database/schema
--         and select on each of the tables. It also has usage access on the
--         warehouse.

-- 6.5.3   Show grants on the read/write access role.

SHOW GRANTS TO ROLE USERLAB_adm_edw_inventory_rw;

--         The USERLAB_adm_edw_inventory_rw shows usage on the database/schema
--         and select, insert, update, delete, and reference on each of the
--         tables. It too has usage on the warehouse.

-- 6.5.4   Show the access available to the roles.
--         The analyst and elt roles are the next layer in the role hierarchy.
--         These are the roles users will use to load and query the data.

-- 6.5.5   Run the following SQL to show access available to the analyst role.

SHOW GRANTS TO ROLE USERLAB_adm_edw_analyst;

--         The output from the query shows the analyst role has usage on the
--         read only access role above. Remember, in Snowflake, if one role is
--         granted to another like USERLAB_edw_inventory_r has been granted to
--         the analyst role, the permissions roll up. This means the analyst
--         role gets all the permissions the read only role has. Because of
--         these permissions rolling up, the analyst can select from any table
--         in the inventory schema and use the warehouse.

-- 6.5.6   Run the following SQL to show access available to the ELT role.

SHOW GRANTS TO ROLE USERLAB_adm_edw_elt;

--         The output from this query shows the same situation as above only
--         with the read/write access role instead of the read only access role.
--         This provides the elt role to have read/write access on any table in
--         the inventory schema and can use the warehouse.

-- 6.6.0   Show access to the the database objects.

-- 6.6.1   Show tables in schema.
--         Use the Show tables to see the names of the tables in the schema and
--         which role owns each table.

USE ROLE USERLAB_adm_edw_analyst;
USE WAREHOUSE USERLAB_adm_wh;
USE SCHEMA USERLAB_adm_edw_db.inventory;
SHOW TABLES IN SCHEMA;


-- 6.6.2   Show access to database.
--         Check which roles have access to the database. We can confirm that
--         USERLAB_adm_edw_sysadmin is the owner of the database, and the two
--         access roles have usage access.

USE ROLE USERLAB_adm_edw_sysadmin;
SHOW GRANTS ON DATABASE USERLAB_adm_edw_db;

SELECT "privilege"
,      "name"
,      "granted_to"
,      "grantee_name"
FROM TABLE(result_scan(last_query_id()));


-- 6.6.3   Show grants on schema.
--         Check which roles have access to the schema. This command shows the
--         same access that the database has with the USERLAB_adm_edw_sysadmin
--         having ownership and the two access roles has usage access

SHOW GRANTS ON SCHEMA  USERLAB_adm_edw_db.inventory;

SELECT "privilege"
,      "name"
,      "granted_to"
,      "grantee_name"
FROM TABLE(result_scan(last_query_id()));


-- 6.7.0   Test the access of the analyst and elt roles by loading some data and
--         running a report
--         Use the USERLAB_adm_edw_elt roles to load some of the inventory data
--         into the tables. Once the data is loaded, use the USERLAB_analyst
--         role to create a report. This ensures the two roles perform as
--         expected.

-- 6.7.1   Load some data from the old inventory system.
--         The data source for this test is the data in
--         SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL database. In the real world, this
--         data would most likely be converted and loaded from the older system
--         or an on-prem database. Use the USERLAB_adm_edw_elt role to copy the
--         data.

USE ROLE USERLAB_adm_edw_elt;
USE SCHEMA USERLAB_adm_edw_db.inventory;
USE WAREHOUSE USERLAB_adm_wh;
-- Start with the dimension tables, date_dim, warehouse, and item
-- Date_dim table
INSERT INTO date_dim
    SELECT * FROM
        snowflake_sample_data.tpcds_sf10tcl.date_dim;

-- Warehouse table. Limit the data to three states
INSERT INTO storage_warehouse
SELECT * FROM
    snowflake_sample_data.tpcds_sf10tcl.warehouse
    WHERE W_STATE IN ('TN', 'GA', 'FL');

-- Item table
INSERT INTO item
    SELECT * FROM
    snowflake_sample_data.tpcds_sf10tcl.item;

-- Inventory table. This is the fact table.
INSERT INTO inventory
    SELECT * FROM
        snowflake_sample_data.tpcds_sf10tcl.inventory 
WHERE INV_WAREHOUSE_SK IN (
        SELECT DISTINCT w_warehouse_sk
        FROM storage_warehouse);


-- 6.7.2   For the final check, switch to the USERLAB_analyst role and run a
--         report.
--         For the final test, run a common report used in the older inventory
--         system that showed the inventory in each warehouse by for the 2002
--         4th quarter.

USE ROLE USERLAB_adm_edw_analyst;
USE SCHEMA USERLAB_adm_edw_db.inventory;
USE WAREHOUSE USERLAB_adm_wh;

-- Run the report
SELECT  W_warehouse_name AS warehouse_name,
       d_date,
       any_value(W_city) AS warehouse_city ,
       any_value(w_state) AS warehouse_state,
       i_category AS category_name,
       i_class AS class_name,
       SUM(inv_quantity_on_hand) AS quantity_on_hand
FROM inventory
   JOIN storage_warehouse ON (inv_warehouse_sk=w_warehouse_sk)
   JOIN item ON (inv_item_sk=i_item_sk)
   JOIN date_dim ON (inv_date_sk = d_date_sk)
   WHERE D_QUARTER_NAME ='2002Q4'
   GROUP BY warehouse_name, d_date, category_name, class_name
   ORDER BY W_warehouse_name, d_date;


-- 6.7.3   Cleanup previously created objects if they exists.


USE ROLE USERLAB_adm_edw_sysadmin;
DROP DATABASE IF EXISTS USERLAB_adm_edw_db;
USE ROLE SYSADMIN;
CALL training_db.admin.setup_adm_edw_roles_privs(p_username=>'USERLAB', p_operation=>'DROP');

ALTER SESSION UNSET query_tag;
USE SECONDARY ROLE ALL;


-- 6.8.0   Key Takeaways
--         - It is recommended to separate the roles between access roles and
--         functional roles. Most organizations today will have some type of
--         single sign-on system used to create and manage the functional roles.
--         - Go to Admin, Users and Roles to visualize the organization you
--         created
--         - While the RBAC framework may seem a little complex at first glance,
--         in reality it simplifies the ongoing process of maintaining access
--         controls. In particular, it makes it easy to deploy or alter access
--         for functional Roles
--         - Applying grants at the schema level using Access roles simplifies
--         the process of auditing access as by default users have Read or
--         Read/Write access privileges.
--         - Finally, using a predefined method and naming standard enables
--         scripting of deployment and access control.
