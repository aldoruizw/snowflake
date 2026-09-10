
-- 9.0.0   Using Password Policies
--         By the end of this lab, you will be able to:
--         - Create and set up a password policy
--         - Centralize password policies
--         - Assign a password policy to test users
--         - Test the enforcement of a password policy
--         This lab shows how to set up centralized password policy management.
--         We will not apply a password policy at the account level, but a
--         password policy will be set for two individual users.
--         Additionally, while it is not required to set up password policy
--         management using a separate policy database and schema, the lab shows
--         this capability as one way to manage password policies using a
--         POLICY_ADMIN role.
--         In this exercise you will create a password policy that will change
--         password attributes and apply the policy to two test users. The users
--         will be forced to change their password the next time they login and
--         use the new password requirements.

-- 9.1.0   Load Lab SQL File

-- 9.1.1   To load the SQL file, in the left navigation bar, select Projects,
--         then, under My Workspace, select the lab SQL file corresponding to
--         this lab exercise.

-- 9.2.0   Setup for storing and testing password policies

-- 9.2.1   Set query tag for this session.

ALTER SESSION SET query_tag = '(USERLAB) lab - TOPIC: Password Policies';


-- 9.2.2   Cleanup any users from labs first.

USE ROLE SECURITYADMIN;

show users like 'USERLAB%';
DROP USER IF EXISTS USERLAB_test_user1;
DROP USER IF EXISTS USERLAB_test_user2;


-- 9.2.3   Create database.
USE ROLE SYSADMIN;
CREATE DATABASE IF NOT EXISTS  USERLAB_adm_policy_db 
COMMENT = ' Database for Admin labs';
CREATE OR REPLACE SCHEMA USERLAB_adm_policy_db.pw_policy_schema;


-- 9.2.4   Create warehouse.

CREATE WAREHOUSE IF NOT EXISTS USERLAB_adm_wh
    WAREHOUSE_SIZE=XSmall
    INITIALLY_SUSPENDED=True
    AUTO_SUSPEND=300
    COMMENT='Warehouse for Admin course labs';

--         In this lab you will be creating a custom role called
--         USERLAB_pw_policy_admin that is responsible for managing all password
--         policies in the account.

-- 9.2.5   Create two users to test with password policies. Since these are
--         temporary users we will bypass MFA for 2 hours. After 2 hours the
--         users will be subject to MFA prompting at login.
USE ROLE SECURITYADMIN;
CREATE USER IF NOT EXISTS USERLAB_test_user1
  --MUST_CHANGE_PASSWORD=true
  PASSWORD = 'USERLAB'
  TYPE = LEGACY_SERVICE
  MUST_CHANGE_PASSWORD = FALSE;
--ALTER USER USERLAB_test_user1 SET MINS_TO_BYPASS_MFA = 120;

CREATE USER IF NOT EXISTS USERLAB_test_user2
  --MUST_CHANGE_PASSWORD=true
  PASSWORD = 'USERLAB'
  TYPE = LEGACY_SERVICE
  MUST_CHANGE_PASSWORD = FALSE;
--ALTER USER USERLAB_test_user2 SET MINS_TO_BYPASS_MFA = 120;

--         Later in the lab, we will use the ALTER USER USERLAB RESET PASSWORD
--         command to set the password for the new users. If we had set the
--         password when creating the user, altering the user with
--         MUST_CHANGE_PASSWORD=TRUE would force the user to reset thier
--         password once the new password policy is in force.

-- 9.2.6   Grant the ADM_ROLE to your new users.
--         This code block below grants the ADM_ROLE to the new users. It also
--         does the following: GRANT APPLY PASSWORD POLICY ON USER
--         USERLAB_test_user1 and login]_test_user2 TO ROLE adm_role to be able
--         to apply a password policy at the user level.

USE ROLE SYSADMIN;
EXECUTE IMMEDIATE $$
DECLARE
  result_message VARCHAR;
BEGIN
  SHOW USERS;
  let user_cursor 
  CURSOR FOR SELECT * FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
  WHERE "name" IN ('USERLAB_TEST_USER1','USERLAB_TEST_USER2')
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



-- 9.2.7   Confirm ADM_ROLE has been granted the correct privileges for
--         centralized password policy management.
--         In order to manage the password policies, a role must have the
--         following privileges.
--         - CREATE PASSWORD POLICY on SCHEMA privilege
--         - USAGE on the DATABASE and SCHEMA that contain the password policy
--         - CREATE PASSWORD POLICY on the schema that contains the password
--         policy
--         - APPLY PASSWORD POLICY on the ACCOUNT.
--         Depending on the requirements, a policy admin may set the policies at
--         the ACCOUNT level or at the USER level.

-- 9.2.8   Check the privileges granted to adm_role.
--         Run the following command to check the privileges granted to ADM_ROLE
--         relating to session policies.

SHOW GRANTS TO ROLE SYSADMIN ;

SELECT "name", "grantee_name", "privilege", "granted_on" FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
WHERE "privilege" like  '%PASSWORD%';


--         You will see the following privileges as the output of the previous
--         command.
--         - APPLY PASSWORD POLICY - USER level
--         - APPLY PASSWORD POLICY - ACCOUNT level
--         We do not see CREATE PASSWORD POLICY on SCHEMA in this output, as the
--         adm_role owns the new session policy database and schema

-- 9.2.9   Show all roles granted to user USERLAB.

USE ROLE SYSADMIN;
SHOW GRANTS TO USER USERLAB;


-- 9.3.0   Create a password policy and assign to users

-- 9.3.1   Use the new password policies role to create a password policy to
--         test.

USE ROLE SYSADMIN;

USE SCHEMA USERLAB_adm_policy_db.pw_policy_schema;

CREATE OR REPLACE PASSWORD POLICY pw_policy_1
  PASSWORD_MIN_LENGTH = 10 -- Min pw length
  PASSWORD_MAX_LENGTH = 24 -- Max pw length
  PASSWORD_MIN_UPPER_CASE_CHARS = 3 -- min # of UC chars
  PASSWORD_MIN_LOWER_CASE_CHARS = 3 -- min # of LC chars
  PASSWORD_MIN_NUMERIC_CHARS = 3 -- Min # of numeric chars
  PASSWORD_MIN_SPECIAL_CHARS = 1 -- Min # of special case chars
  PASSWORD_MAX_AGE_DAYS = 90 -- Max # of days before the pw must be changed
  PASSWORD_MAX_RETRIES = 2 -- Max # of failed logins before user login is locked out
  PASSWORD_LOCKOUT_TIME_MINS = 1 -- Mins that a user is locked out after being locked by pw policy
  COMMENT = 'Test password pw_policy_1 for demo';


-- 9.3.2   Create a second password policy that you will assign to the second
--         test user.

CREATE OR REPLACE PASSWORD POLICY pw_policy_2
  PASSWORD_MIN_LENGTH = 13 -- Min pw length
  PASSWORD_MAX_LENGTH = 124 -- Max pw length
  PASSWORD_MIN_UPPER_CASE_CHARS = 2 -- min # of UC chars
  PASSWORD_MIN_LOWER_CASE_CHARS = 2 -- min # of LC chars
  PASSWORD_MIN_NUMERIC_CHARS = 5 -- Min # of numeric chars
  PASSWORD_MIN_SPECIAL_CHARS = 4 -- Min # of special case chars
  PASSWORD_MAX_AGE_DAYS = 90 -- Max # of days before the pw must be changed
  PASSWORD_MAX_RETRIES = 3 -- Max # of failed logins before user login is locked out
  PASSWORD_LOCKOUT_TIME_MINS = 2 -- Mins that a user is locked out after being locked by pw policy
  COMMENT = 'Test password pw_policy_2 for demo';


-- 9.3.3   Apply the password policy to the test users.
--         Set the policy on a user with the ALTER USER command.

-- Unset if you already have a password policy for this user
-- ALTER USER USERLAB_test_user1 UNSET PASSWORD POLICY;
USE ROLE SECURITYADMIN;
ALTER USER USERLAB_test_user1 SET PASSWORD POLICY pw_policy_1;

-- Unset if you already have a password policy for this user
-- ALTER USER USERLAB_test_user2 UNSET PASSWORD POLICY;

ALTER USER USERLAB_test_user2 SET PASSWORD POLICY pw_policy_2;

--         Do not create the policy name in single quotes as it causes an error
--         currently.
--         Recap of the steps:
--         - 1. Create password policy
--         - 2. Apply the policy
--         - 3. ALTER all users to force a password change

-- 9.4.0   Test The New Password Policy
--         The command below will return a URL. Click the URL to set the
--         USERLAB_test_user1 user’s password, and then log in to the training
--         account with the new credentials.

ALTER USER USERLAB_test_user1 RESET PASSWORD;


-- 9.4.1   Verify that your new password must meet the policy requirements.
--         Remember, when you created the password policy earlier in the lab, it
--         required a minimum of 3 uppercase characters, among other password
--         attributes.
--         Special characters ( . , ' , ! , @ , # , $ , % , ^ , & , * , etc.)

-- 9.4.2   View Password policies and DDL.
--         Log out of USERLAB_test_user1 and log back in as your USERLAB user to
--         continue the lab exercise.

USE ROLE SYSADMIN;

USE SCHEMA USERLAB_adm_policy_db.pw_policy_schema;

-- Password policies in the database

SHOW PASSWORD POLICIES;

-- All password policies in the account

SHOW PASSWORD POLICIES IN ACCOUNT;


-- 9.4.3   Let’s try using get_ddl to see the command used to create the
--         Password policy.

SELECT GET_DDL('policy','pw_policy_1');


-- 9.4.4   Use DESCRIBE PW_POLICY_1 POLICY to see password policy metadata.
--         Compare your PW_POLICY_1 to the default.

DESC PASSWORD POLICY pw_policy_1;


-- 9.4.5   View users who have a password policy set.
--         The output of the table function below shows each user whom has been
--         assigned the pw_policy_1 password policy.

USE SCHEMA USERLAB_adm_policy_db.pw_policy_schema;
USE WAREHOUSE USERLAB_adm_wh;

SELECT *
FROM TABLE(USERLAB_adm_policy_db.information_schema.policy_references(policy_name => 'pw_policy_1'));

USE ROLE SECURITYADMIN;

SHOW USERS LIKE 'USERLAB%';

--         The SHOW USERS does NOT show the password policy attributes. However,
--         you will see that USERLAB_test_user2 still has must_change_password
--         set to true since you have not logged in yet.

-- 9.4.6   Login as user USERLAB_TEST_USER2.
--         Follow the same steps as before to set the password for
--         USERLAB_test_user2. This password policy will require a minimum of 5
--         special characters, among other password attributes.

ALTER USER USERLAB_test_user2 RESET PASSWORD;


-- 9.4.7   Use DESCRIBE PW_POLICY_2 POLICY to see password policy metadata.
--         Log out of USERLAB_test_user2 and log back in as your USERLAB user to
--         continue the lab exercise. Compare your PW_POLICY_2 to the default.

USE ROLE SYSADMIN;

USE SCHEMA USERLAB_adm_policy_db.pw_policy_schema;

DESC PASSWORD POLICY pw_policy_2;


-- 9.4.8   Make sure you have logged out of your test users.

-- 9.4.9   Run the commands below to clear out the objects used in this lab:

USE ROLE SECURITYADMIN;
ALTER USER USERLAB_test_user1 UNSET PASSWORD POLICY;
ALTER USER USERLAB_test_user2 UNSET PASSWORD POLICY;

-- While unsetting the password policy is not required to drop the users, it is a best practice to clean up the objects created in the lab exercise before continuing.

DROP USER IF EXISTS USERLAB_test_user1;
DROP USER IF EXISTS USERLAB_test_user2;
DROP ROLE IF EXISTS USERLAB_pw_policy_admin;

USE ROLE SYSADMIN;
DROP SCHEMA USERLAB_adm_policy_db.pw_policy_schema;
DROP DATABASE USERLAB_adm_policy_db;
ALTER WAREHOUSE USERLAB_adm_wh SUSPEND;


-- 9.5.0   Key Takeaways
--         - To create a password policy, you must have a role with the CREATE
--         PASSWORD POLICY privilege on the schema.
--         - You can set the policy on an account with the ALTER ACCOUNT command
--         or on a user with the ALTER USER command.
--         - To require the user to change their password to meet the password
--         policy on their initial or next login to Snowflake, set the
--         MUST_CHANGE_PASSWORD on the user to TRUE using the ALTER USER
--         command.
