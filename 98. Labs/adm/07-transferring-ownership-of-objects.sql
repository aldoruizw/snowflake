
-- 7.0.0   Transferring Ownership of Objects
--         In this lab you will practice the following:
--         - Transferring ownership of objects from one role to another.
--         - Using the COPY CURRENT GRANTS and REVOKE CURRENT GRANTS arguments.

-- 7.1.0   Load Lab SQL file

-- 7.1.1   To load the SQL file, in the left navigation bar, select Projects,
--         then, under My Workspace, select the lab SQL file corresponding to
--         this lab exercise.

-- 7.2.0   Lab Setup

-- 7.2.1   Set query tag for this session.

ALTER SESSION SET query_tag = '(USERLAB) lab - TOPIC: Transferring Ownership of Objects';
USE SECONDARY ROLE NONE;

-- 7.2.2   Create the database.

USE ROLE SYSADMIN;
CREATE DATABASE IF NOT EXISTS USERLAB_adm_db
COMMENT='Database for Admin labs';
USE DATABASE USERLAB_adm_db;
USE SCHEMA USERLAB_adm_db.public;


-- 7.2.3   Create the warehouse.

CREATE WAREHOUSE IF NOT EXISTS USERLAB_adm_wh 
COMMENT='Warehouse for admin labs';
USE WAREHOUSE USERLAB_adm_wh;


-- 7.2.4   Set some prerequisite objects for the lab.

ALTER WAREHOUSE USERLAB_adm_wh SET WAREHOUSE_SIZE = 'xsmall'  wait_for_completion = TRUE;
ALTER SESSION SET use_cached_result = false;


-- 7.2.5   Create the base table for testing.

CREATE OR REPLACE TABLE my_test_table as 
SELECT * FROM snowflake_sample_data.tpch_sf1.customer;

--         Validate that the current role, ADM_ROLE, owns the table.

SHOW GRANTS ON my_test_table;

SHOW TABLES LIKE 'my_test_table' IN SCHEMA USERLAB_adm_db.public;

--         Validate that the current role, ADM_ROLE, can successfully SELECT and
--         DELETE from the table.

SELECT * FROM my_test_table ORDER BY c_custkey;

DELETE FROM my_test_table WHERE c_custkey = 1;


-- 7.2.6   Create some roles and grant privileges for testing.
--         - Role USERLAB_adm_role_a will only have SELECT on the table. - Role
--         USERLAB_adm_role_b will have ALL privileges on the table. - Roles
--         USERLAB_adm_role_a and USERLAB_adm_role_b have been granted to
--         ADM_ROLE to build a role hierarchy.

USE ROLE SECURITYADMIN;
CREATE OR REPLACE ROLE USERLAB_adm_role_a COMMENT='Admin labs: Role for transferring object ownership testing';
CREATE OR REPLACE ROLE USERLAB_adm_role_b COMMENT='Admin labs: Role for transferring object ownership testing';


-- Build a role hierarchy by granting the two new roles to adm_role
GRANT ROLE USERLAB_adm_role_a TO ROLE SYSADMIN;
GRANT ROLE USERLAB_adm_role_b TO ROLE SYSADMIN;

USE ROLE SECURITYADMIN;

GRANT USAGE ON DATABASE USERLAB_adm_db TO ROLE USERLAB_adm_role_a;
GRANT USAGE ON SCHEMA USERLAB_adm_db.public TO ROLE USERLAB_adm_role_a;
GRANT SELECT ON TABLE USERLAB_adm_db.public.my_test_table TO ROLE USERLAB_adm_role_a;
GRANT USAGE ON WAREHOUSE USERLAB_adm_wh TO ROLE USERLAB_adm_role_a;

GRANT USAGE ON DATABASE USERLAB_adm_db TO ROLE USERLAB_adm_role_b;
GRANT USAGE ON SCHEMA USERLAB_adm_db.public TO ROLE USERLAB_adm_role_b;
GRANT ALL ON TABLE USERLAB_adm_db.public.my_test_table TO ROLE USERLAB_adm_role_b;
GRANT USAGE ON WAREHOUSE USERLAB_adm_wh TO ROLE USERLAB_adm_role_b;


-- 7.3.0   Validating Privileges
--         Role USERLAB_adm_role_a has SELECT on the table, Role
--         USERLAB_adm_role_b has ALL privileges on the table, and ADM_ROLE owns
--         the table.
USE ROLE SYSADMIN;
SHOW GRANTS ON my_test_table;


-- 7.3.1   Ensure that Role USERLAB_adm_role_a has only SELECT on the table.

USE ROLE USERLAB_adm_role_a;

SELECT * FROM my_test_table ORDER BY c_custkey;
-- succeeds

DELETE FROM my_test_table WHERE c_custkey = 2;
-- fails. cannot delete, only has SELECT privilege



-- 7.3.2   Ensure that Role USERLAB_adm_b has ALL privileges on the table.

USE ROLE USERLAB_adm_role_b;

SELECT * FROM my_test_table ORDER BY c_custkey;
-- succeeds

DELETE FROM my_test_table WHERE c_custkey = 2;
-- can delete, has ALL privileges



-- 7.4.0   Transferring Ownership With COPY CURRENT GRANTS
--         In this section, we will transfer ownership of the table from
--         ADM_ROLE to Role USERLAB_adm_role_a with COPY CURRENT GRANTS.
--         COPY_CURRENT_GRANTS will have the effect of MAINTAINING any and all
--         explicitly-defined grants on the table after ownership is
--         transferred.
--         Note: A role that has the MANAGE GRANTS privilege can transfer
--         ownership of an object to any role; in contrast, a role that does not
--         have the MANAGE GRANTS privilege can only transfer ownership from
--         itself to a child role within the role hierarchy.
--         In our lab environment, we do not have MANAGE GRANTS privilege ON
--         ACCOUNT granted to the ADM_ROLE. Therefore the GRANT OWNERSHIP with
--         COPY CURRENT GRANTS will require us to have a role hierarchy so that
--         we can transfer the grants to a child role.

-- 7.4.1   Validate current grants.

SHOW GRANTS ON my_test_table;


-- 7.4.2   Transfer ownership from ADM_ROLE to Role USERLAB_adm_role_a.

USE ROLE SYSADMIN;

GRANT OWNERSHIP 
    ON TABLE USERLAB_adm_db.public.my_test_table
    TO ROLE USERLAB_adm_role_a
    COPY CURRENT GRANTS;


-- 7.4.3   Validate current grants.

SHOW GRANTS ON my_test_table;


-- 7.4.4   Run some statements to determine which roles can operate on the
--         table.

USE ROLE SYSADMIN;

SELECT * FROM USERLAB_adm_db.public.my_test_table;
-- This command works as adm_role inherits privileges through the child role USERLAB_adm_role_a


--         COPY CURRENT GRANTS will have the effect of maintaining any and all
--         explicitly-defined grants on the object after ownership is
--         transferred, however, note that once ownership is transferred, then
--         the previous owner will lose ownership of the object as well as all
--         privileges that came along as a consequence of ownership.
--         Role USERLAB_adm_role_a now owns the table, and can do anything with
--         it.

USE ROLE USERLAB_adm_role_a;

SELECT * FROM my_test_table ORDER BY c_custkey;
-- can still SELECT

DELETE FROM my_test_table WHERE c_custkey = 4;
-- but can now also DELETE


--         Role USERLAB_adm_b still has all privileges on the table, resulting
--         from COPY_CURRENT_GRANTS above.

USE ROLE USERLAB_adm_role_b;

SELECT * FROM my_test_table ORDER BY c_custkey;
-- can still SELECT

DELETE FROM my_test_table WHERE c_custkey = 5;
-- can still DELETE


--         Role USERLAB_adm_role_a now owns the table, Role USERLAB_adm_b still
--         has all privileges, and ADM_ROLE has no privileges whatsoever.

SHOW GRANTS ON my_test_table;


-- 7.5.0   Transferring Ownership with REVOKE CURRENT GRANTS
--         Now, let’s see the impact of REVOKE CURRENT GRANTS.
--         We’ll transfer ownership back to ADM_ROLE. Recall, role
--         USERLAB_adm_role_a currently owns the table, role USERLAB_adm_role_b
--         currently has all privileges on the table, and ADM_ROLE has
--         absolutely no privileges on the table.
--         REVOKE_CURRENT_GRANTS will have the effect of REMOVING any and all
--         explicitly-defined grants on the table after ownership is
--         transferred. This may be desirable in the event the new owning role
--         of the object wishes to begin with a blank slate, so to speak, and
--         take care of deciding which other roles, if any, should have which
--         privileges, if any, against the object that it has just assumed
--         ownership of.

-- 7.5.1   Validate current grants.

SHOW GRANTS ON my_test_table;


-- 7.5.2   Transfer ownership from Role USERLAB_role_a to ADM_ROLE.

USE ROLE USERLAB_adm_role_a;

GRANT ownership 
    ON TABLE USERLAB_adm_db.public.my_test_table
    TO ROLE SYSADMIN
    REVOKE CURRENT GRANTS;


-- 7.5.3   Validate current grants
--         Notice that all explicitly-defined grants have been revoked from all
--         roles given the REVOKE CURRENT GRANTS syntax. Only the newly-owning
--         role, ADM_ROLE, has privileges (acquired through ownership) on the
--         table now.

USE ROLE SYSADMIN;
SHOW GRANTS ON my_test_table;

--         ADM_ROLE can do whatever it wishes with the table, since ADM_ROLE
--         owns it.

USE ROLE SYSADMIN;
SELECT * FROM my_test_table ORDER BY c_custkey;
DELETE FROM my_test_table WHERE c_custkey = 6;

--         Role USERLAB_adm_role_a, the previous owner of the table, cannot do
--         anything.

USE ROLE USERLAB_adm_role_a;

-- fails
SELECT * FROM my_test_table ORDER BY c_custkey;

--         Role USERLAB_adm_b, who previously had ALL privileges on the table,
--         cannot do anything.

USE ROLE USERLAB_adm_role_b;

-- fails
SELECT * FROM my_test_table ORDER BY c_custkey;


-- 7.6.0   Cleanup

USE ROLE SYSADMIN;
DROP TABLE IF EXISTS USERLAB_adm_db.public.my_test_table;
ALTER WAREHOUSE USERLAB_adm_wh SUSPEND;

USE ROLE SECURITYADMIN;
DROP ROLE IF EXISTS USERLAB_adm_role_a;
DROP ROLE IF EXISTS USERLAB_adm_role_b;

ALTER SESSION UNSET query_tag;
USE SECONDARY ROLE ALL;


-- 7.7.0   Key Takeaways
--         - In this lab, we investigated the difference between COPY CURRENT
--         GRANTS and REVOKE CURRENT GRANTS when transferring ownership of an
--         object from one role to another role.
--         - COPY CURRENT GRANTS has the effect of maintaining any and all
--         explicitly-defined grants on the object after ownership is
--         transferred. Note that once ownership is transferred, then the
--         previous owner will lose ownership of the object as well as all
--         privileges that came along as a consequence of ownership. A role that
--         has the MANAGE GRANTS privilege can transfer ownership of an object
--         to any role; in contrast, a role that does not have the MANAGE GRANTS
--         privilege can only transfer ownership from itself to a child role
--         within the role hierarchy.
--         - REVOKE CURRENT GRANTS will have the effect of removing any and all
--         explicitly-defined grants on the object after ownership is
--         transferred to the new owning role. This may be desirable in the
--         event the new owning role of the object wishes to begin with a blank
--         slate, so to speak, and take care of deciding which other roles, if
--         any, should have which privileges, if any, against the object that it
--         has just assumed ownership of.
