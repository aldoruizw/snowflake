
-- 23.0.0  System and Resource Monitors
--         This lab should take you approximately 25 minutes to complete.
--         By the end of this lab, you will be able to:
--         - Explore system usage and billing using the Web UI.
--         - Monitor queries using the Web UI history page.
--         - Monitor system storage usage, compute usage, credit consumption,
--         and user logins and connections.
--         - Create resource monitors to control credit consumption.
--         Many of these queries are examples of how you can monitor your
--         account in the real world. In a classroom environment, these queries
--         are not going to show real-world data. Run the queries here with the
--         understanding that they will be much more usable on a real production
--         account.
--         These exercises will cover system usage and resource monitoring.

-- 23.1.0  Load Lab SQL file

-- 23.1.1  To load the SQL file, in the left navigation bar, select Projects,
--         then, under My Workspace, select the lab SQL file corresponding to
--         this lab exercise.

-- 23.1.2  Ensure your active role is set to adm_role in the bottom left corner
--         of the UI.

-- 23.1.3  Set query tag for this session.

ALTER SESSION SET query_tag = '(PONY) lab - TOPIC: System and Resource Monitors';


-- 23.2.0  Explore the System Usage and Billing Using the Snowsight UI

-- 23.2.1  Click on Compute -> Warehouses in left navigation pane.

-- 23.2.2  Review Warehouse Usage for one of your warehouses.
--         In the Warehouses pane, locate the PONY_adm_wh warehouse and click
--         on its name.

-- 23.2.3  Review the Warehouse Activity pane

-- 23.2.4  Select Admin -> Cost Management in the left navigation pane.

-- 23.2.5  Select the Consumption tab if is not already chosen.
--         Make sure Compute is selected in the third dropdown (Usage Type). Use
--         the various drop-down lists and filters to expose different types of
--         information related to Compute.

-- 23.2.6  Monitor Snowflake Storage.

-- 23.2.7  Select Storage from the Usage Type dropdown at the top.

-- 23.2.8  Use the various drop-down lists and filters to expose different types
--         of information related to Storage.

-- 23.3.0  Monitoring Queries Using the Snowsight UI History Page
--         The Snowflake documentation contains a wealth of information on using
--         the History Page to monitor queries.

-- 23.3.1  Explore the Activity Page features.
--         https://docs.snowflake.com/en/user-guide/ui-snowsight-activity.html

-- 23.3.2  Select Monitoring then Query History in the left navigation pane.

-- 23.4.0  Monitoring System Storage Usage
--         Return to the SQL file for this lab exercise in Workspaces.

-- 23.4.1  Set the Worksheet context as follows:

USE ROLE adm_role;
CREATE WAREHOUSE IF NOT EXISTS PONY_adm_wh;
USE WAREHOUSE PONY_adm_wh;
CREATE DATABASE IF NOT EXISTS PONY_adm_db;
USE DATABASE PONY_adm_db;
USE SCHEMA public;

--         By referencing various table functions, various secure views in
--         SNOWFLAKE.ACCOUNT_USAGE, and various views in the INFORMATION_SCHEMA
--         of databases, you can discover information about the activity
--         occurring in your account.

-- 23.4.2  Query 1 - Billable Storage:

SELECT
    AVG(CASE WHEN (((storage_usage.usage_date) >= ((TO_DATE(DATE_TRUNC('month', CURRENT_DATE()))))
    AND (storage_usage.usage_date) < ((TO_DATE(DATEADD('month', 1, DATE_TRUNC('month', CURRENT_DATE())))))))
    THEN ((storage_usage.storage_bytes / POWER(1024, 4)) + (storage_usage.failsafe_bytes / POWER(1024, 4)))
    ELSE NULL END) AS "storage_usage.curr_mtd_billable_tb",
    AVG(CASE WHEN (((storage_usage.usage_date) >= ((TO_DATE(DATEADD('month', -1, DATE_TRUNC('month', CURRENT_DATE())))))
    AND (storage_usage.usage_date) < ((TO_DATE(DATEADD('month', 1, DATEADD('month', -1, DATE_TRUNC('month', CURRENT_DATE()))))))))
    THEN (storage_usage.STORAGE_BYTES / POWER(1024, 4)) + (storage_usage.FAILSAFE_BYTES / POWER(1024, 4))
    ELSE NULL END) AS "storage_usage.prior_mtd_billable_tb"
FROM
    snowflake.account_usage.storage_usage AS storage_usage;


-- 23.4.3  Query 2 - Return average daily storage usage for the past 10 days,
--         per database, for all databases in your account:

SELECT
*
FROM TABLE(information_schema.database_storage_usage_history(
    DATEADD('DAYS',-10,CURRENT_DATE()),CURRENT_DATE()));


-- 23.4.4  Query 3 - Return average daily storage usage for the past 10 days for
--         your account overall:

SELECT
    usage_date,
    SUM(AVERAGE_DATABASE_BYTES) average_database_bytes,
    SUM(AVERAGE_FAILSAFE_BYTES) average_failsafe_bytes
FROM TABLE(information_schema.database_storage_usage_history(
    DATEADD('DAYS',-10,CURRENT_DATE()),CURRENT_DATE()))
GROUP BY
    usage_date
ORDER BY
    usage_date;


-- 23.4.5  Query 4 - Return average daily data storage usage for all the
--         Snowflake stages in your account for the past 10 days:

SELECT
*
FROM TABLE(information_schema.stage_storage_usage_history(
        DATEADD('DAYS',-10,CURRENT_DATE()),CURRENT_DATE()));


-- 23.5.0  Monitoring System Compute Usage
--         Drill down into the System Compute usage by utilizing various
--         functions, account_usage, and the information_schema.

-- 23.5.1  Query 1 - Retrieve hourly warehouse usage over the past 10 days for
--         all virtual warehouses that ran during this time period:

SELECT * FROM table(information_schema.warehouse_metering_history(
        dateadd('days',-10,current_date())));


-- 23.5.2  Query 2 - Retrieve hourly warehouse usage for a named warehouse on a
--         specified date:

SELECT * FROM table(information_schema.warehouse_metering_history(
    current_date(),current_date(),
    'PONY_adm_wh'));


-- 23.6.0  Monitoring System Credit Consumption
--         Determine the total amount of system credits consumed by using the
--         Account Usage Views.

-- 23.6.1  Query 1 - Total Credits Used (Month to Date):

SELECT
    COALESCE(SUM(CASE WHEN (((warehouse_metering_history.start_time) >= ((DATE_TRUNC('month', CURRENT_DATE()))) AND (warehouse_metering_history.START_TIME) < ((DATEADD('month', 1, DATE_TRUNC('month', CURRENT_DATE())))))) THEN warehouse_metering_history.credits_used ELSE NULL END),
    0) AS "warehouse_metering_history.current_mtd_credits_used",
    COALESCE(SUM(CASE WHEN EXTRACT(MONTH, warehouse_metering_history.start_time) = EXTRACT(MONTH, CURRENT_TIMESTAMP()) - 1 AND warehouse_metering_history.start_time <= dateadd(MONTH, -1, CURRENT_TIMESTAMP()) THEN warehouse_metering_history.credits_used ELSE NULL END),
    0) AS "warehouse_metering_history.prior_mtd_credits_used"
FROM
    snowflake.account_usage.warehouse_metering_history AS warehouse_metering_history;


-- 23.6.2  Query 2 - Credits Used by Warehouse:

SELECT
    warehouse_metering_history.warehouse_name
    AS "warehouse_metering_history.warehouse_name",
    COALESCE(SUM(warehouse_metering_history.credits_used),
    0) AS "warehouse_metering_history.total_credits_used"
FROM
    snowflake.account_usage.warehouse_metering_history
    AS warehouse_metering_history
GROUP BY
    1
ORDER BY
    1;


-- 23.6.3  Query 3 - Credits Used Over Time by Warehouse (MTD):

SELECT
  "warehouse_metering_history.warehouse_name",
  "warehouse_metering_history.start_date",
  "warehouse_metering_history.total_credits_used"
FROM
    (
    SELECT
        *,
        DENSE_RANK() OVER (
    ORDER BY
        z___min_rank) AS z___pivot_row_rank,
        RANK() OVER (PARTITION BY z__pivot_col_rank
    ORDER BY
        z___min_rank) AS z__pivot_col_ordering
    FROM
        (
        SELECT
        *,
        MIN(z___rank) OVER (
            PARTITION BY "warehouse_metering_history.start_date")
        AS z___min_rank
    FROM
        (
        SELECT
        *,
        RANK() OVER (
        ORDER BY
        CASE
        WHEN z__pivot_col_rank = 1 THEN
        (CASE
        WHEN "warehouse_metering_history.total_credits_used"
        IS NOT NULL THEN 0
            ELSE 1
            END)
            ELSE 2
            END,
        CASE
        WHEN z__pivot_col_rank = 1
        THEN "warehouse_metering_history.total_credits_used"
        ELSE NULL
        END DESC,
        "warehouse_metering_history.total_credits_used" DESC,
        z__pivot_col_rank,
        "warehouse_metering_history.start_date") AS z___rank
    FROM
        (
        SELECT
        *,
        DENSE_RANK() OVER (
        ORDER BY
        CASE
        WHEN "warehouse_metering_history.warehouse_name" IS NULL
            THEN 1
            ELSE 0
        END,
        "warehouse_metering_history.warehouse_name")
            AS z__pivot_col_rank


    FROM
        (
        SELECT
            warehouse_metering_history.warehouse_name
            AS "warehouse_metering_history.warehouse_name",
            TO_CHAR(
            TO_DATE(warehouse_metering_history.start_time),
            'YYYY-MM-DD')
            AS "warehouse_metering_history.start_date",
            COALESCE(
                SUM(warehouse_metering_history.credits_used),
            0) AS "warehouse_metering_history.total_credits_used"
    FROM
        snowflake.account_usage.warehouse_metering_history
        AS warehouse_metering_history
        GROUP BY
        1,
        TO_DATE(warehouse_metering_history.START_TIME)) ww ) bb
        WHERE
    z__pivot_col_rank <= 16384 ) aa ) xx ) zz
WHERE
    z___pivot_row_rank <= 500
    OR z__pivot_col_ordering = 1
ORDER BY
    z___pivot_row_rank;


-- 23.7.0  Monitoring User Logins and Connections
--         It is always useful to review user account usage. By using the
--         Account Usage views you can determine the exact number of user logins
--         and their respective connection times.

-- 23.7.1  Query 1 - Total Logins:

SELECT
    COUNT(*) AS "login_history.logins",
    COUNT(CASE WHEN (CASE WHEN CASE WHEN login_history.IS_SUCCESS = 'YES' THEN TRUE ELSE FALSE END THEN 1 ELSE 0 END ) = 0 THEN 1 ELSE NULL END) AS "login_history.total_failed_logins",
    1 * ((COUNT(CASE WHEN (CASE WHEN CASE WHEN login_history.IS_SUCCESS = 'YES' THEN TRUE ELSE FALSE END THEN 1 ELSE 0 END ) = 0 THEN 1 ELSE NULL END)) / NULLIF((COUNT(*)),
    0)) * 100 AS "login_history.login_percent_failure_rate"

FROM
    snowflake.account_usage.login_history AS login_history;


-- 23.7.2  Query 2 - Logins by User:

SELECT
    login_history.user_name AS "login_history.user_name",
    COUNT(*) AS "login_history.logins",
    COUNT(CASE WHEN (CASE WHEN CASE WHEN login_history.IS_SUCCESS = 'YES'
    THEN TRUE ELSE FALSE END
    THEN 1 ELSE 0 END ) = 0 THEN 1 ELSE NULL END) AS "login_history.total_failed_logins",
    1 * ((COUNT(CASE WHEN (CASE WHEN CASE WHEN login_history.IS_SUCCESS = 'YES'
    THEN TRUE ELSE FALSE END
    THEN 1 ELSE 0 END ) = 0 THEN 1 ELSE NULL END)) / NULLIF((COUNT(*)),
    0)) *100 AS "login_history.login_percent_failure_rate"

FROM
    snowflake.account_usage.login_history AS login_history
GROUP BY
    1
ORDER BY
    2 DESC;


-- 23.7.3  Query 3 - Logins by User and Connection Type:

SELECT
    "login_history.reported_client_type",
    "login_history.user_name",
    "login_history.logins",
    "login_history.total_failed_logins",
    "login_history.login_percent_failure_rate"
FROM
    (
    SELECT
        *,
        DENSE_RANK() OVER (
    ORDER BY
        z___min_rank) AS z___pivot_row_rank,
        RANK() OVER (PARTITION BY z__pivot_col_rank
    ORDER BY
        z___min_rank) AS z__pivot_col_ordering
    FROM
        (
        SELECT
            *,
            MIN(z___rank)
            OVER (PARTITION BY "login_history.user_name")
            AS z___min_rank
    FROM
        (
        SELECT
            *,
            RANK() OVER (
        ORDER BY
            CASE
            WHEN z__pivot_col_rank = 1 THEN
            (CASE
                WHEN "login_history.logins" IS NOT NULL THEN 0
                ELSE 1
            END)
                ELSE 2
            END,
            CASE
                WHEN z__pivot_col_rank = 1
                THEN "login_history.logins"
                ELSE NULL
            END DESC,
            "login_history.logins" DESC,
            z__pivot_col_rank,
            "login_history.user_name") AS z___rank


    FROM
        (
        SELECT
            *,
            DENSE_RANK() OVER (
        ORDER BY
            CASE
            WHEN "login_history.reported_client_type" IS NULL THEN 1
                ELSE 0
            END,
            "login_history.reported_client_type") AS z__pivot_col_rank
    FROM
        (
        SELECT
            login_history.reported_client_type
        AS "login_history.reported_client_type",
            login_history.user_name AS "login_history.user_name",
        COUNT(*) AS "login_history.logins",
        COUNT(CASE WHEN (CASE WHEN CASE WHEN login_history.IS_SUCCESS = 'YES'
            THEN TRUE ELSE FALSE END
            THEN 1 ELSE 0 END ) = 0 THEN 1 ELSE NULL END)
            AS "login_history.total_failed_logins",
            1 * ((COUNT(CASE WHEN (CASE WHEN CASE
            WHEN login_history.IS_SUCCESS = 'YES'
            THEN TRUE ELSE FALSE END
            THEN 1 ELSE 0 END ) = 0 THEN 1 ELSE NULL END)) / NULLIF((COUNT(*)),
            0)) *100 AS "login_history.login_percent_failure_rate"
    FROM
        snowflake.account_usage.login_history AS login_history
        GROUP BY
            1,
            2) ww ) bb
        WHERE
            z__pivot_col_rank <= 16384 ) aa ) xx ) zz
WHERE

    z___pivot_row_rank <= 500
    OR z__pivot_col_ordering = 1
ORDER BY
    z___pivot_row_rank;


-- 23.8.0  Investigating Account Activity with Event Tables
--         Event Tables provide a detailed log of actions occurring within your
--         Snowflake account. As an administrator, you can query these tables to
--         gain deep insights into security, resource management, and user
--         activity. This is crucial for auditing, troubleshooting, and ensuring
--         governance policies are being followed.

-- 23.8.1  Query 1: Check for recent login events
--         Monitoring login history is a fundamental security practice. This
--         query allows an administrator to see who has been attempting to
--         access the account, from where, and whether they were successful.
--         Spikes in failed logins or access from unexpected IP addresses could
--         indicate a security threat.

-- Query for recent login events (last 7 days)
SELECT 
    EVENT_TIMESTAMP,
    USER_NAME,
    CLIENT_IP,
    REPORTED_CLIENT_TYPE,
    IS_SUCCESS,
    ERROR_MESSAGE
FROM 
    SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY
WHERE 
    EVENT_TIMESTAMP >= DATEADD('day', -7, CURRENT_TIMESTAMP())
ORDER BY 
    EVENT_TIMESTAMP DESC;


-- 23.8.2  Query 2: Identify warehouse creation events
--         Virtual warehouses are the primary consumers of credits in Snowflake.
--         This query helps an administrator track who is creating new
--         warehouses. This is vital for cost management and ensuring that
--         resource provisioning aligns with the organization’s budget and
--         policies.

-- Query for warehouse creation events
SELECT 
    START_TIME,
    USER_NAME,
    QUERY_TEXT
FROM 
    SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE 
    QUERY_TYPE = 'CREATE'
    AND QUERY_TEXT ILIKE '%WAREHOUSE%'
    AND START_TIME >= DATEADD('day', -30, CURRENT_TIMESTAMP())
ORDER BY 
    START_TIME DESC;


-- 23.8.3  Query 3: Track table alteration events
--         Changes to table structures can have significant downstream impacts
--         on reports, applications, and data pipelines. This query allows an
--         administrator to see who has been altering tables recently. This is
--         important for change management and troubleshooting data integrity
--         issues.

-- Query for table alteration events in the last 24 hours
SELECT
    START_TIME,
    USER_NAME,
    QUERY_TEXT
FROM
    SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE
    QUERY_TEXT ILIKE 'ALTER TABLE%'
    AND START_TIME >= DATEADD('hour', -24, CURRENT_TIMESTAMP())
ORDER BY
    START_TIME DESC;


-- 23.8.4  Query 4: Find long-running queries
--         Inefficient queries can consume excessive compute resources, leading
--         to higher costs and slower performance for other users. This query
--         helps an administrator identify queries that are taking a long time
--         to execute. This information is the first step in performance tuning
--         and query optimization.

-- Query for long-running queries (over 5 minutes)
SELECT
    USER_NAME,
    ROLE_NAME,
    WAREHOUSE_NAME,
    QUERY_TEXT,
    TOTAL_ELAPSED_TIME / 1000 AS DURATION_SECONDS
FROM 
    SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE 
    TOTAL_ELAPSED_TIME > 300000 -- Time in milliseconds
    AND START_TIME >= DATEADD('day', -7, CURRENT_TIMESTAMP())
ORDER BY
    TOTAL_ELAPSED_TIME DESC;


-- 23.9.0  View Your Resource Monitor Using SQL
--         Normally you would view resource monitors from the Snowsight UI by
--         clicking on Admin –> Cost Management in the left navigation pane, and
--         then clicking on the Resource Monitors tab at the top. Since we
--         operate exclusively under adm_role, we use the privileged execution
--         framework to perform this operation securely using SQL.
--         NOTE: The following stored procedure executes SHOW RESOURCE MONITORS
--         LIKE 'PONY%' as ACCOUNTADMIN and returns the results. Similar CALL
--         statements will be used throughout the remainder of this lab. The
--         code being run is provided above the CALL statement, but is commented
--         out.

-- use role accountadmin;
-- SHOW RESOURCE MONITORS LIKE 'PONY%';

CALL adm_db.admin.EXECUTE_READ_CALLER_SQL_ACCOUNTADMIN('ADM_SHOW_RM_ALL');

--         In the results, locate the resource monitor that begins with your
--         login name. This was set up when you first logged in to the training
--         Snowflake platform.

-- 23.10.0 Create a New Resource Monitor Using SQL

-- 23.10.1 Create a new Resource Monitor.
--         For educational purposes let’s set a very low, simple, 1-credit quota
--         so that you can understand the concept.

-- use role accountadmin;
-- CREATE OR REPLACE RESOURCE MONITOR PONY_limit1cq_rm WITH CREDIT_QUOTA=1
--    FREQUENCY = DAILY START_TIMESTAMP = IMMEDIATELY
--    TRIGGERS ON 50 PERCENT DO SUSPEND ON 100 PERCENT DO SUSPEND_IMMEDIATE;

CALL adm_db.admin.execute_privileged_caller_sql_ACCOUNTADMIN('ADM_CREATE_RM');


-- 23.10.2 Create a new virtual warehouse and assign the new resource monitor to
--         it.
--         Here you will create a new virtual warehouse with the resource
--         monitor assigned, and then grant your role access to use it. All
--         three operations run through the privileged execution framework.

-- use role ACCOUNTADMIN;
-- CREATE WAREHOUSE IF NOT EXISTS PONY_rm_wh
--   WITH WAREHOUSE_SIZE = LARGE AUTO_SUSPEND = 60 AUTO_RESUME = TRUE
--   RESOURCE_MONITOR = PONY_limit1cq_rm;

CALL adm_db.admin.execute_privileged_caller_sql_ACCOUNTADMIN('ADM_CREATE_RM_WH');


-- 23.10.3 Grant adm_role the ability to use the new warehouse.

USE WAREHOUSE PONY_adm_wh;

-- use role ACCOUNTADMIN;
-- GRANT USAGE, OPERATE, MONITOR ON WAREHOUSE PONY_rm_wh TO ROLE adm_role;

CALL adm_db.admin.execute_privileged_caller_sql_ACCOUNTADMIN('ADM_GRANT_RM_WH');

USE WAREHOUSE PONY_rm_wh;


-- 23.10.4 Verify the resource monitor is assigned to the warehouse.

-- use role accountadmin;
-- SHOW RESOURCE MONITORS LIKE 'PONY%';

CALL adm_db.admin.EXECUTE_READ_CALLER_SQL_ACCOUNTADMIN('ADM_SHOW_RM_ALL');


-- 23.11.0 Test the new Resource Monitor
--         Now that you have created a Resource Monitor to monitor the warehouse
--         next run a query to use up some credits and trigger based on the
--         percentage you set. Earlier you set a 50% threshold to suspend.

-- 23.11.1 Now we will run a query to keep the warehouse in the started state
--         and use up some of our quota.

USE SCHEMA snowflake_sample_data.tpcds_sf10tcl;

ALTER SESSION SET USE_CACHED_RESULT=FALSE;

SELECT cs_bill_customer_sk, cs_order_number, i_product_name, cs_sales_price
    , SUM(cs_sales_price) OVER (PARTITION BY cs_order_number
       ORDER BY i_product_name
       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) running_sum
  FROM catalog_sales, date_dim, item
 WHERE cs_sold_date_sk = d_date_sk
   AND cs_item_sk = i_item_sk
   AND d_year IN (1998, 1999, 2000, 2001) AND d_moy IN (1,2,3,4,5,6)
 LIMIT 100;

--         The query will complete in about 1 minute.

-- 23.11.2 Check how much of your resource monitor’s quota has been used.
--         Look to see if you have surpassed any of your quota used percentages.
--         Please wait about 1 minute for the warehouse to auto-suspend.

-- Make sure you wait for the warehouse to auto-suspend (about 1 minute) then run the following commands
-- Switch to PONY_adm_wh so the framework call is not blocked by the resource monitor
USE WAREHOUSE PONY_adm_wh;

-- use role accountadmin;
-- SHOW RESOURCE MONITORS LIKE 'PONY_limit%';

CALL adm_db.admin.EXECUTE_READ_CALLER_SQL_ACCOUNTADMIN('ADM_SHOW_RM_LIMIT');

--         Note: The actual used_credits won’t reflect reality until the
--         warehouse has suspended.

-- 23.11.3 Now re-run the query two times to note the results.
--         You will need to re-run this query two times. Make sure you wait for
--         the warehouse to auto-suspend after the first run below. You are
--         attempting to use up all the credits to get the error message we are
--         looking for.

-- Switch back to the monitored warehouse to trigger the quota exceeded error
USE WAREHOUSE PONY_rm_wh;

SELECT cs_bill_customer_sk, cs_order_number, i_product_name, cs_sales_price
    , SUM(cs_sales_price) OVER (PARTITION BY cs_order_number
       ORDER BY i_product_name
       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) running_sum
  FROM catalog_sales, date_dim, item
 WHERE cs_sold_date_sk = d_date_sk
   AND cs_item_sk = i_item_sk
   AND d_year IN (1998, 1999, 2000, 2001) AND d_moy IN (1,2,3,4,5,6)
 LIMIT 100;

--         Note: You will get an error:
--         Warehouse ’PONY_RM_WH’ cannot be resumed because resource monitor
--         {1} has exceeded its quota.
--         The reason you cannot run the query: Your Resource Monitor reached
--         its defined threshold of credits consumed, and the defined action was
--         taken; i.e., suspend the warehouse.

-- 23.12.0 Increase Credit Quota Using the Privileged Execution Framework
--         Now let’s increase the quota using SQL and re-run the query again. In
--         a production environment, an administrator with the ACCOUNTADMIN role
--         would increase the quota via the Snowsight UI (Admin > Cost
--         Management > Resource Monitors). In our classroom environment, we use
--         the privileged execution framework to perform this operation under
--         adm_role.

-- 23.12.1 Increase the resource monitor credit quota to 2.

USE WAREHOUSE PONY_adm_wh;

-- use role accountadmin;
-- ALTER RESOURCE MONITOR PONY_limit1cq_rm SET CREDIT_QUOTA=2;

CALL adm_db.admin.execute_privileged_caller_sql_ACCOUNTADMIN('ADM_ALTER_RM_QUOTA');


-- 23.12.2 Verify the quota has been increased.

-- use role accountadmin;
-- SHOW RESOURCE MONITORS LIKE 'PONY_limit%';

CALL adm_db.admin.EXECUTE_READ_CALLER_SQL_ACCOUNTADMIN('ADM_SHOW_RM_LIMIT');

-- 23.12.3 Re-run the query.
--         The query should now run again because we increased the credit quota.

-- Switch back to the monitored warehouse to verify the increased quota allows it to resume
USE WAREHOUSE PONY_rm_wh;

SELECT cs_bill_customer_sk, cs_order_number, i_product_name, cs_sales_price
    , SUM(cs_sales_price) OVER (PARTITION BY cs_order_number
       ORDER BY i_product_name
       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) running_sum
  FROM catalog_sales, date_dim, item
 WHERE cs_sold_date_sk = d_date_sk
   AND cs_item_sk = i_item_sk
   AND d_year IN (1998, 1999, 2000, 2001) AND d_moy IN (1,2,3,4,5,6)
 LIMIT 100;


-- 23.12.4 Cleanup by dropping the warehouse and resource monitor.

USE WAREHOUSE PONY_adm_wh;

-- use role accountadmin;
-- DROP WAREHOUSE IF EXISTS PONY_rm_wh;

CALL adm_db.admin.execute_privileged_caller_sql_ACCOUNTADMIN('ADM_DROP_RM_WH');

-- use role accountadmin;
-- DROP RESOURCE MONITOR IF EXISTS PONY_limit1cq_rm;

CALL adm_db.admin.execute_privileged_caller_sql_ACCOUNTADMIN('ADM_DROP_RM');


-- 23.13.0 Key Takeaways
--         - You can explore system usage and billing information using the Web
--         UI.
--         - You can monitor queries using the Web UI history page.
--         - You can monitor system storage usage, compute usage, credit
--         consumption, and user logins and connections using the
--         INFORMATION_SCHEMA, various table functions, and the
--         SNOWFLAKE.ACCOUNT_USAGE schema.
--         - You can create resource monitors to control credit consumption.
