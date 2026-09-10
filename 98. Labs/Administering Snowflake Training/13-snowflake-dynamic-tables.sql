
-- 13.0.0  Snowflake Dynamic Tables
--         By the end of this lab, you will be able to:
--         - Use Faker Python Package to generate test data
--         - Create dynamic tables with dependencies
--         - Use Snowsight Dynamic Tables Dashboard for observability

-- 13.1.0  Load Lab SQL file

-- 13.1.1  To load the SQL file, in the left navigation bar, select Projects,
--         then, under My Workspace, select the lab SQL file corresponding to
--         this lab exercise.
--         In the SQL files, lab instructions are shown as comments. Do not skip
--         these - they are instructions you need to follow. When the
--         instructions indicate you need to run some SQL, the required code is
--         in the SQL file.
--         The code below is in your .SQL file. Scroll down to this step number
--         to find it. Step numbers in the workbook correspond to the step
--         numbers in the SQL files.

-- 13.1.2  Set query tag for this session.

ALTER SESSION SET query_tag = '(USERLAB) lab - TOPIC: Dynamic Tables';


-- 13.1.3  Create your database.

USE ROLE SYSADMIN;
CREATE DATABASE IF NOT EXISTS USERLAB_adm_db 
COMMENT='Database for Admin course labs';


-- 13.1.4  Create your warehouse.

CREATE WAREHOUSE IF NOT EXISTS USERLAB_adm_wh
    WAREHOUSE_SIZE=XSmall
    INITIALLY_SUSPENDED=True
    AUTO_SUSPEND=300
    COMMENT='Warehouse for Admin course labs';


-- 13.2.0  Create Schemas

-- 13.2.1  Create the schema.

CREATE OR REPLACE SCHEMA  USERLAB_adm_db.dynamic_dt;


-- 13.3.0  Set Context

-- 13.3.1  Set your context.

USE ROLE  SYSADMIN;
USE SCHEMA USERLAB_adm_db.dynamic_dt;


-- 13.4.0  Generate Synthetic Data

-- 13.4.1  Create a function to generate the customer information using Python
--         faker package.
--         This is required so we can simulate adding more records easily later
--         In the real world you will load new records from your source systems

CREATE OR REPLACE FUNCTION USERLAB_adm_db.dynamic_dt.gen_cust_info(num_records number)
returns table (custid number(10), cname varchar(100))
language python
runtime_version=3.11
handler='CustTab'
packages = ('Faker')
as $$
from faker import Faker
import random

fake = Faker()
# Generate a list of customers  

class CustTab:
    # Generate multiple customer records
    def process(self, num_records):
        customer_id = 1000 # Starting customer ID                 
        for _ in range(num_records):
            custid = customer_id + 1
            cname = fake.name()
            customer_id += 1
            yield (custid,cname)

$$;


-- 13.4.2  Get details on the function GEN_CUST_INFO.

SHOW FUNCTIONS LIKE '%GEN_CUST%';

-- We can see the properties of this function using describe
DESCRIBE FUNCTION GEN_CUST_INFO(NUMBER) ;


-- 13.4.3  Create a second function to generate purchase information using
--         python faker package.
--         This is required so we can simulate adding more records easily later
--         In the real world you will load new records from your source systems

CREATE OR REPLACE FUNCTION USERLAB_adm_db.dynamic_dt.gen_cust_purchase(num_records number,ndays number)
returns table (custid number(10), purchase variant)
language python
runtime_version=3.11
handler='genCustPurchase'
packages = ('Faker')
as $$
from faker import Faker
import random
from datetime import datetime, timedelta
fake = Faker()

class genCustPurchase:
    # Generate multiple customer purchase records
    def process(self, num_records,ndays):       
        for _ in range(num_records):
            c_id = fake.random_int(min=1001, max=1999)
            
            #print(c_id)
            customer_purchase = {
                'custid': c_id,
                'purchased': []
            }
            # Get the current date
            current_date = datetime.now()
            
            # Calculate the maximum date (days from now)
            min_date = current_date - timedelta(days=ndays)
            
            # Generate a random date within the date range
            pdate = fake.date_between_dates(min_date,current_date)
            
            purchase = {
                'prodid': fake.random_int(min=101, max=199),
                'quantity': fake.random_int(min=1, max=5),
                'purchase_amount': round(random.uniform(10, 1000),2),
                'purchase_date': pdate
            }
            customer_purchase['purchased'].append(purchase)
            
            #customer_purchases.append(customer_purchase)
            yield (c_id,purchase)

$$;


-- 13.4.4  Get details on the function GEN_CUST_PURCHASE.

SHOW FUNCTIONS LIKE '%GEN_CUST_PURCH%';

-- We can see the properties of this function using the describe command
DESCRIBE FUNCTION GEN_CUST_PURCHASE(NUMBER,NUMBER) ;


-- 13.5.0  Create Raw Tables

-- 13.5.1  Create table raw_customers and call the function created earlier to
--         load the customer data.

CREATE OR REPLACE TABLE raw_customers 
AS 
SELECT * FROM table(gen_cust_info(1000)) 
ORDER BY 1;


-- 13.5.2  Create table salesdata and call the function created earlier to load
--         the salesdata.

CREATE OR  REPLACE TABLE salesdata 
AS  SELECT * FROM TABLE(gen_cust_purchase(10000,10));


-- 13.5.3  Check data in raw_customers.

SELECT * FROM raw_customers;


-- 13.5.4  Check data in salesdata.

SELECT * FROM salesdata;


-- 13.6.0  Create Dynamic Tables

-- 13.6.1  Create customers table using the raw_customers table. It will have a
--         refresh LAG of 1 minute. This table is a dynamic table.

CREATE OR REPLACE DYNAMIC TABLE CUSTOMERS
    LAG='1 MINUTES'
    WAREHOUSE=USERLAB_adm_wh
AS
SELECT 
    c.custid as customer_id,
    c.cname as customer_name
FROM
    raw_customers c
;


-- 13.6.2  Check customers table.

SELECT * FROM  customers;


-- 13.6.3  Check raw base table.

SELECT count(*) FROM raw_customers;


-- 13.6.4  Check Tables after a minute.

SELECT count(*) FROM customers;

SELECT count(*) FROM salesdata;


-- 13.6.5  Add new records to raw_customers.

INSERT INTO raw_customers 
SELECT * FROM table(gen_cust_info(100));


-- 13.6.6  Generate new sales data.

INSERT INTO salesdata 
SELECT * FROM table(gen_cust_purchase(10,01));


-- 13.6.7  Check dynamic tables after a minute.

SELECT count(*) FROM customers;
SELECT count(*) FROM salesdata;


-- 13.7.0  Create Presentation Tables

-- 13.7.1  Create the sales_report dynamic table.

CREATE OR REPLACE DYNAMIC TABLE sales_report
    LAG='1 MINUTES'
    WAREHOUSE=USERLAB_adm_wh
AS
SELECT 
    s.custid as customer_id,
    c.customer_name as customer_name,
    s.purchase:"prodid"::number(5) as product_id,
    s.purchase:"purchase_amount"::number(10) as saleprice,
    s.purchase:"quantity"::number(5) as quantity,
    s.purchase:"purchase_date"::date as salesdate
FROM
    customers c inner join salesdata s on c.customer_id = s.custid
;


-- 13.7.2  Create a dynamic table to rank the customers best on their spend.

CREATE OR REPLACE DYNAMIC TABLE customer_tier
    LAG='1 MINUTES'
    WAREHOUSE=USERLAB_adm_wh
AS
SELECT 
    customer_id,
    customer_name,
    CASE WHEN sum(saleprice*quantity)  > 35000 THEN 'TIER1' -- tier1 > 35000
         WHEN sum(saleprice*quantity)  BETWEEN 25000 and 34999 THEN 'TIER2'  -- Tier2 25000 - 34999
         ELSE 'TIER3' END AS TIER
FROM
    sales_report
GROUP BY customer_id,customer_name;
;


-- 13.7.3  Query customer_tier.

SELECT tier,COUNT(*) how_many
FROM customer_tier
GROUP BY tier
ORDER BY 1;


-- 13.7.4  Add new records to raw_customers.

INSERT INTO raw_customers 
SELECT * FROM table(gen_cust_info(500));


-- 13.7.5  Generate new sales data.

INSERT INTO salesdata 
SELECT * FROM table(gen_cust_purchase(200,01));


-- 13.7.6  Check the row counts again.

SELECT COUNT(*) FROM raw_customers;

SELECT COUNT(*) FROM salesdata;

SELECT COUNT(*) FROM sales_report;

SELECT tier,count(*) how_many
FROM customer_tier
GROUP BY tier
ORDER BY 1;


-- 13.8.0  Check Refresh History

-- 13.8.1  Query dynamic_table_refresh_history to see the refresh history.

SELECT * 
FROM 
    TABLE(INFORMATION_SCHEMA.DYNAMIC_TABLE_REFRESH_HISTORY())
WHERE 
    NAME IN ('CUSTOMERS','SALESREPORT','CUSTOMER_TIER')
    -- AND REFRESH_ACTION != 'NO_DATA'
ORDER BY 
    DATA_TIMESTAMP DESC, REFRESH_END_TIME DESC LIMIT 10;


-- 13.8.2  View the Dynamic table graphs using Snowsight UI.
--         Click on Transformation. Then click on Dynamic Tables to see the
--         Dynamic Tables refresh status. Drill down on customers dynamic table
--         to see the graph. Expand the graph and you can see that customer_tier
--         is built on the sales_report dynamic table, which feeds from
--         customers and salesdata. The customers dynamic table is fed by
--         raw_customers.
--         raw_customers table –> customers dynamic table + salesdata table –>
--         sales_report dynamic table –> customer_tier dynamic table

-- 13.8.3  Cleanup the objects.

USE ROLE  SYSADMIN;
DROP SCHEMA  USERLAB_adm_db.dynamic_dt;


-- 13.9.0  Key Takeaways
--         - Dynamic tables can be created in place of streams and tasks
--         - They undergo refresh based on the specified target lag
--         - Dynamic tables allows us to define pipeline outcomes using
--         declarative SQL
--         - Dynamic tables are fully observable through Snowsight
