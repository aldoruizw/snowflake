
-- 21.0.0  Snowflake Querying Best Practices and Profiling
--         By the end of this lab, you will be able to:
--         - Use the Query Profile.
--         - Use other resources for understanding the Query Profile.
--         - Review best practices of efficient SQL queries in Snowflake.
--         - Provide filters in your queries to assist the SQL pruner in
--         restricting data access.
--         - Explore GROUP BY and ORDER BY operation performance.
--         - Use an ORDER BY performance example.
--         - Explore the LIMIT clause.
--         - Review JOIN Optimizations in Snowflake.
--         - Learn about dynamic partition pruning.
--         The Query Profile, available through Snowsight, provides execution
--         details for a query. For the selected query, it provides a graphical
--         representation of the main components of the processing plan for the
--         query, with statistics for each component, along with details and
--         statistics for the overall query.
--         The Query Profile includes the following features:
--         The operator tree, which provides a graphical representation of all
--         operator nodes the execution engine will perform, reading the results
--         from bottom to top, and from left to right.
--         Operators are the functional building blocks of a query. They are
--         responsible for different aspects of data management and processing,
--         including data access, transformations, and updates.
--         The node list displays a collapsible list of operator nodes by
--         execution time.
--         Links representing the data flow between each operator node. Each
--         link provides the amount of data processed in the terms of number of
--         rows processed.
--         Percentage represents the percentage of time this node consumed
--         within the query step (e.g., 25% for Aggregate [5]). This information
--         is also reflected in the blue bar at the bottom of the operator node,
--         allowing for easy visual identification of performance-critical
--         operators.

-- 21.1.0  Load Lab SQL file

-- 21.1.1  To load the SQL file, in the left navigation bar, select Projects,
--         then, under My Workspace, select the lab SQL file corresponding to
--         this lab exercise.

-- 21.1.2  Set query tag for this session.

ALTER SESSION SET query_tag = '(PONY) lab - TOPIC: Snowflake Querying Best Practices and Profiling ';


-- 21.2.0  Learn to Use the Query Profile
--         We are going to practice using the Snowflake Query Profile to read
--         the execution plan of a query including the various SQL operations
--         and performance metrics.

-- 21.2.1  Create the warehouse.

USE ROLE adm_role;
CREATE WAREHOUSE IF NOT EXISTS PONY_adm_wh 
COMMENT='Warehouse for admin labs';
USE WAREHOUSE PONY_adm_wh;


-- 21.2.2  Run the following commands to set the context and to disable the use
--         of the Query Result cache.

USE SCHEMA snowflake_sample_data.tpcds_sf10tcl;
ALTER WAREHOUSE PONY_adm_wh SET warehouse_size=medium;
ALTER SESSION SET
USE_CACHED_RESULT = false;


-- 21.2.3  Run the following query.
--         This query reports the total extended sales price per item brand of a
--         specific manufacturer (939) for all sales in a specific month of the
--         year (month 12).

-- 21.2.4  Run the query.

SELECT  dt.d_year
    ,item.i_brand_id brand_id
    ,item.i_brand brand
    ,sum(ss_net_profit) sum_agg
FROM  date_dim dt
    ,store_sales
    ,item
WHERE dt.d_date_sk = store_sales.ss_sold_date_sk
AND store_sales.ss_item_sk = item.i_item_sk
AND item.i_manufact_id = 939
AND dt.d_moy=12
GROUP BY
dt.d_year,item.i_brand,item.i_brand_id
ORDER BY
dt.d_year ,sum_agg desc, brand_id
LIMIT 100;

--         The preceding query may exceed 90 seconds if using a medium-sized
--         warehouse. Be aware that some queries listed here may take longer to
--         execute. Approximate times will be posted if they are expected to
--         exceed 60 seconds.

-- 21.2.5  Access the Query Profile.
--         In the Query History pane, at the bottom of the Snowsight Workspace,
--         click on query ID of the statement you just executed.
--         This will bring up a new browser tab with the Query Details. Click on
--         the Query Profile tab to continue.
--         Be aware that the numbers and results shown here might not exactly
--         match the results your queries display. The Snowflake optimizer
--         changes over time and this diagram is just an example.
--         This next section will explain what you are seeing in the query
--         profile for the query above.

-- 21.2.6  List Operator Nodes by Execution Time.
--         The Most Expensive Nodes panel lists nodes by execution time in
--         descending order, which enables users to quickly locate the costliest
--         operator nodes in terms of execution time.

-- 21.2.7  What is the most expensive Node in this query? .
--         Click on the most expensive node to open the node details. Notice in
--         the Profile Overview for this node the execution was mainly Remote
--         Disk I/O.
--         With the TableScan node still selected, look at the Attributes
--         section and notice the name of the table is STORE_SALES and there are
--         only three columns out of 24 in the select statement.
--         Next check the Statistics section. Notice the pruning for this table
--         is:
--         - Partitions scanned: 11,955
--         - Partitions total: 72,721

-- 21.2.8  Review the Operator Tree.
--         The tree provides a graphical representation of the operator nodes
--         that comprise the query and the links that connect each operator.
--         Operators are the functional building blocks of a query. They are
--         responsible for different aspects of data management and processing,
--         including data access, transformations and updates. Each operator
--         node in the tree includes some basic attributes:
--         - Type # - Operator type and ID Number. Example: Aggregate [5]
--         - Percentage - Fraction of time that this operator consumed within
--         the query step
--         - Label - Operator-specific additional information (e.g. SUM(X.J) for
--         Aggregate [5])
--         Operators are connected with Links showing the number of rows passed
--         between each operation.

-- 21.2.9  Find a filter operator and click on it.
--         Notice in the Attributes section the Filter Condition can be seen.
--         Also notice the number of rows coming into the filter operator is the
--         same as the number coming out of the filter. This is because the
--         filter operation is pushed down to the tablescan operator and is not
--         a separate operation.

-- 21.2.10 Find a JoinFilter operator and click on it.
--         Notice in the text of the node it shows which Join node is used to
--         filter the data.

-- 21.2.11 Find an Aggregate operator and click on it.
--         Notice in the Attributes section the Grouping Keys and Aggregate
--         Functions can be seen. Aggregates are handled during the processing
--         of the data and not after the data has been completely read. This
--         results in faster processing. Another interesting point about the
--         Aggregate operator is that it runs in parallel on the compute nodes
--         of the virtual warehouse, to process the data local to each compute
--         node. This can be seen in the Statistics section showing the Bytes
--         sent over the network.

-- 21.2.12 Find the SortWithLimit operator and click on it.
--         Notice the Attributes section shows the Sort Keys and the limit
--         value.

-- 21.3.0  Resources for Understanding the Query Profile
--         The documentation contains detailed explanations about other
--         operators you may observe in a query profile. The URL is:
--         https://docs.snowflake.com/en/user-guide/ui-query-profile.html#query-
--         profile-interface
--         Additional details included in the overview/detail pane that is
--         divided into three (3) sections:
--         Operator Details:
--         Execution Time:
--         Execution time provides information about where time was spent during
--         the querying process. Time spent can be broken down into categories,
--         which are displayed in the following order:
--         - Processing - time spent on data processing by the CPU.
--         - Local Disk IO - time when the processing was blocked by local disk
--         access (local SSD on virtual warehouse).
--         - Remote Disk IO - time when the processing was blocked by remote
--         disk access (remote Cloud storage).
--         - Network Communication - time when the processing was waiting for
--         the network data transfer.
--         - Synchronization - various synchronization activities between
--         participating processes.
--         - Initialization - time spent setting up the query processing.
--         Statistics:
--         A major source of information provided in the Detail panel is the
--         various statistics, grouped into the following sections:
--         - IO - information about the input-output operations performed during
--         the query
--         - Scan progress - the percentage of data scanned for a given table so
--         far.
--         - Bytes scanned - the number of bytes scanned so far.
--         - Percentage scanned from cache - the percentage of data scanned from
--         the local disk cache.
--         - Bytes written - bytes written (e.g. when loading into a table).
--         - Bytes written to result - bytes written to a result object.
--         - Bytes read from result - bytes read from a result object.
--         - External bytes scanned - bytes read from an external object, e.g. a
--         stage.
--         - Pruning - information on the effects of table pruning:
--         - Partitions scanned - number of partitions scanned so far.
--         - Partitions total - total number of partitions in a given table.
--         - Spilling - information about disk usage for operations where
--         intermediate results do not fit in memory:
--         - Bytes spilled to local storage - volume of data spilled to local
--         disk.
--         - Bytes spilled to remote storage - volume of data spilled to remote
--         disk.
--         - Network - network communication
--         - Bytes sent over the network - amount of data sent over the network.

-- 21.4.0  Review Snowflake Best Practices of Efficient SQL Queries in Snowflake

-- 21.4.1  Snowflake best practices for writing efficient high performing SQL
--         queries.
--         - Select only the columns you need and avoid using SELECT *
--         - Apply appropriate filters so partition pruning can occur
--         - GROUP BY columns with a small number of distinct values
--         - ORDER BY small cardinality columns
--         - Apply ORDER BY only in top level SELECT
--         - Use LIMIT to restrict the number of rows in result set
--         - Use columns in the JOIN predicate that match the clustering order
--         so that the query optimizer can push down partition pruning to the
--         probe side of Hash Joins
--         - JOIN on unique key or primary key
--         - Use TEMPORARY Table to materialize repetitive subqueries and
--         intermediate results to control cost of repetitive computes

-- 21.4.2  Key benefits.
--         Writing effective, high-performing SQL queries will result in
--         efficient compute usage (virtual warehouse) and cost optimization.

-- 21.4.3  TPCH Benchmark Schema.

-- 21.5.0  Provide Filter in Query WHERE Clause to Restrict Dataset as Much as
--         Possible

-- 21.5.1  Using columns matching the table’s clustering dimensions will provide
--         the best pruning of micro-partitions since this type of filter allows
--         your query to access only relevant subsets of data, which improves
--         performance and reduces costs.

-- 21.5.2  Switch to the TPCH_SF1000 Schema.

USE schema snowflake_sample_data.TPCH_SF1000;


-- 21.5.3  Filter column matches table’s clustering column.

-- 21.5.4  Run the following query.

SELECT
    c_custkey,
    c_name,
    sum(l_extendedprice * (1 - l_discount)) as revenue,
    c_acctbal,
    n_name,
    c_address,
    c_phone,
    c_comment
FROM
    customer,
    orders,
    lineitem,
    nation
WHERE
    c_custkey = o_custkey
and l_orderkey = o_orderkey
and o_orderdate >= to_date('1993-10-01')
and o_orderdate < dateadd(month, 3, to_date('1993-10-01'))
and l_returnflag = 'R'
and c_nationkey = n_nationkey
GROUP BY
    c_custkey,
    c_name,
    c_acctbal,
    c_phone,
    n_name,
    c_address,
    c_comment
ORDER BY
    3 desc
LIMIT 20;


-- 21.5.5  Access the query profile after the execution completes.

-- 21.5.6  Locate the TableScan node for the ORDERS table.

-- 21.5.7  Take note of the performance metrics in the Statistics panel.
--         - Partitions scanned (124)
--         - Partitions and total partitions (3,242) as shown.

-- 21.5.8  Pruning skips a large portion of partitions. This corresponds to the
--         following filter.
--         - Filter condition (ORDERS.O_ORDERDATE >= 1993-10-01) AND
--         (ORDERS.O_ORDERDATE < 1994-01-01)

-- 21.5.9  The table ORDERS is well clustered on the predicate column ORDERDATE.

-- 21.5.10 Check the clustering quality of filter column, ORDERDATE, by running
--         the command:

SELECT SYSTEM$CLUSTERING_INFORMATION( 'orders' , '(o_orderdate)' );


-- 21.5.11 Review the result:
--         - The table is well clustered around the o_orderdate dimension.
--         - The clustering depth is low: 1.8436
--         - The histogram shows that the majority of micropartitions has a very
--         low depth.
--         Access the documentation for more details about clustering.
--         https://docs.snowflake.com/en/user-guide/tables-clustering-
--         micropartitions.html

-- 21.5.12 Compare the pruning from the ORDERS table above with the CUSTOMER
--         table.

-- 21.5.13 Review the same query profile as in Task 1.

-- 21.5.14 Click on the TableScan operator for the CUSTOMER table.

-- 21.5.15 Take note of the performance metrics:
--         - Partitions scanned (667).
--         - Total partitions (667).

-- 21.5.16 Take note of the following.
--         - Partition pruning did not skip any partitions when reading the
--         table CUSTOMER.
--         - The reason is that there is no WHERE predicate for the CUSTOMER
--         table and the JOIN condition is (ORDERS.O_CUSTKEY =
--         CUSTOMER.C_CUSTKEY) and the CUSTOMER table is not clustered by
--         c_custkey.

-- 21.5.17 Check the clustering quality of filter column, c_custkey, by running
--         the following command.

SELECT SYSTEM$CLUSTERING_INFORMATION( 'customer' , '(c_custkey)' );


-- 21.5.18 Examine the results.
--         - The table is poorly clustered around the c_custkey dimension:
--         - The clustering depth is high: 260.2594

-- 21.5.19 The histogram shows that all of the micro-partitions are grouped at
--         the lower end of the histogram.
--         Access the documentation for additional details regarding clustering:
--         https://docs.snowflake.com/en/user-guide/tables-clustering-
--         micropartitions.html

-- 21.6.0  Explore GROUP BY and ORDER BY Operation Performance

-- 21.6.1  Review performance benefits and implications of GROUP BY column usage
--         scenarios.
--         The following scenarios have more limited requirements on compute
--         resources, thereby contributing to faster query performance:
--         - Group by using columns with low cardinality (few distinct values)
--         - Order by using columns with low cardinality (few distinct values)

-- 21.6.2  GROUP BY with low cardinality columns.

-- 21.6.3  Run the following query (Query 1 of TPCH schema):

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
L_linestatus;


-- 21.6.4  View the query profile.

-- 21.6.5  Click on the Aggregate operator.

-- 21.6.6  Take note of the performance metrics for this operator.
--         Note the following items:
--         - The amount of data shuffled during the parallel aggregation
--         operation is limited.
--         - There are no bottlenecks shown such as spillage to local SSD.

-- 21.7.0  ORDER BY Performance Example

-- 21.7.1  Select to view the same query profile as in the example above.

-- 21.7.2  Click on the Sort operator.

-- 21.7.3  Take note of the performance metrics for this operator.
--         Note the following items:
--         - The amount of data shuffled during the global sort operation is
--         limited.
--         - There are no bottlenecks shown since the amount of data sent over
--         the network is infinitesimal.

-- 21.8.0  Explore the LIMIT Clause
--         Applying a LIMIT clause to a query may affect the amount of data that
--         is read and thus improves performance.
--         It does depend on the query and LIMIT can impact the amount of data
--         that is read from micro-partitions. For example, if you just do a
--         simple SELECT * FROM snowflake_sample_data.tpcds_sf10tcl.store_sales
--         limit 100; this query on a 28 M row table will be very fast because
--         it only needs to read 1 micro-partition to satisfy the query.

-- 21.8.1  Using LIMIT to limit the Result_Set.

-- 21.8.2  Execute the following query:

SELECT
s.ss_sold_date_sk,
r.sr_returned_date_sk,
s.ss_store_sk,
s.ss_item_sk,
s.ss_customer_sk,
s.ss_ticket_number,
s.ss_quantity,
s.ss_sales_price,
s.ss_customer_sk,
s.ss_store_sk,
s.ss_quantity,
s.ss_sales_price,
r.sr_return_amt
FROM snowflake_sample_data.tpcds_sf10tcl.store_sales  S
INNER JOIN snowflake_sample_data.tpcds_sf10tcl.store_returns  R on r.sr_item_sk=s.ss_item_sk
WHERE  s.ss_item_sk =4164
LIMIT 100;


-- 21.8.3  Access the query profile after the execution completes.
--         Note the following items:
--         - As shown in the query profile, the LIMIT operator is processed
--         later in the query plan and may have an impact on table access and
--         join operations.
--         - If you remove the LIMIT clause you will see more partitions scanned
--         from the STORE_SALES table.
--         - The LIMIT clause does help to significantly reduce the query result
--         output, which in turn helps to also improve the overall query
--         performance.

-- 21.9.0  Join Optimizations in Snowflake
--         A join is one of the most resource-intensive operations. Snowflake’s
--         optimizer provides built-in dynamic partition pruning to help reduce
--         data access during join processing.

-- 21.9.1  Take note of the following Snowflake best practices.
--         Use JOIN filter column(s) that match the table’s clustering column so
--         the query optimizer can push down partition pruning to the larger
--         table (which is usually the probe side of Hash Join).

-- 21.10.0 Dynamic Partition Pruning

-- 21.10.1 Run the following query.
--         This query might take just over 1 minute to execute.

USE SCHEMA snowflake_sample_data.tpcds_sf10tcl;

SELECT count(ss_customer_sk)
FROM store_sales JOIN date_dim d
ON ss_sold_date_sk = d_date_sk
WHERE d_year = 2000
GROUP BY ss_customer_sk;


-- 21.10.2 Access the query profile after the execution completes.

-- 21.10.3 Click on the TableScan operator for the store_sales table.

-- 21.10.4 Take note of the performance metrics for this operator.
--         Notice in the query profile the number of Partitions scanned is less
--         than the total partitions.

-- 21.10.5 Observe the following conditions:
--         - Partition pruning skips a large portion of partitions.
--         - This corresponds to the filter:
--         D.D_DATE_SK = STORE_SALES.SS_SOLD_DATE_SK

-- 21.10.6 Check the clustering quality of the predicate column ss_sold_date_sk
--         in the store_sales table using the following command.

SELECT SYSTEM$CLUSTERING_INFORMATION( 'snowflake_sample_data.tpcds_sf10tcl.store_sales', '(ss_sold_date_sk)');


-- 21.10.7 The table is well clustered around the ss_sold_date_sk dimension.
--         The clustering depth is very low: 1.0521
--         The histogram shows that most micro-partition groups are at the top
--         range (most at an overlap depth of 00001).

-- 21.11.0 Key Takeaways
--         - The query profile provides feedback on the steps the optimizer used
--         to execute a query
--         - Understanding how to read the query profile will help solve
--         performance issues in Snowflake.
