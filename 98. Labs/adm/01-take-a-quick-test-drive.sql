-- 1.0.0   Take a Quick Test Drive
--         This lab is designed to introduce you to the Snowflake Snowsight
--         interface from an administrator’s point of view.
--         By the end of this lab, you will be able to:
--         - Setup Snowflake Multi-Factor Authentication for your account.
--         - Log into the Snowflake account using Snowsight and investigate its
--         various functions.
--         - Use standard SQL statements to create a database and a warehouse.
--         - Examine Snowflake’s data organization structure, storage, compute,
--         and metadata in the Cloud services.
--         - Setup user profile.
--         - Generate a new programmatic access token (PAT).

-- 1.1.0   Log In to Your Snowflake Account and Setup Current Role

-- 1.1.1   Log into your snowflake account.
--         Log in to your Snowflake account using the information provided by
--         your instructor. Remember, this is the Web UI that was set up for you
--         by the instructor. Use the username (an animal name assigned by the
--         instructor) and the default password to access this account. A sample
--         URL would look something like this:
--         https://app.snowflake.com/organization_name/account_name

-- 1.2.0   Log In and Set Up MFA
--         Snowflake is secure by default. MFA is enforced for all Snowsight
--         users. The instructions below explain how to log in to Snowsight and
--         set up MFA.

-- 1.2.1   Access the URL provided to you for this course.
--         You will be taken to a login screen for the lab account.

-- 1.2.2   Enter your username and temporary password.
--         Obtain these credentials from your instructor.

-- 1.2.3   Set Up MFA using the Passkey method.
--         You will be prompted to Set up MFA.
--         Click on the Passkey option.
--         Follow the options available on your local machine to save the
--         passkey. We recommend saving the passkey locally using either a
--         browser-based password manager, or using Windows Hello (on a Windows
--         machine). Most options will require verification of your identity
--         using biometrics or a PIN.
--         Once the passkey has been successfully added, give it a nickname and
--         then click Continue.
--         If you were not prompted at login time to setup MFA for some reason,
--         you can also setup MFA using the following steps. This step can be
--         skipped if you have already setup MFA with Passkey.
--         Click on the animal name on the bottom left. Click on Settings. Click
--         on Authentication followed by Add New Authentication method. Select
--         passkey or authenticator and follow through the onscreen
--         instructions.

-- 1.2.4   Change your password when prompted.
--         This is not an error - the lab environments are set up so all users
--         are asked to change their password the first time they log in.

-- 1.2.5   Verify that you have ADM_ROLE selected.
--         Click on the animal name on the bottom left. If you have a role other
--         than ADM_ROLE, hover over the role listed under Switch Role, and
--         select ADM_ROLE from the pop-up list of available roles.
--         Note: Your username in the following image may be different.

-- 1.3.0   Create Lab Objects Using Workspaces

-- 1.3.1   To load the SQL files used in this course, in the left navigation
--         bar, under Work with data hover over Projects, then select
--         Workspaces.

-- 1.3.2   In the upper-left of the Workspaces page, in the My Workspaces pane,
--         click the + Add new button.

-- 1.3.3   Select Upload Folder from the drop-down menu.

-- 1.3.4   Navigate to the location where you downloaded the lab files. Open the
--         folder corresponding to your assigned animal user, and click Upload.

-- 1.3.5   From the list of lab files that appear under your animal user name
--         folder, Locate the lab file ##-take-a-quick-test-drive.sql where ##
--         is the lab number and click to open it.

-- 1.3.6   Set query tag for this session.

ALTER SESSION SET query_tag = '(USERLAB) lab - TOPIC: Take a Quick Test Drive';
USE SECONDARY ROLE NONE;


-- 1.3.7   Next Create your database using SQL commands.
USE ROLE SYSADMIN;
CREATE DATABASE IF NOT EXISTS USERLAB_adm_db 
COMMENT='Database for Admin course labs';


-- 1.3.8   Create a table in the PUBLIC schema of your database.

CREATE OR REPLACE TABLE USERLAB_adm_db.public.USERLAB_tbl
    (id NUMBER(38,0), name STRING(10),
    country VARCHAR(20), order_date DATE);


-- 1.3.9   Create your warehouse, leaving it initially suspended so it is not
--         using credits until you need it.

CREATE WAREHOUSE IF NOT EXISTS USERLAB_adm_wh
    WAREHOUSE_SIZE=XSmall
    INITIALLY_SUSPENDED=True
    AUTO_SUSPEND=300
    COMMENT='Warehouse for Admin course labs';


-- 1.3.10  Use the following commands to set defaults for your role, database,
--         schema, and warehouse.
--         This will be referred to as your standard context throughout the rest
--         of this workbook.


ALTER USER USERLAB
    SET
    DEFAULT_NAMESPACE=USERLAB_adm_db.public
    DEFAULT_WAREHOUSE=USERLAB_adm_wh;


-- 1.3.11  Run a SHOW WAREHOUSES to see that your warehouse is set as the
--         default.

SHOW WAREHOUSES LIKE 'USERLAB_adm%';


-- 1.4.0   Run Queries on Sample Data

-- 1.4.1   Select the Databases tab in the upper-left (next to Workspaces), and
--         ensure you have selected Objects tab.

-- 1.4.2   Expand the SNOWFLAKE_SAMPLE_DATA database object, then TPCH_SF1.

-- 1.4.3   Click the schema name (TPCH_SF1) and to the right of the name click
--         the ellipsis (three dots) and notice the options available.

-- 1.4.4   Click TPCH_SF1 to expand the schema (if it has not been expanded),
--         and then click Tables followed by clicking on the ORDERS table.
--         An Object Details pane describing the Orders table appears below the
--         Database Explorer Object pane. Close the Object Details pane by
--         clicking the x on the right-hand side of the pane.

-- 1.4.5   Back in the Database Explorer pane hover over the ORDERS table until
--         you see the ellipsis (three dots) for that object. Click the ellipses
--         and select Preview Table from the pop-up menu to see a sample of the
--         data in the ORDERS table.
--         A preview pane will display on the right and show you the sample
--         data. Close the preview pane by clicking the x on the right-hand side
--         of the tab.

-- 1.4.6   In your workspace, run the following commands to explore the data:


USE DATABASE snowflake_sample_data;
USE SCHEMA tpch_Sf1;

SHOW TABLES;

SELECT COUNT(*) FROM orders;

SELECT * FROM supplier LIMIT 10;

SELECT MAX(o_totalprice) FROM orders;

SELECT o_orderpriority, SUM(o_totalprice)
FROM orders
GROUP BY o_orderpriority
ORDER BY SUM(o_totalprice);


-- 1.4.7   Review the data by running a query to verify ps_partkey, ps_suppkey,
--         and ps_availqty columns from the PARTSUPP table. Order the output by
--         part key.

SELECT ps_partkey, ps_suppkey, ps_availqty
FROM partsupp
ORDER BY ps_partkey;


-- 1.4.8   Notice that there are multiple rows for each ps_partkey, with
--         different values for ps_suppkey and ps_availqty.
--         This means that several suppliers stock each part key and have
--         different quantities available.

-- 1.4.9   Run a query to return just the part key, and the total available
--         quantity from all suppliers combined. GROUP and ORDER the output by
--         the part key.
--         You can see how many rows are returned by the query in the Query
--         Results pane.
--         How many total rows were returned by your query? 200,000

SELECT ps_partkey, SUM(ps_availqty)
FROM partsupp
GROUP BY ps_partkey
ORDER BY ps_partkey;


-- 1.4.10  Run a query to return the total number of rows.
--         How many total rows are in the PARTSUPP table? 800,000

SELECT count(*)
FROM partsupp;


-- 1.4.11  Run the following query that will return the lowest- and highest-
--         priced items (based on the extended price) from the LINEITEM table.
--         What are the lowest and highest prices returned? 901.00 and 104949.50

SELECT MIN(l_extendedprice), MAX(l_extendedprice)
FROM lineitem;


-- 1.5.0   Review Your User Settings

-- 1.5.1   Access the Settings page.
--         Click on the animal name on the bottom left, then select Settings.

-- 1.5.2   Review your profile.
--         The settings page defaults to My Profile. Observe that you are unable
--         to change your name or email address. This is because your user role
--         does not have the privileges to make those changes.

-- 1.6.0   Update Your User Profile
--         In the next steps, you will run a stored procedure to update your
--         user profile. This is necessary because elevated privileges are
--         required to perform this action.

-- 1.6.1   Create variables for your first name, last name and email address.
--         Return to your lab SQL file in the My Workspaces pane.

-- Edit each of the following three lines to add your first name, lastname, and email address.
-- Run the commands to set the variables.
SET myfirstname = 'User';
SET mylastname = 'Lab';
SET myemail = 'UserLab@mail.com';

-- Confirm that the variables are set.
SELECT $myfirstname, $mylastname, $myemail;


-- 1.6.2   Call the stored procedure to update your user profile.
--         You call a stored procedure which runs with elevated privileges that
--         allow you to make the necessary changes.

-- Call the stored procedure to update your user profile
--CALL training_db.common.update_profile(current_user(), $myfirstname, $mylastname, $myemail);
USE ROLE ACCOUNTADMIN;
SET query = 'ALTER USER ' || current_user() || ' SET FIRST_NAME = ''' || $myfirstname
             || ''', LAST_NAME = ''' || $mylastname
             || ''', EMAIL = ''' || $myemail || '''';
SELECT $query;
EXECUTE IMMEDIATE $query;
USE ROLE SYSADMIN;

-- Confirm that settings have taken effect
DESCRIBE USER USERLAB;

ALTER SESSION UNSET query_tag;
USE SECONDARY ROLE ALL;

-- 1.6.3   Confirm the profile changes via the user menu.
--         Click the animal name in the lower-left corner, then select Settings.
--         You may have to refresh your browser, or log out and back in if you
--         do not see the changes.
--         Click Resend verification. You should get a verification email to the
--         address that you specified.

-- 1.7.0   Setup Programmatic Access Tokens (PAT)

-- 1.7.1   Generate a new PAT.
--         We’ll generate a new token for our upcoming Key Pair Authentication
--         lab.
--         Click on the animal name on the bottom left. Click on Settings. Click
--         on Authentication.
--         Under Programmatic access tokens
--         Click on the Generate new token.
--         Enter the following details.
--         Name: USERLAB_TOKEN_ALL
--         Comment: Token for USERLAB user
--         Role: All of my roles (ADM_ROLE is required for general admin labs.
--         Only TRAINING_ROLE is allowed to login to Jupyterhub)
--         Click on the Generate button
--         Click on the Download token button
--         There should be a USERLAB_TOKEN_ALL‐token‐secret.txt downloaded to
--         your local machine.
--         You can return to your worksheet.

-- 1.8.0   Key Takeaways
--         - Setup MFA and PAT to ensure secure authentication.
--         - Snowsight enables an administrator to navigate around and perform
--         different functions that can also be done through SQL.
--         - When a query is run, we can view information about it in the Query
--         Results pane.
--         - In the databases tab, we can click on a table and see the table
--         description and preview the data.