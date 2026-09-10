
-- 4.0.0   Monitoring Using Snowflake Notebooks
--         In this lab you will practice the following:
--         - Open a pre-built Snowflake Notebook with sample monitoring code
--         - Run the code in notebook cells
--         - Learn how to query the snowflake.account_usage views and generate
--         insights
--         - Schedule the notebook to run at a particular time

-- 4.1.0   Load Lab Notebook

-- 4.1.1   Go back to Snowsight after the last lab.

-- 4.1.2   To load the SQL file, in the left navigation bar select Projects,
--         then, under My Workspace select the lab SQL file corresponding to
--         this lab exercise.

-- 4.1.3   Create the database.
USE ROLE SYSADMIN;
CREATE DATABASE IF NOT EXISTS USERLAB_adm_db
COMMENT='Database for Admin course labs';


-- 4.1.4   Create the warehouse.

CREATE  WAREHOUSE IF NOT EXISTS USERLAB_adm_wh
    WAREHOUSE_SIZE=XSmall
    INITIALLY_SUSPENDED=True
    AUTO_SUSPEND=300
    COMMENT='Warehouse for Admin course labs';


-- 4.1.5   Set the following as context within this worksheet.

USE ROLE SYSADMIN;
USE WAREHOUSE USERLAB_adm_wh;
CREATE OR REPLACE SCHEMA USERLAB_adm_db.monitoring;
USE SCHEMA USERLAB_adm_db.monitoring;

-- Go to 4.1.9 and open 04.01-admin_monitoring.ipynb.

-- 4.1.6   List the file on the resources stage.

--LIST @training_db.admin.notebooks;

--         You should see a single file with a .ipynb extension

-- 4.1.7   Copy notebook to My Workspace.

--COPY FILES INTO 'snow://workspace/USER$.PUBLIC.DEFAULT$/versions/live/'
--FROM @training_db.admin.notebooks;


-- 4.1.8   Confirm that the notebook has been copied to My Workspace.
--         Refresh the listing in your workspace by clicking the ellipsis (…) in
--         the My Workspace header area and select Refresh. The .ipynb file
--         should be listed in the Workspace pane on the left.

-- 4.1.9   Open the notebook and follow the instructions.
--         Click on Projects and then Workspaces to continue the lab.
--         Once completed, close the notebook and return to the worksheet.

-- 4.2.0   Key Takeaways
--         - Notebooks are a versatile development environment.
--         - Query results can be visualised using streamlit charts.
--         - You can persist data in snowflake.account_usage views if necessary.
--         - Notebooks can be scheduled to run at particular intervals.
