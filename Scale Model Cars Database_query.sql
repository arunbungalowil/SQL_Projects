-- Customers and Products Analysis Using SQL
-- DATABASE => Scale Model Cars Database
-- It contains eight tables:
-- Customers: customer data
-- Employees: all employee information
-- Offices: sales office information
-- Orders: customers' sales orders
-- OrderDetails: sales order line for each sales order
-- Payments: customers' payment records
-- Products: a list of scale model cars
-- ProductLines: a list of product line categorie

-- Write a query to print all the columns of customer table 
-- set limit to 10
SELECT *
FROM customers
LIMIT 10;

-- Write a query to print number of customers from each country
-- oorder the resulting table in ascending order 
SELECT 
	COUNT(*) AS numbers,
	country
FROM customers
GROUP BY country
ORDER BY numbers ;

--Find Unique Product line and their numbers
SELECT 
	productLine,
	SUM(quantityInStock) AS total
FROM products
GROUP BY productLine
LIMIT 10
-- Write a query to display the following table:
-- Select each table name as a string.
-- Select the number of attributes as an integer (count the number of attributes per table).
-- Select the number of rows using the COUNT(*) function.
-- Use the compound-operator UNION ALL to bind these rows together.

SELECT 'customers' AS table_name, COUNT(*) AS number_of_attributes, (SELECT COUNT(*) FROM customers) AS number_of_rows FROM PRAGMA_table_info('customers')
UNION ALL
SELECT 'products' AS tbale_name, COUNT(*) AS number_of_attributes, (SELECT COUNT(*) FROM products) AS number_of_rows FROM PRAGMA_table_info('products')
UNION ALL
SELECT 'productLines' AS table_name, COUNT(*) AS number_of_attributes,(SELECT COUNT(*) FROM productLines) AS number_of_rows FROM PRAGMA_table_info('productLines')
UNION ALL
SELECT 'orders' AS table_name, COUNT(*) AS number_of_attributes, (SELECT COUNT(*) FROM orders) AS number_of_rows FROM PRAGMA_table_info('orders')
UNION ALL
SELECT 'orderdetails' AS table_name, COUNT(*) AS number_of_attributes,(SELECT COUNT(*) FROM orderdetails) AS number_of_rows FROM PRAGMA_table_info('orderdetails')
UNION ALL
SELECT 'payments' AS table_name, COUNT(*) AS number_of_attributes,(SELECT COUNT(*) FROM payments) AS number_of_rows FROM PRAGMA_table_info('payments')
UNION ALL
SELECT 'employees' AS table_name, COUNT(*) AS number_of_attributes,(SELECT COUNT(*) FROM employees) AS number_of_rows FROM PRAGMA_table_info('employees')
UNION ALL
SELECT 'offices' AS table_name, COUNT(*) AS number_of_attributes,(SELECT COUNT(*) FROM offices) AS number_of_rows FROM PRAGMA_table_info('offices');


-- Write a query to compute the low stock for each product.
SELECT 
	p.productCode,
	p.productName,
	SUM(o.quantityOrdered) / p.quantityInStock AS low_stock
FROM products AS p
INNER JOIN orderdetails AS o
ON p.productCode = o.productCode
GROUP BY p.productCode
ORDER BY low_stock DESC
LIMIT 10;
-- Write a query to compute the product performance for each product.
SELECT 
	p.productCode,
	p.productName,
	ROUND(SUM(o.quantityOrdered * o.priceEach),2) AS product_performance
FROM orderdetails AS o
INNER JOIN products AS p
ON p.productCode = o.productCode
GROUP BY p.productCode
order by product_performance DESC
LIMIT 10;

-- Display priority products for restocking
-- Combine the previous queries using a Common Table Expression (CTE) to display priority products for restocking using the IN operator.

WITH 
table_1 AS(
SELECT 
	p.productCode
FROM (
	SELECT 
		p.productCode,
		p.productName,
		SUM(o.quantityOrdered) / p.quantityInStock AS low_stock
	FROM products AS p
	JOIN orderdetails AS o
	ON p.productCode = o.productCode
	GROUP BY p.productCode
	ORDER BY low_stock DESC) AS P),
table_2 AS(
SELECT 
	p.productCode
	FROM(
		SELECT 
			p.productCode,
			p.productLine,
			p.productname,
			ROUND(SUM(o.quantityOrdered * o.priceEach),2) AS product_performance
		FROM orderdetails AS o
		JOIN products AS p
		ON p.productCode = o.productCode
		GROUP BY p.productCode
		ORDER BY product_performance DESC
		LIMIT 10) AS p)
		
SELECT p.productCode,p.productName,p.productLine
FROM products AS p
WHERE p.productCode in table_1 AND p.productCode IN table_2;

--  how much profit each customer generates.
SELECT 
	o.customerNumber,
	ROUND(SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)),2) AS profit
FROM orders AS o
JOIN orderdetails AS od
ON o.orderNumber = od.orderNumber
JOIN products AS p
ON p.productCode = od.productCode
GROUP BY o.customerNumber
ORDER BY profit DESC;

-- Find the top five VIP customers

WITH
	vip_customers AS(
	SELECT 
	o.customerNumber,
	ROUND(SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)),2) AS profit
FROM orders AS o
JOIN orderdetails AS od
ON o.orderNumber = od.orderNumber
JOIN products AS p
ON p.productCode = od.productCode
GROUP BY o.customerNumber
ORDER BY profit DESC
	)
SELECT 
	c.contactLastName || " " || c.contactFirstName,
	c.city,
	c.country,
	profit
FROM customers AS c
JOIN vip_customers 
ON vip_customers.customerNumber = c.customerNumber
LIMIT 10;

-- Find the top five least-engaged customers
WITH
	non_vip_customers AS(
	SELECT 
	o.customerNumber,
	ROUND(SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)),2) AS profit
FROM orders AS o
JOIN orderdetails AS od
ON o.orderNumber = od.orderNumber
JOIN products AS p
ON p.productCode = od.productCode
GROUP BY o.customerNumber
ORDER BY profit 
	)
SELECT 
	c.contactLastName || " " || c.contactFirstName,
	c.city,
	c.country,
	profit
FROM customers AS c
JOIN non_vip_customers 
ON non_vip_customers.customerNumber = c.customerNumber
LIMIT 10;
	
-- Compute the average of customer profits

WITH  performance AS
(SELECT o.customerNumber, round(SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)),2) AS profit
FROM orders o
JOIN orderdetails od ON od.orderNumber = o.orderNumber
JOIN products p ON p.productCode = od.productCode
GROUP BY o.customerNumber
ORDER BY profit)
SELECT  round(avg(profit),2) as LTV
FROM performance;
-- 
-- LTV tells us how much profit an average customer generates during their lifetime with our store. 
-- We can use it to predict our future profit. So, if we get ten new customers next month, 
-- we'll earn 390,395 dollars, and we can decide based on this prediction how much we can spend on acquiring new customers.

