
-- 2.0.0   Snowflake Virtual Warehouses
--         By the end of this lab, you will be able to:
--         - Create virtual warehouses using Snowsight
--         - Create and modify a virtual warehouse using SQL
--         - Explore the AUTO-SUSPEND and AUTO-RESUME features
--         - Suspend a warehouse using SQL commands
--         - Size Up (scale up) the virtual warehouse using Snowsight
--         - Explore the scale out function of multi-cluster warehouses
--         - Summarize the considerations for managing virtual warehouses

-- 2.1.0   Create Virtual Warehouses Using the Snowsight UI
--         An important feature in Snowflake is the ability to allocate virtual
--         warehouses of different sizes to different tasks or business
--         functions. This is called Workload Segmentation. This concept allows
--         processes such as ETL/ELT to run completely separate from end-user
--         queries or from other tasks.
--         In this lab, you will create multiple warehouses; the first warehouse
--         for running queries, a second warehouse for ingesting data, and a
--         third warehouse for high concurrency.

-- 2.1.1   In the left navigation bar, select Compute.

-- 2.1.2   In the sub-menu that appears, select Warehouses.
--         You use this area in the Snowsight UI primarily to create warehouses
--         and to view the status, name, size, cluster details, scaling
--         policies, and so forth of existing warehouses.
--         Let’s begin by creating a new virtual warehouse.

-- 2.1.3   Click on the + Warehouse button in the upper right corner to create a
--         new virtual warehouse with the specifications shown below.
--         - Warehouse Name: USERLAB_adm_load_wh
--         - Type: Standard (Gen1)
--         - Size: Medium
--         X-Small is the default size for Virtual Warehouses in Snowsight.
--         - Leave the other settings as their default.

-- 2.1.4   Scroll down and expand the Advanced Options area.
--         - Make sure Auto resume and Auto suspend are checked, and set the
--         Suspend After time to 3 minutes.
--         - Click Create Warehouse

-- 2.2.0   Load Lab SQL file

-- 2.2.1   To load the SQL file, in the left navigation bar, select Projects,
--         then, under My Workspace, select the lab SQL file corresponding to
--         this lab exercise.
--         In the SQL files, lab instructions are shown as comments. Do not skip
--         these - they are instructions you need to follow. When the
--         instructions indicate you need to run some SQL, the required code is
--         in the SQL file.
--         The code below is in your .SQL file. Scroll down to this step number
--         to find it. Step numbers in the workbook correspond to the step
--         numbers in the SQL files.

-- 2.2.2   Set query tag for this session.

ALTER SESSION SET query_tag = '(USERLAB) lab - TOPIC: Snowflake Virtual Warehouses'; 
USE SECONDARY ROLE NONE;

USE ROLE SYSADMIN;
-- Create a warehouse to be used for running standard queries 
CREATE WAREHOUSE IF NOT EXISTS USERLAB_adm_query_wh
  WAREHOUSE_SIZE = 'MEDIUM'
  WAREHOUSE_TYPE = 'STANDARD'
  GENERATION = '1'
  AUTO_SUSPEND = 60
  AUTO_RESUME = true
  MIN_CLUSTER_COUNT = 1
  MAX_CLUSTER_COUNT = 2
  INITIALLY_SUSPENDED = true
  SCALING_POLICY = 'STANDARD'
  COMMENT = 'Admin labs: Training WH for completing hands on labs queries';

-- Create another warehouse for loading data
CREATE WAREHOUSE IF NOT EXISTS USERLAB_adm_load2_wh
  WAREHOUSE_SIZE = 'MEDIUM'
  WAREHOUSE_TYPE = 'STANDARD'
  AUTO_SUSPEND = 60
  AUTO_RESUME = true
  MIN_CLUSTER_COUNT = 1
  MAX_CLUSTER_COUNT = 2
  INITIALLY_SUSPENDED = true
  SCALING_POLICY = 'STANDARD'
  COMMENT = 'Admin labs: Training WH for completing hands on lab data movement';


-- 2.2.3   Run the SHOW command to review the two (2) warehouses created by you
--         and any other warehouses that may already exist in the same account.

SHOW WAREHOUSES;


-- 2.3.0   Explore the AUTO-SUSPEND and AUTO-RESUME Features
--         AUTO-SUSPEND and AUTO-RESUME are very important features as a virtual
--         warehouse is charged only for credit usage when it is running
--         (credits are billed per second). When not in use, it is important to
--         conserve power and costs by suspending any virtual warehouses that
--         are not being used. The auto-suspend time is set in seconds, so the
--         command below sets the auto-suspend to one minute.

-- 2.3.1   Use the following SQL to issue an ALTER statement to your warehouse
--         and change the following parameters.

ALTER WAREHOUSE USERLAB_adm_load2_wh SET AUTO_SUSPEND = 60;


-- 2.3.2   Then from the navigation pane on the left, select Compute and
--         Warehouses area and locate your USERLAB_adm_load2_wh Warehouse and
--         confirm the parameter is as follows.
--         Auto Suspend: 1 minute
--         The Auto Suspend column may not be displayed in the list of
--         warehouses. To see the setting, click Columns in the top right of the
--         screen and select the Auto Suspend. You may have to click the refresh
--         icon next to the Column button to see the new column. Once Auto
--         Suspend has been added, click on the Name column to sort the list by
--         name and scroll down to find your warehouse.

-- 2.4.0   Suspend a Warehouse Using SQL Commands

-- 2.4.1   Return to your workspace.

-- 2.4.2   Use SQL to issue a command to suspend your load warehouse.

ALTER WAREHOUSE USERLAB_adm_load2_wh SUSPEND;

--         In the case of your warehouse USERLAB_adm_load2_wh, you will receive
--         the error: **“Invalid state. Warehouse ’USERLAB_ADM_LOAD2_WH’ cannot
--         be suspended.”** at this point in the lab since the warehouse was
--         created with the attribute INITIALLY_SUSPENDED=TRUE.

-- 2.4.3   Run the following statements.

USE WAREHOUSE USERLAB_adm_query_wh;
ALTER SESSION SET USE_CACHED_RESULT = false;
SELECT * FROM snowflake_sample_data.tpch_sf1000.region;

--         Because the warehouse is, by default, set to auto-resume, it will
--         turn itself on automatically when Snowflake receives a query pointed
--         to that warehouse that requires compute resource.

-- 2.4.4   show warehouses like USERLAB%:

SHOW WAREHOUSES LIKE 'USERLAB%';


-- 2.4.5   In Snowsight, click on Compute -> Warehouses.

-- 2.4.6   Locate your Warehouses and check that the Status is marked as
--         Started.
--         Note that you may need to click the Refresh button to see the current
--         state of the warehouse.

-- 2.4.7   Now wait at least a minute and then click refresh button in upper
--         right.
--         Recall we set the auto suspend to 1 minute. You should now see your
--         warehouse status as Suspended.

-- 2.5.0   Size Up (Scale Up) the Virtual Warehouse Using the Web UI
--         Warehouses are provisioned in t-shirt sizes. Size specifies the
--         amount of compute resources (CPUs, SSD storage, and memory) in a
--         virtual warehouse. Each size increase doubles the amount of resources
--         and the number of credits consumed.

-- 2.5.1   Locate your USERLAB_adm_load_wh Warehouse.

-- 2.5.2   Click on your USERLAB_adm_load_wh warehouse to open up the Warehouse
--         Activity and Query History screen.

-- 2.5.3   Click the ellipsis (three dots) in the upper right corner of the
--         screen.

-- 2.5.4   Select Edit.

-- 2.5.5   Click on Size to drop down the list of sizes.

-- 2.5.6   Select Large and click Save Warehouse.

-- 2.6.0   Size Down Using a SQL Command
--         Resizing can be performed any time, even when the virtual warehouse
--         is running.
--         Here are the effects of resizing:
--         - Suspended warehouses: no immediate impact, they will start at the
--         new size upon next resume.
--         - Running warehouses: immediate impact, running queries complete at
--         their original size while queued and future queries will run at the
--         new size.

-- 2.6.1   Return to your workspace.

-- 2.6.2   Use SQL to resize one of the warehouses and display their status:

ALTER WAREHOUSE USERLAB_adm_query_wh SET WAREHOUSE_SIZE = 'SMALL';

SHOW WAREHOUSES LIKE 'USERLAB%';

--         Locate your warehouse and confirm the size is now SMALL.

-- 2.6.3   Use the following query to compare the relative performance of
--         different warehouse sizes:
--         Larger warehouse sizes can improve performance because data can be
--         held in memory and not spilled to storage. Also, when you test
--         performance, it is important to disable the Query Result cache and
--         suspend the warehouse between runs.

USE WAREHOUSE USERLAB_adm_query_wh;

-- Suspend and resume the warehouse to flush the warehouse data cache.
-- Remember, if the warehouse is already suspended, this will cause an error. Just ignore it and continue.
ALTER WAREHOUSE USERLAB_adm_query_wh SUSPEND;

ALTER WAREHOUSE USERLAB_adm_query_wh RESUME;

ALTER SESSION SET USE_CACHED_RESULT = false;

USE SCHEMA snowflake_sample_data.tpch_sf1000;

-- The following query may take almost 1 minute to run with a SMALL warehouse size.
SELECT
l_returnflag,
l_linestatus,
sum(l_quantity) as sum_qty,
sum(l_extendedprice) as sum_base_price,
sum(l_extendedprice * (1-l_discount))
  as sum_disc_price,
sum(l_extendedprice * (1-l_discount) *
  (1+l_tax)) as sum_charge,
avg(l_quantity) as avg_qty,
avg(l_extendedprice) as avg_price,
avg(l_discount) as avg_disc,
count(*) as count_order
FROM
lineitem
WHERE
l_shipdate <= dateadd(day, -90, to_date('1998-12-01'))
GROUP BY
l_returnflag,
l_linestatus
ORDER BY
l_returnflag,
l_linestatus;


-- 2.6.4   Change the warehouse size to MEDIUM and rerun the same query.

-- Suspend and resume the warehouse to flush the warehouse data cache.
-- Remember, if the warehouse is already suspended, this will cause an error. Just ignore it and continue.
ALTER WAREHOUSE USERLAB_adm_query_wh suspend;

ALTER WAREHOUSE USERLAB_adm_query_wh resume;

ALTER WAREHOUSE USERLAB_adm_query_wh SET WAREHOUSE_SIZE = 'MEDIUM';

SHOW WAREHOUSES LIKE 'USERLAB_ADM_Q%';



-- The same query now will take about 30 seconds to run with a MEDIUM warehouse size.
SELECT
l_returnflag,
l_linestatus,
sum(l_quantity) as sum_qty,
sum(l_extendedprice) as sum_base_price,
sum(l_extendedprice * (1-l_discount))
  as sum_disc_price,
sum(l_extendedprice * (1-l_discount) *
  (1+l_tax)) as sum_charge,
avg(l_quantity) as avg_qty,
avg(l_extendedprice) as avg_price,
avg(l_discount) as avg_disc,
count(*) as count_order
FROM
lineitem
WHERE
l_shipdate <= dateadd(day, -90, to_date('1998-12-01'))
GROUP BY
l_returnflag,
l_linestatus
ORDER BY
l_returnflag,
l_linestatus;


-- 2.6.5   Change the warehouse type to GEN2 and rerun the same query.

-- Suspend and resume the warehouse to flush the warehouse data cache.
-- Remember, if the warehouse is already suspended, this will cause an error. Just ignore it and continue.
ALTER WAREHOUSE USERLAB_adm_query_wh suspend;

ALTER WAREHOUSE USERLAB_adm_query_wh resume;

ALTER WAREHOUSE USERLAB_adm_query_wh SET GENERATION = '2';

SHOW WAREHOUSES LIKE 'USERLAB_ADM_Q%';


-- The same query now will take less than 30 seconds to run with a GEN 2 MEDIUM warehouse size.
SELECT
l_returnflag,
l_linestatus,
sum(l_quantity) as sum_qty,
sum(l_extendedprice) as sum_base_price,
sum(l_extendedprice * (1-l_discount))
  as sum_disc_price,
sum(l_extendedprice * (1-l_discount) *
  (1+l_tax)) as sum_charge,
avg(l_quantity) as avg_qty,
avg(l_extendedprice) as avg_price,
avg(l_discount) as avg_disc,
count(*) as count_order
FROM
lineitem
WHERE
l_shipdate <= dateadd(day, -90, to_date('1998-12-01'))
GROUP BY
l_returnflag,
l_linestatus
ORDER BY
l_returnflag,
l_linestatus;


-- 2.7.0   Explore the Scale Out Function of Multi-Cluster Warehouses
--         A Snowflake multi-cluster warehouse consists of one or more clusters
--         of compute resources that execute queries. For a given warehouse, an
--         administrator can set both the minimum and maximum number of compute
--         clusters allocated to that warehouse.
--         Here we will show you how to create a multi_cluster warehouse, but
--         due to time constraints we will not be able to use it.

-- 2.7.1   Use the following SQL command to create a new virtual warehouse for
--         automatic concurrency scale out.

CREATE WAREHOUSE IF NOT EXISTS USERLAB_adm_scale_out_wh
  WAREHOUSE_SIZE = 'SMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = true
  MIN_CLUSTER_COUNT = 1
  MAX_CLUSTER_COUNT = 3
  INITIALLY_SUSPENDED = true
  SCALING_POLICY = 'STANDARD'
  COMMENT = 'Admin labs: Training WH for completing concurrency tests';

SHOW WAREHOUSES LIKE 'USERLAB_ADM_S%';

--         Because you are setting the Maximum Clusters to be greater than the
--         Minimum Clusters, you are configuring the Warehouse in Auto-Scale
--         Mode and allowing Snowflake to scale the virtual warehouse as needed
--         for handing fluctuating workloads. If you set the Maximum Clusters
--         and Minimum Clusters to the same number, you would be running in
--         “Maximized Mode’, which you might do for a stable workload.

-- 2.7.2   Cleanup the warehouses.

DROP WAREHOUSE USERLAB_adm_scale_out_wh;
DROP WAREHOUSE USERLAB_adm_query_wh;


-- 2.7.3   Unset query tag.

ALTER SESSION UNSET query_tag;
USE SECONDARY ROLE ALL;

--         The Scaling Policy controls when and how Snowflake will turn on/off
--         additional clusters in the warehouse, up to the number of Maximum
--         Clusters. This is designed to maximize both query responsiveness and
--         concurrency.

-- 2.8.0   Considerations for Managing Virtual Warehouses
--         - Allocate different warehouses to different roles for workload
--         separation. For example, an ELT workload should not share a warehouse
--         with a dashboard workload.
--         - Set an AUTO SUSPEND time to minimize how much idle time you are
--         paying for. Remember that you are charge for a virtual warehouse
--         while it is up and available (resumed) - whether or not it is
--         processing queries.
--         - Independently size up or size down each virtual warehouse according
--         to performance needs or data volumes. These scenarios will be covered
--         in multiple labs throughout the course.
--         - Automatically scale out using multi-clustered virtual warehouses
--         for more users and maximized concurrency.
--         - Pick the appropriate Scaling Policy for the multi-clustered virtual
--         warehouses to match workload types.

-- 2.9.0   Key Takeaways
--         - A virtual warehouse, often referred to simply as a warehouse, is a
--         cluster of compute resources in Snowflake.
--         - A warehouse provides the required resources, such as CPU, memory,
--         and temporary storage, to run queries and perform DML operations.
--         - A virtual warehouse does not have any permanent storage - it is
--         just the compute for running queries.
