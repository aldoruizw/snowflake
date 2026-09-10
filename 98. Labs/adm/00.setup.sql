USE ROLE SECURITYADMIN;
CREATE USER USERLAB
  PASSWORD = 'USERLAB'
  TYPE = LEGACY_SERVICE
  MUST_CHANGE_PASSWORD = FALSE;
GRANT ROLE ACCOUNTADMIN TO USERLAB;

USE ROLE SYSADMIN;
CREATE OR REPLACE DATABASE training_db;
CREATE OR REPLACE SCHEMA training_db.ADMIN;
CREATE OR REPLACE SCHEMA training_db.common;
--CREATE OR REPLACE SCHEMA training_db.weather;

--create or replace TABLE ISD_2019_TOTAL (
--	V VARIANT,
--	T TIMESTAMP_NTZ(9)
--);

USE ROLE SECURITYADMIN;
GRANT USAGE ON DATABASE training_db TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA training_db.PUBLIC TO ROLE PUBLIC;
GRANT USAGE ON FUTURE WORKSPACES IN SCHEMA training_db.PUBLIC TO ROLE PUBLIC;
GRANT READ ON FUTURE WORKSPACES IN SCHEMA training_db.PUBLIC TO ROLE PUBLIC;
GRANT WRITE ON FUTURE WORKSPACES IN SCHEMA training_db.PUBLIC TO ROLE PUBLIC;

/*
-- Create the shared workspace
CREATE WORKSPACE TRAINING_DB.PUBLIC."shared";

-- Grant READ, WRITE on the workspace to PUBLIC
GRANT READ ON WORKSPACE TRAINING_DB.PUBLIC."shared" TO ROLE PUBLIC;
GRANT WRITE ON WORKSPACE TRAINING_DB.PUBLIC."shared" TO ROLE PUBLIC;
*/

USE ROLE ACCOUNTADMIN;
CREATE OR REPLACE PROCEDURE training_db.admin.grant_adm_role_class (P_USERNAME VARCHAR)
RETURNS STRING
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
      EXECUTE IMMEDIATE 'GRANT ROLE SYSADMIN TO USER ' || P_USERNAME;
      EXECUTE IMMEDIATE 'GRANT APPLY SESSION POLICY ON USER  ' || P_USERNAME || ' TO ROLE SYSADMIN';
      EXECUTE IMMEDIATE 'GRANT APPLY PASSWORD POLICY ON USER ' || P_USERNAME || ' TO ROLE SYSADMIN';
      RETURN 'SYSADMIN granted to ' || P_USERNAME;
END;
$$;

USE ROLE ACCOUNTADMIN;
CREATE OR REPLACE PROCEDURE training_db.admin.setup_adm_edw_roles_privs(P_USERNAME VARCHAR, P_OPERATION VARCHAR)
RETURNS VARCHAR(16777216)
LANGUAGE SQL
EXECUTE AS OWNER
AS '
DECLARE
        edw_db                VARCHAR;
        edw_useradmin         VARCHAR;
        edw_sysadmin          VARCHAR;
        edw_inventory_r       VARCHAR;
        edw_inventory_rw      VARCHAR;
        edw_elt               VARCHAR;
        edw_analyst           VARCHAR;

BEGIN            
        edw_db                :=p_username || ''_adm_edw_db'';
        edw_useradmin         := :p_username || ''_adm_edw_useradmin'';
        edw_sysadmin          := :p_username || ''_adm_edw_sysadmin'';
        edw_inventory_r       := :p_username || ''_adm_edw_inventory_r'';
        edw_inventory_rw      := :p_username || ''_adm_edw_inventory_rw'';
        edw_elt               := :p_username || ''_adm_edw_elt'';
        edw_analyst           := :p_username || ''_adm_edw_analyst'';

        IF (:P_USERNAME IS NOT NULL AND :P_OPERATION=''ADD'') THEN  
            CREATE OR REPLACE ROLE IDENTIFIER(:edw_sysadmin);
            CREATE OR REPLACE ROLE IDENTIFIER(:edw_useradmin);
            CREATE OR REPLACE ROLE IDENTIFIER(:edw_sysadmin);

            -- Role hierarchy
            GRANT ROLE IDENTIFIER(:edw_useradmin) TO ROLE useradmin; 
            GRANT ROLE IDENTIFIER(:edw_sysadmin) TO ROLE sysadmin; 

            -- Sysadmin privileges
            GRANT CREATE DATABASE ON ACCOUNT TO IDENTIFIER(:edw_sysadmin);
            GRANT CREATE WAREHOUSE ON ACCOUNT TO IDENTIFIER(:edw_sysadmin);

            -- Useradmin privileges
            GRANT CREATE ROLE ON ACCOUNT TO IDENTIFIER(:edw_useradmin);
    
            -- Grant roles to the user
            GRANT ROLE IDENTIFIER(:edw_useradmin) TO USER IDENTIFIER(:p_username);
            GRANT ROLE IDENTIFIER(:edw_sysadmin) TO USER IDENTIFIER(:p_username);
        
            RETURN '' EDW sysadmin and useradmin role setup completed  '';

        ELSEIF (:P_USERNAME IS NOT NULL AND :P_OPERATION = ''DROP'') THEN
            DROP DATABASE IF EXISTS IDENTIFIER(:edw_db);
            DROP ROLE IF EXISTS IDENTIFIER(:edw_inventory_r);
            DROP ROLE IF EXISTS IDENTIFIER(:edw_inventory_rw);
            DROP ROLE IF EXISTS IDENTIFIER(:edw_elt);
            DROP ROLE IF EXISTS IDENTIFIER(:edw_analyst);
            DROP ROLE IF EXISTS IDENTIFIER(:edw_useradmin);
            DROP ROLE IF EXISTS IDENTIFIER(:edw_sysadmin);
            
            RETURN (''Cleaned up previously created edw roles and objects'');
        ELSE 
            RETURN (''Operation not successful - invalid parameters'');
        END IF;
END;
';

USE ROLE ACCOUNTADMIN;
CREATE OR REPLACE PROCEDURE training_db.admin.set_rsa_key_public (P_USERNAME VARCHAR, P_PUBLIC_KEY STRING)
RETURNS STRING
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE
    user_exists INTEGER;
    result STRING;

BEGIN
    -- Check if user exists in account_usage.users
    SELECT COUNT(*)
    INTO :user_exists
    FROM snowflake.account_usage.users
    WHERE UPPER(name) = UPPER(:P_USERNAME)
    AND deleted_on IS NULL;

    -- If user exists, set the RSA public key
    IF (user_exists > 0) THEN
        BEGIN
            EXECUTE IMMEDIATE ' ALTER USER  ' || P_USERNAME  || ' SET RSA_PUBLIC_KEY=  "' || P_PUBLIC_KEY || '"'; 
            result := 'Successfully granted adm_role to user ' || :P_USERNAME;
        EXCEPTION
            WHEN OTHER THEN
            result := 'Error setting RSA Public key: ' || SQLSTATE || ' - ' || SQLERRM;
        END;
    ELSE
        result := 'User ' || :P_USERNAME || ' does not exist';
    END IF;
    
    RETURN result;
END;
$$;

USE ROLE ACCOUNTADMIN;
CREATE OR REPLACE PROCEDURE training_db.common.update_profile(
    p_username VARCHAR,
    p_fname   VARCHAR,
    p_lname   VARCHAR,
    p_email   VARCHAR
)
RETURNS STRING
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE
    cur_user STRING;
    query STRING;
BEGIN
    -- validation check: make sure this is not an attempt to alter someone elses profile details
    SELECT CURRENT_USER() INTO cur_user;
    IF (cur_user != UPPER(:p_username)) THEN
        RETURN 'Operation NOT PERMITTED. You may only alter profile details for the user you are logged in as.';
    END IF;

    query := 'ALTER USER ' || p_username || ' SET FIRST_NAME = ''' || p_fname
             || ''', LAST_NAME = ''' || p_lname
             || ''', EMAIL = ''' || p_email || '''';
    EXECUTE IMMEDIATE :query;

    RETURN 'Profile UPDATED with query:\n' || :query;
END;
$$;