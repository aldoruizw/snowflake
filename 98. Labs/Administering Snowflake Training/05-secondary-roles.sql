
-- 5.0.0   Secondary Rol
--         By the end of this lab, you will be able to:
--         - Determine Privileges (GRANTs)
--         - Grant Permissions (GRANT ROLE and GRANT USAGE)
--         - Use Secondary Roles to aggregate permissions from more than one
--         role
--         The purpose of this lab is to familiarize you with secondary roles
--         and how you can use them to access both a primary role and a
--         secondary role already granted to the user within a single session.

-- 5.1.0   Scenario
--         You are going to execute the command USE SECONDARY ROLES to aggregate
--         permissions from all roles that have been granted to your user.
--         - You will create a new user called USERLAB_adm_tester and two roles
--         called USERLAB_adm_roletest1 and USERLAB_adm_roletest2.
--         - Grant permissions on customer and orders table in
--         USERLAB_adm_db.manufacturing schema.
--         - You will login as the USERLAB_adm_tester user in a browser session
--         and open up a worksheet.
--         - You will query the orders table. Then you will try to query the
--         customer tables and it will fail.
--         - You will enable secondary roles and try accessing the customer
--         table and it will be successful.
--         - You will write a query that combines data from both customer and
--         orders while secondary roles are enabled.
--         - You will then disable secondary roles.
--         - You will next set USERLAB_adm_roletest2 role as your primary role
--         and enable secondary roles.
--         - You will then try to create a table called customer_orders which
--         combines data from both orders and customers.
--         - This Create statement will fail as Create is allowed only by the
--         USERLAB_adm_roltest1 which is not the primary role.
--         - Finally, you will switch to USERLAB_adm_roletest1, enable secondary
--         roles and create the table.

-- 5.2.0   Load Lab SQL File

-- 5.2.1   To load the SQL file, in the left navigation bar, select Projects,
--         then, under My Workspace, select the lab SQL file corresponding to
--         this lab exercise.

-- 5.2.2   Set query tag for this session.

ALTER SESSION SET query_tag = '(USERLAB) lab - TOPIC: Secondary roles';


-- 5.2.3   Cleanup any users from labs first.

USE ROLE SECURITYADMIN;

show users like 'USERLAB%';
DROP USER IF EXISTS USERLAB_adm_tester;


-- 5.2.4   Create the database.
USE ROLE SYSADMIN;
CREATE DATABASE IF NOT EXISTS USERLAB_adm_db 
COMMENT='Database for Admin labs';


-- 5.2.5   Create the warehouse.


CREATE WAREHOUSE IF NOT EXISTS USERLAB_adm_wh 
COMMENT='Warehouse for admin labs';
USE WAREHOUSE USERLAB_adm_wh;


-- 5.2.6   Create two new roles.
--         We will create two new roles to test secondary roles.

USE ROLE SECURITYADMIN;
CREATE ROLE IF NOT EXISTS USERLAB_adm_roletest1 COMMENT='Admin labs: Role for secondary roles';
CREATE ROLE IF NOT EXISTS USERLAB_adm_roletest2 COMMENT='Admin labs: Role for secondary roles';


-- 5.2.7   Create a user called USERLAB_adm_tester for secondary role testing.
--         We will now create a user to test secondary roles. Since this is a
--         temporary user we will bypass MFA for 2 hours. After 2 hours the user
--         will be subject to MFA prompting at login.

USE ROLE SECURITYADMIN;
CREATE USER IF NOT EXISTS USERLAB_adm_tester
  DEFAULT_SECONDARY_ROLES = ()
  --MUST_CHANGE_PASSWORD=true
  PASSWORD = 'USERLAB'
  TYPE = LEGACY_SERVICE
  MUST_CHANGE_PASSWORD = FALSE;
--ALTER USER USERLAB_adm_tester SET MINS_TO_BYPASS_MFA = 120;


-- 5.2.8   Grant the two roles to the USERLAB_adm_tester.
--         Grant previously created two roles to the new user.
USE ROLE SECURITYADMIN;
GRANT ROLE USERLAB_adm_roletest1 to USER USERLAB_adm_tester;
GRANT ROLE USERLAB_adm_roletest2 to USER USERLAB_adm_tester;


-- 5.2.9   Create a manufacturing schema and create two new tables.
--         Create a new schema and two new tables to test secondary roles.
USE ROLE SYSADMIN;
CREATE OR REPLACE SCHEMA USERLAB_adm_db.manufacturing;
CREATE OR REPLACE TABLE USERLAB_adm_db.manufacturing.customer 
AS SELECT * FROM snowflake_sample_data.tpch_sf1.customer;
CREATE OR REPLACE TABLE USERLAB_adm_db.manufacturing.orders  
AS SELECT * FROM snowflake_sample_data.tpch_sf1.orders;


-- 5.2.10  Grant privileges on the manufacturing schema and ORDERS, CUSTOMER
--         tables to the two roles created earlier.
--         Grant privileges on the two tables created to the two roles. Notice
--         how USERLAB_adm_roletest1 and USERLAB_adm_roletest2 have different
--         privileges.
USE ROLE SECURITYADMIN;

GRANT USAGE ON DATABASE USERLAB_adm_db to USERLAB_adm_roletest1;
GRANT USAGE ON DATABASE USERLAB_adm_db to USERLAB_adm_roletest2;

GRANT USAGE ON SCHEMA USERLAB_adm_db.manufacturing to USERLAB_adm_roletest1;
GRANT USAGE ON SCHEMA USERLAB_adm_db.manufacturing to USERLAB_adm_roletest2;

GRANT SELECT ON USERLAB_adm_db.manufacturing.orders to role USERLAB_adm_roletest1;
GRANT ALL ON USERLAB_adm_db.manufacturing.customer to role USERLAB_adm_roletest2;

GRANT ALL ON SCHEMA USERLAB_adm_db.manufacturing to role USERLAB_adm_roletest1;

GRANT USAGE ON WAREHOUSE USERLAB_adm_wh to role USERLAB_adm_roletest1;
GRANT USAGE ON WAREHOUSE USERLAB_adm_wh to role USERLAB_adm_roletest2;


-- 5.3.0   Use Secondary Roles To Aggregate Permissions From More Than One Role

-- 5.3.1   Reset password for user USERLAB_adm_tester and log in.
--         The command below will return a URL. Click the URL to set the
--         USERLAB_adm_tester user’s password, and then log in to the training
--         account with the new credentials.

--ALTER USER USERLAB_adm_tester RESET PASSWORD;


-- 5.3.2   Load the SQL file used in this lab. In the left navigation bar, hover
--         over Projects, then select Workspaces.

-- 5.3.3   In the upper-left of the Workspaces page, in the My Workspaces pane,
--         click the + Add new button.

-- 5.3.4   Select Upload Files from the drop-down menu.

-- 5.3.5   Navigate to the location where you downloaded the lab files. Open the
--         folder corresponding to your assigned animal user, then select the
--         SQL file corresponding to this lab exercise. Click Open.

-- 5.3.6   To load the SQL file, under My Workspace select the lab SQL file
--         corresponding to this lab exercise.

-- 5.3.7   Move to the step that instructs you to login as USERLAB_adm_tester
--         and run the following. Confirm secondary roles are not enabled
--         currently.
--         Once you log in as the USERLAB_adm_tester, run the following commands
--         to test the secondary roles.

-- as USERLAB_adm_tester
USE ROLE USERLAB_adm_roletest1;

-- Shows no secondary roles are active currently.
SELECT CURRENT_SECONDARY_ROLES();


-- 5.3.8   Query Customer table, this query will fail as USERLAB_adm_roletest1
--         does not have privileges to query the table.

USE WAREHOUSE USERLAB_adm_wh;

-- The following query will succeed.
SELECT * FROM USERLAB_adm_db.manufacturing.orders;

-- The following query will fail with a SQL compilation error.
SELECT * FROM USERLAB_adm_db.manufacturing.customer;


-- 5.3.9   Enable secondary roles and rerun the CUSTOMER query.
--         Enable secondary roles, confirm that they are enabled and run the
--         query below.

USE SECONDARY ROLE ALL;

-- Confirm secondary roles are now active.

SELECT CURRENT_SECONDARY_ROLES();


SELECT * FROM USERLAB_adm_db.manufacturing.customer;
-- The query succeeds because customer table as the privileges are aggregated from more than one role.


-- 5.3.10  Query both CUSTOMER and ORDERS tables.


-- Confirm secondary roles are still active.

SELECT CURRENT_SECONDARY_ROLES();

SELECT C_CUSTKEY,C_NAME, C_ADDRESS,O_ORDERSTATUS,O_TOTALPRICE  
FROM USERLAB_adm_db.manufacturing.CUSTOMER C
JOIN USERLAB_adm_db.manufacturing.ORDERS O
ON O.O_CUSTKEY=C.C_CUSTKEY;

-- This query succeeds once again as the privileges are aggregated from more than one role.


-- 5.3.11  Make USERLAB_adm_roletest2 the current role and run the query again.

USE ROLE USERLAB_adm_roletest2;

-- Confirm secondary roles are still active.

SELECT CURRENT_SECONDARY_ROLES();

SELECT C_CUSTKEY,C_NAME, C_ADDRESS,O_ORDERSTATUS,O_TOTALPRICE  
FROM USERLAB_adm_db.manufacturing.CUSTOMER C
JOIN USERLAB_adm_db.manufacturing.ORDERS O
ON O.O_CUSTKEY=C.C_CUSTKEY;

-- The query succeeds as the privileges are aggregated from more than one role.


-- 5.4.0   Testing Create Table With Secondary Roles Enabled

-- 5.4.1   While secondary roles are enabled, create a table using the CUSTOMER
--         and ORDERS tables as USERLAB_adm_roletest2.

USE ROLE USERLAB_adm_roletest2;
CREATE OR REPLACE TABLE USERLAB_adm_db.manufacturing.CUSTOMER_ORDERS
AS SELECT C_CUSTKEY,C_NAME, C_ADDRESS,O_ORDERSTATUS,O_TOTALPRICE  
FROM USERLAB_adm_db.manufacturing.CUSTOMER C
JOIN USERLAB_adm_db.manufacturing.ORDERS O
ON O.O_CUSTKEY=C.C_CUSTKEY;

-- This query fails with SQL access control error. This means the role USERLAB_adm_roletest2 does not have privileges to create tables.

--         With SECONDARY ROLES ALL set, the current user can use any privilege
--         from any role that the user has been granted, except CREATE. A CREATE
--         statement is permitted only if it has been granted to the currently-
--         selected, active role in the session.

-- 5.4.2   Switch to USERLAB_adm_roletest1 and try to create the table.


USE ROLE USERLAB_adm_roletest1;

SELECT CURRENT_SECONDARY_ROLES();

CREATE TABLE USERLAB_adm_db.manufacturing.CUSTOMER_ORDERS
AS SELECT C_CUSTKEY,C_NAME, C_ADDRESS,O_ORDERSTATUS,O_TOTALPRICE  
FROM USERLAB_adm_db.manufacturing.CUSTOMER C
JOIN USERLAB_adm_db.manufacturing.ORDERS O
ON O.O_CUSTKEY=C.C_CUSTKEY;

-- The query succeeds USERLAB_adm_roletest1 has privileges to create tables in the manufacturing schema and it is the primary role.


-- 5.4.3   Disable secondary roles.

USE SECONDARY ROLE NONE;
SELECT CURRENT_SECONDARY_ROLES();


-- 5.4.4   Signout as USERLAB_adm_tester and log back in to the account as
--         USERLAB.
--         We have now completed the testing as USERLAB_adm_tester. Sign out
--         from the Snowsight UI.
--         Next login as the USERLAB.

-- 5.4.5   Drop user USERLAB_adm_tester as USERLAB user.
--         Open the SQL file relevant for this lab and scroll down to the drop
--         statement.
--         – As USERLAB user drop the user created previously.
USE ROLE SECURITYADMIN;
DROP USER USERLAB_adm_tester;
DROP ROLE USERLAB_ADM_ROLETEST1;
DROP ROLE USERLAB_ADM_ROLETEST2;

ALTER SESSION UNSET query_tag;

-- 5.5.0   Key Takeaways
--         - Secondary roles can be used to aggregate permission in a single
--         session.
--         - You can only create objects if the primary role has permission to
--         do that.
