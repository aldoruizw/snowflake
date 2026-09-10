
-- 22.0.0  DML and Transaction Model
--         By the end of this lab, you will be able to:
--         - Summarize the transaction model and concurrency control.
--         - Explore autocommit default values.
--         - Change session values for the autocommit parameter.
--         - Explore multi-statement transactions.
--         - Monitor the SHOW LOCKS and LOCK_TIMEOUT parameters for concurrency
--         control.
--         - Use SYSTEM$ABORT_TRANSACTION to release locks and terminate
--         transactions.
--         This lab will explore Data Manipulation Language (DML) and various
--         commands for transaction controls. Pay close attention to the
--         separate Workspace tabs and how they process data. Review the list of
--         items we will be covering and what the learning objectives are.

-- 22.1.0  Transaction Model and Concurrency Control
--         This lab will use two (2) SQL files, Lab FILE-A and Lab FILE-B, to
--         run various DML statements in order to emulate two (2) different
--         transaction scopes working in a concurrent environment.

-- 22.2.0  Load Lab SQL file

-- 22.2.1  To load the SQL file, in the left navigation bar, select Projects,
--         then, under My Workspace, find the lab SQL file corresponding to this
--         lab exercise.

-- 22.2.2  Click the ellipsis … to the right of the SQL lab file that appear
--         when hovering over the file name. Choose Duplicate from the pop-up
--         menu that appears.

-- 22.2.3  Click the ellipsis … to the right of the original SQL lab file again,
--         and this time, choose Rename from the pop-up menu that appears.
--         Rename the SQL file to FILE-A.sql.

-- 22.2.4  Repeat the process for the duplicated SQL file, renaming it to
--         FILE-B.sql.
--         Renaming the SQL files will move them to the top of the folder order
--         in the My Workspace pane.

-- 22.2.5  Set query tag for this session.

ALTER SESSION SET query_tag = '(PONY) lab - TOPIC: DML and Transaction Model - A';


-- 22.2.6  You will only execute statements in this workspace tab that are
--         surrounded by the FILE-A comments:

-- FILE-A --


-- 22.2.7  Create your database.

-- FILE-A --
USE ROLE adm_role;
CREATE DATABASE IF NOT EXISTS PONY_adm_db 
COMMENT='Database for Admin course labs';


-- 22.2.8  Create your warehouse.

-- FILE-A --
CREATE WAREHOUSE IF NOT EXISTS PONY_adm_wh
    WAREHOUSE_SIZE=XSmall
    INITIALLY_SUSPENDED=True
    AUTO_SUSPEND=300
    COMMENT='Warehouse for Admin course labs';


-- 22.2.9  Move to SQL file FILE-B.
--         Locate the FILE-B.sql tab in your workspace and click on it.
--         Alternatively, locate and select the FILE-B.sql file in the My
--         Workspace pane under your user folder.

-- 22.2.10 Set query tag for this session.

ALTER SESSION SET query_tag = '(PONY) lab - TOPIC: DML and Transaction Model - B';


-- 22.2.11 You will only execute statements in this tab that are surrounded by
--         the FILE-B comments.

-- FILE-B --


-- 22.3.0  Explore the Autocommit Default Value

-- 22.3.1  Set the context for FILE-A:

-- FILE-A --
USE ROLE adm_role;
USE DATABASE PONY_adm_db;
USE SCHEMA public;
CREATE WAREHOUSE IF NOT EXISTS PONY_adm_load_wh;
USE WAREHOUSE PONY_adm_load_wh;
-- FILE-A --


-- 22.3.2  Create a table and insert some records:

-- FILE-A --
CREATE OR REPLACE TABLE t1 (
  c1    BIGINT,
  c2    STRING
);

INSERT INTO t1 (c1, c2)
    VALUES(1,'ONE'), (2, 'TWO'), (3,'THREE');
-- FILE-A --


-- 22.3.3  Show the session is set to AUTOCOMMIT by default:

-- FILE-A --
SHOW PARAMETERS LIKE 'AUTOCOMMIT' IN SESSION;
-- FILE-A --


-- 22.3.4  Run query and confirm the data is available because the INSERT
--         statement has been autocommitted:

-- FILE-A --
SELECT * FROM t1;
-- FILE-A --


-- 22.3.5  Rollback the above INSERT statement:

-- FILE-A --
ROLLBACK;
-- FILE-A --


-- 22.3.6  Re-run query to query from the table:

-- FILE-A --
SELECT * FROM t1;
-- FILE-A --

--         You should see all three (3) records since AUTOCOMMIT is true. There
--         is nothing to roll back.

-- 22.4.0  Change the Session Value for the Autocommit Parameter

-- 22.4.1  Set parameter of AUTOCOMMIT to off:

-- FILE-A --
ALTER SESSION SET AUTOCOMMIT = FALSE;
-- FILE-A --


-- 22.4.2  Confirm that AUTOCOMMIT is set to FALSE:

-- FILE-A --
SHOW PARAMETERS LIKE 'AUTOCOMMIT' IN SESSION;
-- FILE-A --


-- 22.4.3  Insert some new records:

-- FILE-A --
INSERT INTO T1 (C1, C2)
    VALUES(4,'FOUR'), (5, 'FIVE');
-- FILE-A --


-- 22.4.4  Run a query to check for the new records. The two (2) new records are
--         uncommitted data but are visible to the current transaction.

-- FILE-A --
SELECT * FROM t1;
-- FILE-A --

--         You should see five (5) rows. Confirm this is the case.

-- 22.4.5  SWITCH TO OTHER WORKSPACE TAB ——> FILE-B

-- 22.4.6  Set the context:

-- FILE-B --
USE ROLE adm_role;
USE DATABASE PONY_adm_db;
USE SCHEMA public;
USE WAREHOUSE PONY_adm_load_wh;
-- FILE-B --


-- 22.4.7  Run the following query in this Workspace tab (FILE-B) and show it
--         cannot see uncommitted data produced in the FILE-A Workspace tab.

-- FILE-B --
-- With READ COMMITTED isolation support for table, a statement sees
-- only data that was committed before the statement began.
SELECT * FROM T1;
-- FILE-B --

--         You should see only three (3) rows since the transaction for the
--         insert (of 2 rows) in the other Workspace tab (FILE-A), is still not
--         yet complete and those two (2) other rows are not visible to the new
--         transaction in this Workspace tab (FILE-B).

-- 22.4.8  SWITCH BACK TO OTHER WORKSPACE TAB ——> FILE-A

-- 22.4.9  Rollback the INSERT statement in the transaction originated in
--         Workspace tab FILE-A:

-- FILE-A --
ROLLBACK;
-- FILE-A --


-- 22.4.10 Run the query to select from the table. You should see only three (3)
--         rows as the two (2) new records have been rolled backed successfully:

-- FILE-A --
SELECT * FROM t1;
-- FILE-A --


-- 22.4.11 Insert the two (2) rows again in Workspace tab FILE-A:

-- FILE-A --
INSERT INTO T1 (C1, C2)
    VALUES(4,'FOUR'), (5, 'FIVE');
-- FILE-A --


-- 22.4.12 Execute a COMMIT statement, and commit the two (2) extra rows:

-- FILE-A --
COMMIT;
-- FILE-A --


-- 22.4.13 Query the table again:

-- FILE-A --
SELECT * FROM t1;
-- FILE-A --

--         You should be able to see five (5) rows; the two (2) new records are
--         made permanent to the table after the commit.

-- 22.4.14 SWITCH TO OTHER WORKSPACE TAB ——> FILE-B

-- 22.4.15 Query the table again:

-- FILE-B --
SELECT * FROM t1;
-- FILE-B --

--         You should also be able to see five (5) rows; the two (2) new records
--         are made permanent to the table after the commit.

-- 22.5.0  Explore Multi-Statement Transactions

-- 22.5.1  SWITCH BACK TO WORKSPACE TAB FILE-A

-- 22.5.2  Start a new multi-statement transaction in Workspace tab FILE-A:

-- FILE-A --
BEGIN TRANSACTION;
-- FILE-A --


-- 22.5.3  Execute two (2) insert statements in this transaction:

-- FILE-A --
INSERT INTO t1 (c1, c2)  VALUES(6,'SIX');

INSERT INTO t1 (c1, c2)  VALUES(7,'SEVEN'), (8,'EIGHT');
-- FILE-A --


-- 22.5.4  End the new multi-statement transaction by running the COMMIT
--         statement:

-- FILE-A --
COMMIT;
-- FILE-A --

--         The COMMIT statement ends the multi-statement transaction and commits
--         the three (3) extra rows.

-- 22.5.5  Query the table to see that new rows added by the two (2) INSERT
--         statements above:

-- FILE-A --
SELECT * FROM t1;
-- FILE-A --

--         You should see eight (8) rows in the result.

-- 22.5.6  Insert a new row to the table:

-- FILE-A --
INSERT INTO T1 (C1, C2)  VALUES(9,'NINE');
-- FILE-A --


-- 22.5.7  Execute a ROLLBACK statement:

-- FILE-A --
ROLLBACK;
-- FILE-A --

--         This Rollback statement should rollback the INSERT statement which
--         was started in its own new transaction.

-- 22.5.8  Confirm that AUTOCOMMIT in current session is still set to FALSE:

-- FILE-A --
SHOW PARAMETERS LIKE 'AUTOCOMMIT' IN SESSION;
-- FILE-A --


-- 22.5.9  Query the table. You should see only eight (8) rows because the newly
--         started transaction was rolled back successfully.

-- FILE-A --
SELECT * FROM t1;
-- FILE-A --


-- 22.6.0  Monitor Using SHOW LOCKS and LOCK_TIMEOUT Parameters for Concurrency
--         Control
--         Explore the transaction-related parameter, LOCK_TIMEOUT, which
--         controls the number of seconds to wait while trying to lock a
--         resource, before timing out and aborting the waiting statement:

-- FILE-A --
SHOW PARAMETERS LIKE '%lock%';
-- FILE-A --

--         By default, this parameter is set to 43,200 seconds (i.e. 12 hours).

-- 22.6.1  Run a SELECT statement on table t1:

-- FILE-A --
SELECT * FROM t1;
-- FILE-A --


-- 22.6.2  Use the SHOW LOCKS command to show that SELECT does not place any
--         lock on underlying table:

-- FILE-A --
SHOW LOCKS;
-- FILE-A --

--         The SHOW command in this step should return no records as the query
--         does not place a lock on the underlying table.

-- 22.6.3  Confirm that AUTOCOMMIT in current session is still set to FALSE:

-- FILE-A --
SHOW PARAMETERS LIKE 'AUTOCOMMIT' IN SESSION;
-- FILE-A --


-- 22.6.4  Run UPDATE on table t1:

-- FILE-A --
UPDATE t1
  SET c2='Second UPDATE'
  WHERE c1=8;
-- FILE-A --


-- 22.6.5  Check that the UPDATE statement succeeds and verify the record has
--         indeed been updated.

-- FILE-A --
SELECT c2
FROM t1
WHERE c1 = 8;
-- FILE-A --


-- 22.6.6  Run the SHOW LOCKS command to confirm that the UPDATE statement has
--         placed a partitions lock on the target table t1 within the current
--         transaction, which is still active.

-- FILE-A --
SHOW LOCKS;
-- FILE-A --

--         The current transaction in Workspace tab FILE-A has a HOLDING status
--         with a lock on the target table, t1.
--         The SHOW command in this step should return one (1) record. See the
--         following example:

-- 22.6.7  SWITCH TO WORKSPACE TAB FILE-B

-- 22.6.8  Run the SHOW LOCKS command here and you should see the same locking
--         output as in the previous step:

-- FILE-B --
SHOW LOCKS;
-- FILE-B --


-- 22.6.9  While remaining in Workspace tab FILE-B, run the following DELETE
--         statement to the same target table t1:

-- FILE-B --
DELETE FROM t1
WHERE c1=7;
-- FILE-B --

--         Your DELETE statement in Workspace tab FILE-B will be blocked from
--         completing because of the lock placed on the target table t1 by the
--         UPDATE statement in Workspace tab FILE-A.

-- 22.6.10 SWITCH TO WORKSPACE TAB FILE-A

-- 22.6.11 Run the SHOW LOCKS command:

-- FILE-A --
SHOW LOCKS;
-- FILE-A --

--         The SHOW command in this step should return two (2) records.
--         You should also still see your update statement in Workspace tab
--         FILE-A with a HOLDING status.
--         You should see your blocked (delete) statement from Workspace tab
--         FILE-B with a WAITING status.

-- 22.6.12 Execute the ROLLBACK statement to end the transaction and release the
--         lock:

-- FILE-A --
ROLLBACK;
-- FILE-A --


-- 22.6.13 Run the SHOW LOCKS command to show that the lock is released:

-- FILE-A --
SHOW LOCKS;
-- FILE-A --

--         The SHOW command in this step should return no record as the lock has
--         been released with the ROLLBACK statement.

-- 22.6.14 SWITCH TO WORKSPACE TAB FILE-B

-- 22.6.15 Check that the DELETE statement is completed now, as shown below,
--         because the lock on the target table t1 has been released by the
--         other transaction, thus allowing the DELETE statement on FILE-B to
--         also complete (FILE-B’s session is set to AUTOCOMMIT = TRUE).:

-- FILE-B --
SHOW LOCKS;
-- FILE-B --


-- FILE-B --
SELECT * FROM T1;
-- FILE-B --


-- 22.7.0  Use SYSTEM$ABORT_TRANSACTION to Release Locks and Terminate
--         Transactions

-- 22.7.1  SWITCH TO WORKSPACE TAB FILE-A

-- 22.7.2  Execute DELETE statement on table t1:

-- FILE-A --
DELETE FROM t1
WHERE c1=6;
-- FILE-A --


-- 22.7.3  SWITCH TO WORKSPACE TAB FILE-B

-- 22.7.4  Execute the SHOW LOCKS statement:

-- FILE-B --
SHOW LOCKS;
-- FILE-B --

--         The SHOW LOCKS output shows the target table t1 in HOLDING status.

-- 22.7.5  Review the transaction id associated with the DELETE statement.
--         An account administrator can use the system function
--         SYSTEM$ABORT_TRANSACTION to release any lock on any user’s
--         transactions by executing the function using the transaction column
--         from the SHOW LOCKS output.

-- FILE-B --
SELECT SYSTEM$ABORT_TRANSACTION(<transaction_id>);
-- FILE-B --

--         Do not include commas in transaction_id value. For example,
--         1654029937500 vs. 1,654,029,937,500

-- 22.7.6  SWITCH TO WORKSPACE TAB FILE-A

-- 22.7.7  End the transaction by running the COMMIT statement:
--         Since the transaction was already aborted, this COMMIT will return a
--         COMMIT failed error message.

-- FILE-A --
COMMIT;
-- FILE-A --


-- 22.8.0  Key Takeaways
--         - Snowflake supports using transaction control syntax.
--         - By default, the parameter AUTOCOMMIT is enabled but BEGIN
--         TRANSACTION and COMMIT|ROLLBACK can still be used to do a manual
--         transaction.
--         - The SHOW LOCKS command will show current locks on the system.
