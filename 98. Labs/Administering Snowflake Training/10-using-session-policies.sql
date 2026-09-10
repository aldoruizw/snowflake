
-- 10.0.0  Using Session Policies
--         By the end of this lab, you will be able to:
--         - Create and set up a session policy
--         - Centralize session policies
--         - Assign a session policy to a particular user
--         - Test the enforcement of a session policy

-- 10.1.0  Scenario
--         In this exercise, you will create a session policy that will enforce
--         a 5 minute session timeout when a test user logged in is inactive
--         (idle).

-- 10.2.0  Load Lab SQL File

-- 10.2.1  To load the SQL file, in the left navigation bar, select Projects,
--         then, under My Workspace, select the lab SQL file corresponding to
--         this lab exercise.
--         This lab shows how to set up centralized session policy management.

-- 10.2.2  Set query tag for this session.

ALTER SESSION SET query_tag = '(USERLAB) lab - TOPIC: Session Policies';


-- 10.2.3  Cleanup any users from labs first.

USE ROLE SECURITYADMIN;
DROP USER IF EXISTS USERLAB_test_user;


-- 10.3.0  Setup for storing and testing session policies
--         In this lab you will be using the adm_role to manage all the session
--         policies. The session policies will be created in a schema called
--         sess_policy_schema in the USERLAB_adm_policy_db database.

-- 10.3.1  Create a custom database and schema for storing all session policies.

USE ROLE SYSADMIN;
CREATE DATABASE IF NOT EXISTS  USERLAB_adm_policy_db 
COMMENT= 'Database for Admin labs';
CREATE OR REPLACE SCHEMA USERLAB_adm_policy_db.sess_policy_schema;


-- 10.3.2  Create warehouse.

CREATE WAREHOUSE IF NOT EXISTS USERLAB_adm_wh
    WAREHOUSE_SIZE=XSmall
    INITIALLY_SUSPENDED=True
    AUTO_SUSPEND=300
    COMMENT='Warehouse for Admin course labs';


-- 10.3.3  Create a user to test with session policies.
--         We will now create a user to test session policies. Since this is a
--         temporary user we will bypass MFA for 2 hours. After 2 hours the user
--         will be subject to MFA prompting at login.

USE ROLE SECURITYADMIN;

CREATE USER IF NOT EXISTS USERLAB_test_user
MUST_CHANGE_PASSWORD = TRUE;
ALTER USER USERLAB_test_user SET MINS_TO_BYPASS_MFA = 120;


-- 10.3.4  Grant the ADM_ROLE to your new user by calling a pre-built stored
--         procedure.
--         This procedure grants the ADM_ROLE to the new user. It also does the
--         following: GRANT APPLY SESSION POLICY ON USER USERLAB_test_user TO
--         ROLE adm_role to be able to apply a session policy at the user level.


EXECUTE IMMEDIATE $$
DECLARE
  result_message VARCHAR;
BEGIN
  SHOW USERS;
  let user_cursor 
  CURSOR FOR SELECT * FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
  WHERE "name" IN ('USERLAB_TEST_USER')
  ;
  let user_array ARRAY := ARRAY_CONSTRUCT();
  let messages ARRAY := ARRAY_CONSTRUCT();
  
  FOR user_row in user_cursor DO
    user_array := ARRAY_APPEND(user_array, user_row."name");
    let user_name VARCHAR := user_row."name";
    CALL training_db.admin.grant_adm_role_class (P_USERNAME=>:user_name) INTO :result_message;
    messages := ARRAY_APPEND(messages, result_message);
  END FOR;
  
  RETURN messages;
END;
$$;



-- 10.3.5  Confirm ADM_ROLE has been granted the correct privileges for
--         centralized session policy management.
--         In order to manage the session policies, a role must have the
--         following privileges.
--         - CREATE SESSION POLICY on SCHEMA privilege
--         - USAGE on the DATABASE and SCHEMA that contain the session policy
--         - CREATE SESSION POLICY on the schema that contains the session
--         policy
--         - APPLY SESSION POLICY on the ACCOUNT.
--         Depending on the requirements, a policy admin may set the policies at
--         the ACCOUNT level or at the USER level.
--         Run the following command to check the privileges granted to ADM_ROLE
--         relating to session policies.

SHOW GRANTS TO ROLE SYSADMIN ;

SELECT "privilege", "granted_on", "name" FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
WHERE "privilege" like  '%SESSION%'
OR "privilege" LIKE   '%ACCOUNT%'
OR "name" like '%USERLAB%TEST%';


--         You will see the following privileges as the output of the previous
--         command.
--         - APPLY SESSION POLICY - USER level
--         - APPLY SESSION POLICY - ACCOUNT level
--         We do not see CREATE SESSION POLICY on SCHEMA in this output, as the
--         adm_role owns the new session policy database and schema.

-- 10.3.6  Show all roles granted to user USERLAB.

USE ROLE SYSADMIN;
SHOW GRANTS TO USER USERLAB;


-- 10.4.0  Create a session policy and assign to a user

-- 10.4.1  Configure the session policy to set the SESSION_IDLE_TIMEOUT_IN_MINS
--         to be 5 Minutes.
--         Range of values on timeout parameters is 5 mins to 240 mins (4
--         hours).

USE ROLE SYSADMIN;
CREATE OR REPLACE SESSION POLICY USERLAB_adm_policy_db.sess_policy_schema.sess_test_policy1
  SESSION_IDLE_TIMEOUT_MINS = 5
  SESSION_UI_IDLE_TIMEOUT_MINS = 5
  COMMENT = 'Session policy for demo usage';

--         It is possible to set this session policy at ACCOUNT level using the
--         following command. We will not do this step at ACCOUNT level.
--         – ALTER ACCOUNT SET SESSION POLICY
--         <db_name.schema_name>.session_policy_prod_1;

-- 10.4.2  Assign the session policy to user USERLAB_test_user.
--         Set the policy on a user with the ALTER USER command.

ALTER USER USERLAB_test_user SET SESSION POLICY
  USERLAB_adm_policy_db.sess_policy_schema.sess_test_policy1;

--         To replace a session policy that is already set for an account or
--         user, unset the session policy first and then set the new session
--         policy for the account or user. For example:
--         – ALTER USER USERLAB_test_user UNSET SESSION POLICY;

-- 10.4.3  Enforce session policies within the account.
--         Enforcement of session policies can be controlled with parameters in
--         the account.
--         – USE ROLE adm_role;
--         – ALTER ACCOUNT SET enforce_session_policy = true; – This is the
--         default.
--         – ALTER ACCOUNT SET enforce_session_policy = false; – Disable session
--         policy enforcement

-- 10.5.0  Test the new Session Policy
--         The command below will return a URL. Click the URL to set the
--         USERLAB_test_user password, and then log in to the training account
--         with the new credentials.

ALTER USER USERLAB_test_user RESET PASSWORD;


-- 10.5.1  Verify that you get timed out after 5 minutes of idle time.
--         Check your watch and verify the test user gets logged off in 5
--         minutes.
--         Continue on with the lab while you wait for the session to timeout.

-- 10.5.2  Open a different web browser to login and continue the lab.
--         For example, if you are using Microsoft Edge then choose a different
--         web browser, like Firefox.
--         If you try to log in using the same web browser, your current login
--         user will get logged off and the session timeout test will fail.
--         If you are using Google Chrome you can simply bring up an Incognito
--         Window to avoid getting logged off.
--         In the new browser (or Incognito window), log in to the training
--         account as your original USERLAB user, and continue the lab.

-- 10.5.3  View session policies and DDL.


USE ROLE SYSADMIN;

USE SCHEMA USERLAB_adm_policy_db.sess_policy_schema;

-- Session policies in the database

SHOW SESSION POLICIES;

-- All session policies in the account

SHOW SESSION POLICIES IN ACCOUNT;


-- 10.5.4  Let’s try using get_ddl to see the command used to create the Session
--         policy.

SELECT GET_DDL('policy','sess_test_policy1');


-- 10.5.5  Use DESCRIBE SESSION POLICY to see session policy metadata.

DESC SESSION POLICY sess_test_policy1;


-- 10.5.6  View current session policy references.

USE SCHEMA USERLAB_adm_policy_db.sess_policy_schema;
USE WAREHOUSE USERLAB_adm_wh;

SELECT *
FROM TABLE(USERLAB_adm_policy_db.information_schema.policy_references(policy_name => 'sess_test_policy1'));

--         Close the new browser (or Incognito window) and return to the session
--         policy test window before continuing.

-- 10.5.7  Run the commands below to clear out the objects used in this lab:
--         Before running the following cleanup commands, verify that your test
--         user session timed out as expected after 5 minutes. If 5 minutes have
--         passed and nothing appears to have happened, you may need to click in
--         the browser window to refresh it and show the login prompt. Once
--         prompted, log back in as the original USERLAB lab user.


USE ROLE SECURITYADMIN;
ALTER USER USERLAB_test_user UNSET SESSION POLICY;
DROP USER IF EXISTS USERLAB_test_user;
USE ROLE SYSADMIN;
DROP DATABASE IF EXISTS USERLAB_adm_policy_db;
ALTER WAREHOUSE USERLAB_adm_wh SUSPEND;


-- 10.6.0  Key Takeaways
--         - To create a session policy, you must be using a role with the
--         CREATE SESSION POLICY privilege on the schema.
--         - You can set the policy on an account with the ALTER ACCOUNT command
--         or on a user with the ALTER USER command.
--         - To enforce the Session Policy you need to, as an account
--         administrator, set the ENFORCE_SESSION_POLICY for the account to be
--         TRUE.
