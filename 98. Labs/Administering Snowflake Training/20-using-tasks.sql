
-- 20.0.0  Using Tasks
--         By the end of this lab, you will be able to:
--         - Create a task
--         - Create a tree of tasks
--         - Start and stop a tree of tasks
--         - Alter a task with a stored procedure
--         - Call a stored procedure from a task
--         The purpose of this lab is to teach you to create and execute tasks
--         and a tree of tasks.

-- 20.1.0  Scenario
--         In this exercise you will create a tree of four tasks. The scenario
--         is that for all orders in a specific month, you need to capture and
--         store the average number of days from the time an order is created
--         until it is shipped. The idea is that the table would be updated once
--         a month for reporting purposes.
--         ———————- FIRST TASK—————————
--         Generates a subset of data from the orders and lineitem tables and
--         stores it in a new table.
--         In the real world, this data would be raw data either generated or
--         loaded into Snowflake.
--         For this exercise, the data will be generated from the orders and
--         lineitem tables.
--         ———————–SECOND TASK—————————
--         Averages the data generated in the previous task and stores it in a
--         new table.
--         In the real world, this could serve as the final table for reporting
--         purposes.
--         ———————–THIRD TASK—————————
--         Generates rows with year and month values for use by the first and
--         second tasks.
--         Simulates a monthly reporting cycle, but runs the main task every
--         minute to aggregate data.
--         ———————–FOURTH TASK—————————
--         Generates rows with day and month values for use by the first and
--         second tasks.
--         A stored procedure is created to stop the main task after it runs 10
--         times, preventing tasks from running unintentionally.
--         At the end of the lab, all tables and tasks will be deleted for
--         cleanup.
--         ———————–FIFTH TASK—————————
--         Runs the stored procedure to stop the tasks, ensuring they aren’t
--         left running after the lab.
--         At the end of the lab, all tables and tasks will be deleted for
--         cleanup.
--         NOTE: Tasks left running unsupervised can consume credits.
--         In your training account, it is IMPERATIVE that you suspend any tasks
--         you create. Failure to do so could result in all students being
--         locked out of their 30-day training account.

-- 20.2.0  Load Lab SQL file

-- 20.2.1  To load the SQL file, in the left navigation bar, select Projects,
--         then, under My Workspace, select the lab SQL file corresponding to
--         this lab exercise.

-- 20.2.2  Set query tag for this session.

ALTER SESSION SET query_tag = '(PONY) lab - TOPIC: Using Tasks';


-- 20.3.0  Create Database And Warehouse

-- 20.3.1  Create database.

USE ROLE adm_role;
CREATE DATABASE IF NOT EXISTS  PONY_adm_db 
COMMENT='Database for Admin course labs';


-- 20.3.2  Create warehouse.

CREATE WAREHOUSE IF NOT EXISTS PONY_adm_wh
WAREHOUSE_SIZE=XSmall
INITIALLY_SUSPENDED=True
AUTO_SUSPEND=300
COMMENT='Warehouse for Admin course labs';


-- 20.4.0  Create Tables

-- 20.4.1  Set the context.
--         Run the following commands from the SQL file.

USE ROLE adm_role;
USE WAREHOUSE PONY_adm_wh;
USE DATABASE PONY_adm_db;
CREATE OR REPLACE SCHEMA PONY_tasks_schema;
USE SCHEMA PONY_tasks_schema;


-- 20.4.2  Run the following commands to create the final reporting tables that
--         will hold the average days to ship.

CREATE OR REPLACE TABLE avg_shipping_in_days(
    yr INTEGER, mon INTEGER,
    avg_shipping_days DECIMAL(18,2)
);


CREATE OR REPLACE TABLE avg_shipping_days(
    mon INTEGER, day INTEGER,
    avg_shipping_days DECIMAL(18,2)
);

--         The first table stores the year, the month, and the average shipping
--         days in decimal format. The second table stores the month, day,
--         average shipping days in decimal format.
--         Now let’s create the table that will hold the transformed data from
--         the order and lineitem tables that will be used to populate the
--         previously created table.

-- 20.4.3  Run the following command to create the table that will store the
--         transformed data.

CREATE OR REPLACE TABLE shipping_by_date (
    orderdate DATE,
    shipdate DATE,
    daystoship DECIMAL(18,2));

--         As you can see, we will pull over only the order date, the shipping
--         date, and the difference between them.
--         Now let’s create one more table. We’ll need it to store rows, each of
--         which will contain unique year and month values. The tasks will fetch
--         the latest month and year from the table in order to know which set
--         of data to transform and load into the previously created table.
--         We’ll also insert the first row into the table. One of our tasks will
--         automate the insertion of subsequent rows.

-- 20.4.4  Run the commands below to create the year_month table, insert the
--         first required row of data, and verify that the insert took place.

CREATE OR REPLACE TABLE year_month(
    id integer autoincrement(1,1),
    yr INTEGER, mon INTEGER
);

INSERT INTO year_month(yr, mon) VALUES (1992, 1);

SELECT * FROM year_month;


-- 20.5.0  Creating the tasks
--         Now that we’ve created the tables to be populated, let’s create the
--         task tree.

-- 20.5.1  Run the following command to create the task that will load the raw
--         data table with data from the orders and lineitem tables.

CREATE OR REPLACE TASK insert_shipping_by_date_rows
    SCHEDULE = 'USING CRON 0-59 0-23 * * * America/Chicago'
AS    
    INSERT INTO PONY_adm_db.PONY_tasks_schema.shipping_by_date (orderdate, shipdate, daystoship)
    SELECT
        o_orderdate
        , l_shipdate
        , l_shipdate - o_orderdate AS fulfill_date
    FROM
        training_db.tpch_sf1.orders O LEFT JOIN training_db.tpch_sf1.lineitem L ON O.o_orderkey = l.l_orderkey     
    WHERE
        YEAR(O_ORDERDATE) = (SELECT yr FROM PONY_adm_db.PONY_tasks_schema.year_month WHERE id = (select MAX(id) from year_month))
        AND
        MONTH(O_ORDERDATE)= (SELECT mon FROM PONY_adm_db.PONY_tasks_schema.year_month WHERE ID = (select MAX(id) from year_month));

--         Notice that the schedule is set to run every minute of every hour.
--         For the purposes of this lab, each minute will bring over one month’s
--         worth of data from the order and lineitem tables.
--         Note that the AS clause of the task contains an INSERT statement that
--         calls a SELECT statement to populate the table. The WHERE clause of
--         the SELECT statement that the INSERT statement uses to populate the
--         table also selects data where the year and month fields’ values match
--         the month and year values most recently inserted into the year_month
--         table. Thus, each minute it will pull one month’s worth of data.

-- 20.5.2  Run the following commands to create the task that will populate the
--         table for the average monthly shipping.

CREATE OR REPLACE TASK average_monthly_shipping
    AFTER insert_shipping_by_date_rows
AS  
    INSERT INTO PONY_adm_db.PONY_tasks_schema.avg_shipping_in_days(yr, mon, avg_shipping_days)
    SELECT
        YEAR(orderdate) AS yr
      , MONTH(orderdate) AS mon
      , AVG(daystoship) AS avg_shipping_days
    FROM
        PONY_adm_db.PONY_tasks_schema.shipping_by_date
    WHERE
        yr = (SELECT yr FROM PONY_adm_db.PONY_tasks_schema.year_month WHERE id = (select MAX(id) from year_month))
        AND
        mon = (SELECT mon FROM PONY_adm_db.PONY_tasks_schema.year_month WHERE id = (select MAX(id) from year_month))
    GROUP BY
        YEAR(orderdate)
      , MONTH(orderdate);

--         Note that this task does not have a schedule but rather an AFTER
--         clause, so it executes after the main task completes. The WHERE
--         clause of the SELECT statement that the INSERT statement uses to
--         populate the table also selects data where the yr and mon fields’
--         values match the month and year values most recently inserted into
--         the year_month table.

-- 20.5.3  Add another task here to build the DAG.

CREATE OR REPLACE TASK average_daily_shipping
AFTER insert_shipping_by_date_rows
AS
INSERT INTO PONY_adm_db.PONY_tasks_schema.avg_shipping_days(day, mon, avg_shipping_days)
SELECT
MONTH(orderdate) AS mon
, DAY(orderdate) as day
, AVG(daystoship) AS avg_shipping_days
FROM
PONY_adm_db.PONY_tasks_schema.shipping_by_date
GROUP BY
DAY(orderdate)
, MONTH(orderdate);


-- 20.5.4  Run the following command to create the task that will increment the
--         year and month in the year_month table.

CREATE OR REPLACE TASK increment_year_month
    AFTER average_monthly_shipping
AS   
    INSERT INTO year_month (yr, mon)
    SELECT DISTINCT
        IFF(mon=12, yr+1, yr) AS YR
        , IFF(mon=12, 1, mon+1) AS MON
    FROM year_month
    WHERE ID = (select MAX(ID) from year_month);

--         This task is fairly simple. As you can see from the AFTER clause and
--         the SELECT statement, after the previous task averages the current
--         month’s monthly shipping time frame in days, a new row is added for
--         the next month.

-- 20.5.5  Run the following commands to create the task that will stop the tree
--         from executing.
--         Below is a JavaScript stored procedure that is designed to stop the
--         task tree when it is called. If you’re not familiar with stored
--         procedures, don’t worry. For the purposes of this lab, the main
--         takeaway is that it is possible for you to design, create, and call a
--         stored procedure to stop any running tasks.

CREATE OR REPLACE PROCEDURE stop_tasks()
RETURNS string
LANGUAGE javascript
STRICT
AS
$$
var r='continue';
var mon = snowflake.createStatement({sqlText: 'SELECT mon FROM PONY_adm_db.PONY_tasks_schema.year_month WHERE id = (select MAX(id) from year_month);'});

var result = mon.execute();
result.next();
var x = result.getColumnValue(1);

if (x>=11) {

var killstmt1 = snowflake.createStatement({sqlText: 'ALTER TASK insert_shipping_by_date_rows SUSPEND;'});
var killstmt2 = snowflake.createStatement({sqlText: 'ALTER TASK average_monthly_shipping SUSPEND;'});
var killstmt3 = snowflake.createStatement({sqlText: 'ALTER TASK increment_year_month SUSPEND;'});
var killstmt4 = snowflake.createStatement({sqlText: 'ALTER TASK average_daily_shipping SUSPEND;'});

killstmt1.execute();
killstmt2.execute();
killstmt3.execute();
killstmt4.execute();

r = 'stopped'
}
return r;

$$;

CREATE OR REPLACE TASK stop_tasks
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
    AFTER increment_year_month
AS
    CALL stop_tasks();

--         The idea behind this task is that it will call a stored procedure
--         after all the other tasks have fired and all the required inserts
--         have taken place. The stored procedure will suspend the previous
--         three tasks if there is a month in any of the year_month table rows
--         that has an 11. This will keep the tasks from running indefinitely.

-- 20.5.6  Show the tasks to ensure they all four were created correctly.

SHOW TASKS;


-- 20.5.7  Run the following commands to start the tree:
--         Now we’re going to start the tree and monitor the activity.
--         The system function below recursively starts all the tasks in the
--         tree. If you were starting only one task you would use an ALTER TASK
--         <task name> RESUME statement to start it.

SELECT SYSTEM$TASK_DEPENDENTS_ENABLE('insert_shipping_by_date_rows');


-- 20.5.8  Use the following queries to monitor what is going on in the tables
--         over the next 10-15 minutes and to view the state of the tasks.

SELECT * FROM year_month;
SELECT * FROM shipping_by_date;
SELECT * FROM avg_shipping_in_days;
SELECT * FROM avg_shipping_days;

DESCRIBE TASK insert_shipping_by_date_rows;
DESCRIBE TASK average_monthly_shipping;
DESCRIBE TASK increment_year_month;
DESCRIBE TASK average_daily_shipping;

--         You should notice that year and month rows are being added to the
--         year_month table, that the SHIPPING_BY_DATE table is full of raw
--         data, and that the avg_shipping_in_days table is getting a new month
--         of aggregated data each minute.

-- 20.5.9  Use this command to see the task history for all of the tasks.

SELECT *
  FROM TABLE(information_schema.task_history(
    SCHEDULED_TIME_RANGE_START=>DATEADD('hour',-1,CURRENT_TIMESTAMP())));  


-- 20.5.10 Once you feel the task is finished then use SHOW TASKS; to see if the
--         tasks have suspended.

SHOW TASKS;


-- 20.5.11 View the tasks graphs in snowsight.
--         In the left-hand navigation pane, under Horizon Catalog, hover over
--         Catalog, then click on Database Explorer from the pop-up menu. Expand
--         your database, then this lab’s schema, and finally, expand Tasks.
--         Select on one of the tasks, then click on the Graph tab. Explore all
--         the tasks involved.

-- 20.6.0  Ending the lab

-- 20.6.1  If you don’t wish to wait until the last task has stopped the process
--         and are ready to complete the lab, you can run the ALTER TASK command
--         below to immediately stop the task tree. this will suspend only the
--         root task, but the NET effect will be that neither the root task nor
--         any child tasks in the tree will run:

ALTER TASK insert_shipping_by_date_rows SUSPEND;
SHOW TASKS;


-- 20.6.2  If you waited until the last task in the tree stopped the process, or
--         if you are done with the lab and ran the previous ALTER TASK command,
--         run the commands below to clear out the objects used in this lab:

DROP TABLE shipping_by_date;
DROP TABLE avg_shipping_in_days;
DROP TABLE avg_shipping_days;
DROP TABLE year_month;
DROP TASK insert_shipping_by_date_rows;
DROP TASK average_monthly_shipping;
DROP TASK increment_year_month;
DROP TASK stop_tasks;
DROP TASK average_daily_shipping;
USE SCHEMA public;
DROP SCHEMA PONY_tasks_schema;
ALTER WAREHOUSE PONY_adm_wh SUSPEND;


-- 20.7.0  Key Takeaways
--         - The first task in a tree of tasks must be started upon a schedule,
--         using either Snowflake-specific scheduling syntax or CRON syntax.
--         - Subsequent tasks in a tree of tasks must be started by calling them
--         from the predecessor task with an AFTER clause.
--         - You can start a tree of tasks with this statement: SELECT
--         system$task_dependents_enable(<>);.
--         - It is imperative to stop a task you no longer need in order to
--         avoid wasting credits.
--         - A stored procedure can be used to stop a tree of tasks.
--         - You can use the statement CALL stored_procedure_name() in the AS
--         clause of a task to invoke a stored procedure.
