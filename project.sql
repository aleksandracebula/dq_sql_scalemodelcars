The purpose of this project is to showcase my SQL skills. It was developed as part of a data science guided course on the Dataquest platform.

Data available here: (link).

I have analyzed data from a sales records database for scale model cars. My analysis have focused on the following key areas:

1. Inventory Management: identifying which products should have been ordered more or less frequently based on sales performance.
2. Marketing Strategy: tailoring communication and marketing strategies to specific customer behaviors and segments.
3. Customer Acquisition Cost (CAC): determining the optimal budget for acquiring new customers by analyzing current lifetime value.

***********************************************
STEP 1: GETTING FAMILIAR WITH THE DATABASE
The goal was to understand the table structures and sizes.
***********************************************

The database contains eight tables:
1. Customers: customer data.
2. Employees: all employee information.
3. Offices: sales office information.
4. Orders: customers' sales orders.
5. OrderDetails: sales order line for each sales order.
6. Payments: customers' payment records.
7. Products: a list of scale model cars.
8. ProductLines: a list of product line categories.

A table below shows tables':
- name,
- number of attributes,
- number of rows.

-- database info --

SELECT 'Customers' AS table_name, 
       13 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Customers
  
UNION ALL

SELECT 'Products' AS table_name, 
       9 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Products

UNION ALL

SELECT 'ProductLines' AS table_name, 
       4 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM ProductLines

UNION ALL

SELECT 'Orders' AS table_name, 
       7 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Orders

UNION ALL

SELECT 'OrderDetails' AS table_name, 
       5 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM OrderDetails

UNION ALL

SELECT 'Payments' AS table_name, 
       4 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Payments

UNION ALL

SELECT 'Employees' AS table_name, 
       8 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Employees

UNION ALL

SELECT 'Offices' AS table_name, 
       9 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Offices;

*******************************************
STEP 2: EXPLORING PRODUCTS
Which products should be ordered more of or less of?
The goal was to create 3 tables:
- low stock - indicates products in demand out of stock or almost out of stock; represents the quantity of the sum of each product ordered divided by the quantity of product in stock;
- product performance - represents the sum of sales per product;
- priority products for restocking - are those with high product performance that are on the brink of being out of stock.
*******************************************
-- low stock --
SELECT SUM(od.quantityOrdered) AS quantityOrdered, 
       p.quantityInStock, 
       p.productCode, 
       ROUND(SUM(od.quantityOrdered) * 1.0/p.quantityInStock, 2) AS lowStock
  FROM products AS p
  JOIN orderdetails AS od
    ON p.productCode = od.productCode
 GROUP BY p.productCode
 ORDER BY lowStock DESC
 LIMIT 10;

The table shows that with a total of 1015 of S24_2000 product ordered and only 15 units currently in stock, it has a low-stock ratio of 67.67. This indicates that the product is highly popular but severely understocked, leading to significant missed sales opportunities.

-- product performance --
SELECT productCode, 
        ROUND(SUM(quantityOrdered * priceEach), 2) AS productPerformance
  FROM orderdetails
 GROUP BY productCode
 ORDER BY productPerformance DESC
 LIMIT 10;

The table shows 10 products with best product performance.

-- prority products for restocking --
WITH
lowStockTable AS (
    SELECT SUM(od.quantityOrdered) AS quantityOrdered, 
           p.quantityInStock, 
           p.productCode, 
           ROUND(SUM(od.quantityOrdered) * 1.0/p.quantityInStock, 2) AS lowStock
      FROM products AS p
      JOIN orderdetails AS od
        ON p.productCode = od.productCode
     GROUP BY p.productCode
     ORDER BY lowStock DESC
     LIMIT 10
),

productToRestock AS (
    SELECT productCode, 
           ROUND(SUM(quantityOrdered * priceEach), 2) AS productPerformance
      FROM orderdetails AS od
     WHERE productCode IN (SELECT productCode
                             FROM lowStockTable)
     GROUP BY productCode
     ORDER BY productPerformance DESC
     LIMIT 10
)

SELECT productCode, productName
  FROM products As p
 WHERE productCode IN (SELECT productCode 
                         FROM productToRestock);

***********************************
STEP 3: EXPLORING CUSTOMER INFORMATION
How should marketing and communication strategies be matched to customer behaviors?
The idea was to include 5 top customers in customer reward program (CRP). In order to do that, I created 3 tables:
- a table which shows profit each customer generates,
- a table with top 5 customers by revenue (to include them in CRP),
- a table with top 5 least-engaged customers by revenue.
***********************************

-- revenue --
SELECT o.customerNumber, 
       ROUND(SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)), 2) AS revenue
  FROM products AS p
  JOIN orderdetails AS od
    ON p.productCode = od.productCode
  JOIN orders AS o
    ON od.orderNumber = o.orderNumber
 GROUP BY customerNumber;

-- top 5 customers by revenue --
WITH 

revenueTable AS (
SELECT o.customerNumber, 
      ROUND(SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)), 2) AS revenue
  FROM products AS p
  JOIN orderdetails AS od
    ON p.productCode = od.productCode
  JOIN orders AS o
    ON od.orderNumber = o.orderNumber
 GROUP BY customerNumber
    )
    
SELECT c.contactLastName, 
       c.contactFirstName, 
       c.city, 
       c.country, 
       r.revenue
  FROM customers AS c
  JOIN revenueTable AS r
    ON c.customerNumber = r.customerNumber
 ORDER BY revenue DESC
 LIMIT 5;

-- top 5 least-engaged customers by revenue --
WITH 

revenueTable AS (
SELECT o.customerNumber, 
      ROUND(SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)), 2) AS revenue
  FROM products AS p
  JOIN orderdetails AS od
    ON p.productCode = od.productCode
  JOIN orders AS o
    ON od.orderNumber = o.orderNumber
 GROUP BY customerNumber
    )
    
SELECT c.contactLastName, 
       c.contactFirstName, 
       c.city, 
       c.country, 
       r.revenue
  FROM customers AS c
  JOIN revenueTable AS r
    ON c.customerNumber = r.customerNumber
 ORDER BY revenue
 LIMIT 5;

*******************
STEP 4 SETTING AN OPTIMAL BUDGET FOR ACQUIRING NEW CUSTOMERS
How much can be spent on acquiring new customers?
The idea was to find:
- a number of new customers arriving each month,
- finding Customer Lifetime Value (LTV) which tells how much profit an average customer generates during their lifetime with the store
*******************

-- new customers arriving each month --
WITH 

payment_with_year_month_table AS (
SELECT *, 
       CAST(SUBSTR(paymentDate, 1,4) AS INTEGER)*100 + CAST(SUBSTR(paymentDate, 6,7) AS INTEGER) AS year_month -- kolumna paymentDate ma format rrrr-mm-dd; SUBSTR obcina znaki od 1 do 4 (czyli sam rok), CAST zmienia z date na integer, mnożymy * 100 i sumujemy z "miesiącem"
  FROM payments p
),

customers_by_month_table AS (
SELECT p1.year_month, COUNT(*) AS number_of_customers, SUM(p1.amount) AS total -- sumujemy miesięcznie przychody i zliczamy liczbę klientów
  FROM payment_with_year_month_table p1
 GROUP BY p1.year_month
),

new_customers_by_month_table AS (
SELECT p1.year_month, 
       COUNT(DISTINCT customerNumber) AS number_of_new_customers,
       SUM(p1.amount) AS new_customer_total,
       (SELECT number_of_customers
          FROM customers_by_month_table c
        WHERE c.year_month = p1.year_month) AS number_of_customers,
       (SELECT total
          FROM customers_by_month_table c
         WHERE c.year_month = p1.year_month) AS total
  FROM payment_with_year_month_table p1
 WHERE p1.customerNumber NOT IN (SELECT customerNumber
                                   FROM payment_with_year_month_table p2
                                  WHERE p2.year_month < p1.year_month)
 GROUP BY p1.year_month
)

SELECT year_month, 
       ROUND(number_of_new_customers*100/number_of_customers,1) AS number_of_new_customers_props,
       ROUND(new_customer_total*100/total,1) AS new_customers_total_props
  FROM new_customers_by_month_table;

--The number of clients has been decreasing since 2003. In 2004, values were the lowest. The year 2005 is not presented in the table above althought it is present in the database. It means that the store has not had any new customers since September of 2004. It means it makes sense to spend money acquiring new customers.

The year 2005, which is present in the database as well, isn't present in the table above, this means that the store has not had any new customers since September of 2004. This means it makes sense to spend money acquiring new customers.

-- Customer LTV --
WITH 

revenueTable AS (
SELECT o.customerNumber, 
      ROUND(SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)), 2) AS revenue
  FROM products AS p
  JOIN orderdetails AS od
    ON p.productCode = od.productCode
  JOIN orders AS o
    ON od.orderNumber = o.orderNumber
 GROUP BY customerNumber
    )

SELECT AVG(rt.revenue) AS ltv
  FROM revenueTable AS rt;
  
--LTV tells us how much profit an average customer generates during their lifetime with our store. It can be used to predict the future profit. If we get ten new customers next month, we'll earn 390,395 dollars, and we can decide based on this prediction how much we can spend on acquiring new customers.