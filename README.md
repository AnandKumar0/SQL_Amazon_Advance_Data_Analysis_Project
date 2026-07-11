# Amazon Advance Data Analysis using PostgreSQL
![amazonlogo](https://github.com/AnandKumar0/SQL_Amazon_Advance_Data_Analysis_Project/blob/main/amazonlogo.png)![databaselogo](https://github.com/AnandKumar0/SQL_Amazon_Advance_Data_Analysis_Project/blob/main/database.png)
## Project Overview

**Project Title:** Amazon Advance Data Analysis

**Database:** `sql_project_p5`

**Tools Used:** PostgreSQL, SQL, GitHub

This project demonstrates advanced SQL skills used by Data Analysts to design a multi-table e-commerce database, validate data integrity, explore the data, and solve 19 real-world business problems — including a stored procedure that automates sales entry and inventory updates.

The project covers the complete analytical workflow: database design, data validation (including business-rule checks), exploratory data analysis (EDA), business-driven SQL analysis, and a PL/pgSQL stored procedure for transactional automation.


## Objectives

**Database Design**
Design a normalized, multi-table e-commerce schema (category, customers, sellers, products, orders, order_items, payments, shipping, inventory) with full referential integrity via foreign keys.

**Data Validation**
Identify duplicates, NULL values, referential integrity violations, and — beyond basic checks — validate business rules (e.g., returned orders must be refunded, price must exceed COGS).

**Exploratory Data Analysis (EDA)**
Understand customer, seller, and product counts, total revenue, average order value, and total units sold.

**Business Analysis**
Answer 19 real-world business questions covering sales performance, customer behavior, seller performance, inventory, shipping, and profitability.

**Automation**
Build a stored procedure that records a new sale and automatically updates inventory stock.

## Project Structure

### 1. Database Setup

**Table Creation**

The project starts by dropping and recreating nine related tables with foreign key constraints defined inline.

```sql
DROP TABLE IF EXISTS category CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS sellers CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS shipping CASCADE;
DROP TABLE IF EXISTS inventory CASCADE;


-- >> CREATE ALL TABLES -->>

CREATE TABLE category (
	category_id INT PRIMARY KEY,
	category_name VARCHAR(100)
);

CREATE TABLE customers (
	customer_id INT PRIMARY KEY,
	first_name VARCHAR(20),
	last_name VARCHAR(20),
	state VARCHAR(20)
);


CREATE TABLE sellers (
	seller_id INT PRIMARY KEY,
	seller_name VARCHAR(25),
	origin VARCHAR(10)
);

CREATE TABLE products (
	product_id INT PRIMARY KEY,
	product_name VARCHAR(50),
	price NUMERIC(10, 2),
	cogs NUMERIC(10, 2),
	category_id INT,				-- FK
	
	CONSTRAINT fk_products_category FOREIGN KEY(category_id) REFERENCES category(category_id)
);

CREATE TABLE orders (
	order_id INT PRIMARY KEY,
	order_date DATE,
	customer_id INT,	-- FK
	seller_id INT,	-- FK
	order_status VARCHAR(15),

	CONSTRAINT fk_orders_customers FOREIGN KEY(customer_id) REFERENCES customers(customer_id),    
	CONSTRAINT fk_orders_sellers FOREIGN KEY(seller_id) REFERENCES sellers(seller_id)
);

CREATE TABLE order_items (
	order_item_id INT PRIMARY KEY,
	order_id INT,	-- FK
	product_id INT,	-- FK
	quantity INT,
	price_per_unit NUMERIC(10, 2),

	CONSTRAINT fk_order_items_orders FOREIGN KEY(order_id) REFERENCES orders(order_id),
	CONSTRAINT fk_order_items_products FOREIGN KEY(product_id) REFERENCES products(product_id)
);

CREATE TABLE payments (
	payment_id INT PRIMARY KEY,
	order_id INT,	--FK
	payment_date DATE,
	payment_status VARCHAR(20),

	CONSTRAINT fk_payment_orders FOREIGN KEY(order_id) REFERENCES orders(order_id)
);

CREATE TABLE shipping (
	shipping_id INT PRIMARY KEY,
	order_id INT,	--FK
	shipping_date DATE,
	return_date DATE,
	shipping_providers VARCHAR(15),
	delivery_status VARCHAR(15),

	CONSTRAINT fk_shipping_orders FOREIGN KEY(order_id) REFERENCES orders(order_id)
);

CREATE TABLE inventory (
	inventory_id INT PRIMARY KEY,
	product_id INT,	-- FK
	stock INT,
	warehouse_id INT,
	last_stock_date DATE,

	CONSTRAINT fk_inventory_products FOREIGN KEY(product_id) REFERENCES products(product_id)
);
```

**Verify the Data**

```sql
SELECT * FROM category;
SELECT * FROM customers;
SELECT * FROM sellers;
SELECT * FROM products;
SELECT * FROM orders;
SELECT * FROM order_items;
SELECT * FROM payments;
SELECT * FROM shipping;
SELECT * FROM inventory;
```

### 2. Data Validation

**Row Counts**

```sql
SELECT COUNT(*) FROM category;
SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM sellers;
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM order_items;
SELECT COUNT(*) FROM payments;
SELECT COUNT(*) FROM shipping;
SELECT COUNT(*) FROM inventory;
```

**Distinct Status Values**

```sql
SELECT DISTINCT order_status FROM orders;

SELECT DISTINCT payment_status FROM payments;

SELECT * FROM payments
WHERE payment_status = 'Refunded';

SELECT DISTINCT delivery_status FROM shipping;
```

**Duplicate Primary Key Checks**

```sql
SELECT customer_id, COUNT(*)
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

SELECT product_id, COUNT(*)
FROM products
GROUP BY product_id
HAVING COUNT(*) > 1;

SELECT order_id, COUNT(*)
FROM orders
GROUP BY 1
HAVING COUNT(*) > 1;

SELECT seller_id, COUNT(*)
FROM sellers
GROUP BY 1
HAVING COUNT(*) > 1;

SELECT category_id, COUNT(*)
FROM category
GROUP BY 1
HAVING COUNT(*) > 1;

SELECT order_item_id, COUNT(*)
FROM order_items
GROUP BY 1
HAVING COUNT(*) > 1;

SELECT payment_id, COUNT(*)
FROM payments
GROUP BY 1
HAVING COUNT(*) > 1

SELECT shipping_id, COUNT(*)
FROM shipping
GROUP BY 1
HAVING COUNT(*) > 1;

SELECT inventory_id, COUNT(*)
FROM inventory
GROUP BY 1
HAVING COUNT(*) > 1;
```

**Null Checks**

```sql
SELECT *
FROM customers
WHERE first_name IS NULL;

SELECT * FROM sellers 
WHERE seller_name IS NULL;

SELECT * FROM products 
WHERE product_name IS NULL;

SELECT * FROM orders 
WHERE order_date IS NULL
	OR order_status IS NULL;

SELECT * FROM order_items 
WHERE quantity IS NULL
	OR price_per_unit IS NULL;

SELECT * FROM payments 
WHERE payment_status IS NULL;

SELECT * FROM shipping 
WHERE shipping_providers IS NULL
	OR delivery_status IS NULL;

SELECT * FROM inventory 
WHERE stock IS NULL;
```

**Foreign Key / Referential Integrity Checks**

```sql
-- 1. Invalid customer_id in orders

SELECT *
FROM orders o
LEFT JOIN customers c
ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


-- 2. Invalid seller_id in orders

SELECT *
FROM orders o
LEFT JOIN sellers s
ON o.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

-- 3. Invalid product_id in order_items

SELECT *
FROM order_items oi
LEFT JOIN products p
ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;
```

**Business Rule Validation**

Beyond structural checks, business-logic consistency was also validated — e.g., a "Returned" order should always have a "Refunded" payment status, and price should always exceed cost of goods sold (COGS).

```sql
-- 4. Returned orders should be refunded

SELECT
	o.order_id,
	o.order_status,
	p.payment_status
FROM orders o
JOIN payments p
ON o.order_id = p.order_id
WHERE o.order_status = 'Returned'
	AND p.payment_status <> 'Refunded';

-- 5. Completed orders should have successful payment

SELECT
	o.order_id,
	o.order_status,
	p.payment_status
FROM orders o
JOIN payments p
ON o.order_id = p.order_id
WHERE o.order_status = 'Completed'
	AND p.payment_status <> 'Payment Successed';


-- 6. Inprogress orders should be pending

SELECT
	o.order_id,
	o.order_status,
	p.payment_status
FROM orders o
JOIN payments p
ON o.order_id = p.order_id
WHERE o.order_status = 'Inprogress'
	AND p.payment_status <> 'Payment Pending';

-- 7. Returned shipping should have a return date

SELECT *
FROM shipping
WHERE delivery_status = 'Returned'
	AND return_date IS NULL;
	
-- 8. Delivered shipping should not have a return date

SELECT *
FROM shipping
WHERE delivery_status = 'Delivered'
	AND return_date IS NOT NULL;

-- 9. Price should always be greater than COGS

SELECT *
FROM products
WHERE price <= cogs;
```

### 3. Exploratory Data Analysis (EDA)

```sql
SELECT COUNT(*) AS total_customers
FROM customers;


SELECT COUNT(*) AS total_sellers 
FROM sellers; 


SELECT COUNT(*) AS total_products
FROM products;

SELECT COUNT(*) AS total_orders
FROM orders;

SELECT SUM(quantity * price_per_unit) AS total_revenue
FROM order_items;

SELECT ROUND(AVG(quantity * price_per_unit), 2) AS aov
FROM order_items;

SELECT SUM(quantity) AS total_quantity 
FROM order_items;
```

### 4. Business Problems

**Q1. Top selling products — top 10 products by total sales value, including product_name, total quantity sold, and total sales value**

A `total_sales` column was first added and populated on `order_items` to simplify downstream revenue calculations.

```sql
-- Creating new column
ALTER TABLE order_items
ADD COLUMN total_sales FLOAT;

-- UPDATE DATA IN order_items
UPDATE order_items
SET total_sales = quantity * price_per_unit
```

```sql
SELECT
	oi.product_id,
	p.product_name,
	SUM(oi.total_sales) AS total_sales,
	COUNT(o.order_id) AS total_orders
FROM orders o
JOIN order_items oi
ON o.order_id = oi.order_id
JOIN products p
ON p.product_id = oi.product_id
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 10;
```

**Q2. Revenue by category — total revenue per product category, including percentage contribution to total revenue**

```sql
SELECT
	p.category_id,
	c.category_name,
	SUM(oi.total_sales) AS total_sales,
	(SUM(oi.total_sales)/(SELECT SUM(total_sales) FROM order_items) * 100) AS contribution
FROM order_items oi
JOIN products p
ON oi.product_id = p.product_id
LEFT JOIN category c
ON c.category_id = p.category_id
GROUP BY 1, 2
ORDER BY 3 DESC;
```

**Q3. Average Order Value (AOV) — for customers with more than 30 orders**

```sql
SELECT
	c.customer_id,
	c.first_name || ' ' || c.last_name AS customer_name,
	SUM(oi.total_sales) / COUNT(o.order_id) AS aov,
	COUNT(o.order_id) AS total_orders
FROM orders o
JOIN customers c
ON o.customer_id = c.customer_id
JOIN order_items oi
ON oi.order_id = o.order_id
GROUP BY
	c.customer_id,
	c.first_name,
	c.last_name
HAVING COUNT(o.order_id) >= 30;
```

**Q4. Monthly sales trend — sales trend over the past year, showing current month sales vs last month sales**

```sql
SELECT
	year,
	month,
	total_sales AS current_month_sale,
	LAG(total_sales, 1) OVER(ORDER BY year, month) AS last_month_sale
FROM
(
	SELECT
		EXTRACT(MONTH FROM o.order_date) AS month,
		EXTRACT(YEAR FROM o.order_date) AS year,
		ROUND(SUM(oi.total_sales::NUMERIC), 2) AS total_sales
	FROM orders o
	JOIN order_items oi
	ON o.order_id = oi.order_id
	WHERE order_date >= CURRENT_DATE - INTERVAL '1 YEAR'
	GROUP BY 1, 2
) t1;
```

**Q5. Customers with no purchases — customers who registered but never placed an order**

```sql
SELECT *
FROM customers
WHERE customer_id
	NOT IN 
		(SELECT DISTINCT customer_id FROM orders);
-- OR

SELECT *
FROM customers c
LEFT JOIN orders o
ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;
```

**Q6. Best-selling category by state — best-selling product category per state, with total sales for that category**

```sql
WITH ranking_table AS
(
	SELECT
		c.state,
		cat.category_name,
		SUM(oi.total_sales) AS total_sales,
		RANK() OVER(PARTITION BY c.state ORDER BY SUM(oi.total_sales) DESC) AS rnk
	FROM orders o
	JOIN customers c
	ON o.customer_id = c.customer_id
	JOIN order_items oi
	ON o.order_id = oi.order_id
	JOIN products p
	ON p.product_id = oi.product_id
	JOIN category cat
	ON cat.category_id = p.category_id 
	GROUP BY 1, 2
)

SELECT *
FROM ranking_table
WHERE rnk = 1;
```

**Q7. Customer Lifetime Value (CLTV) — total value of orders placed by each customer, ranked**

```sql
SELECT
	c.customer_id,
	c.first_name || ' ' || c.last_name AS customer_name,
	SUM(oi.total_sales) AS cltv,
	DENSE_RANK() OVER(ORDER BY SUM(oi.total_sales) DESC) AS rnk
FROM orders o
JOIN customers c
ON o.customer_id = c.customer_id
JOIN order_items oi
ON oi.order_id = o.order_id
GROUP BY
	c.customer_id,
	c.first_name,
	c.last_name
;
```

**Q8. Inventory stock alerts — products with stock below 10 units, including last restock date and warehouse info**

```sql
SELECT
	i.inventory_id,
	i.warehouse_id,
	p.product_name,
	i.stock AS current_stock_left,
	i.last_stock_date
FROM inventory i
JOIN products p
ON i.product_id = p.product_id
WHERE stock < 10;
```

**Q9. Shipping delays — orders where shipping date is more than 3 days after order date, including customer, order, and delivery provider details**

```sql
SELECT
	c.*,
	o.*,
	s.shipping_providers
FROM orders o
JOIN customers c
ON o.customer_id = c.customer_id
JOIN shipping s
ON o.order_id = s.order_id
WHERE s.shipping_date - o.order_date >= 3;
```

**Q10. Payment success rate — percentage of successful payments across all orders, broken down by payment status**

```sql
SELECT
	p.payment_status,
	COUNT(*) AS total_cnt,
	ROUND(COUNT(*)::NUMERIC/(SELECT COUNT(*) FROM payments)::NUMERIC * 100, 2) AS success_ratio
FROM orders o
JOIN payments p
ON o.order_id = p.order_id
GROUP BY 1
ORDER BY 2 DESC;
```

**Q11. Top performing sellers — top 5 sellers by total sales value, including their successful order percentage**

```sql
WITH top_sellers AS
(
	SELECT
		s.seller_id,
		s.seller_name,
		ROUND(SUM(oi.total_sales)::NUMERIC, 2) AS total_sales
	FROM orders o
	JOIN sellers s
	ON o.seller_id = s.seller_id
	JOIN order_items oi
	ON oi.order_id = o.order_id
	GROUP BY 1, 2
	ORDER BY 3 DESC
	LIMIT 5
),

seller_reports AS
(
	SELECT
		o.seller_id,
		ts.seller_name,
		o.order_status,
		COUNT(*) AS total_orders
	FROM orders o
	JOIN top_sellers ts
	ON ts.seller_id = o.seller_id
	WHERE o.order_status NOT IN ('Inprogress', 'Returned')
	GROUP BY 1, 2, 3
)
SELECT
	seller_id,
	seller_name,
	SUM(CASE WHEN order_status = 'Completed' THEN total_orders ELSE 0 END) AS completed_orders,
	SUM(CASE WHEN order_status = 'Cancelled' THEN total_orders ELSE 0 END) AS cancelled_orders,
	SUM(total_orders) AS total_orders,
	ROUND(SUM(CASE WHEN order_status = 'Completed' THEN total_orders ELSE 0 END)::NUMERIC / 
		SUM(total_orders)::NUMERIC * 100, 2) AS successful_order_ratio
FROM seller_reports
GROUP BY 1, 2
ORDER BY 5 DESC
```

**Q12. Product profit margin — profit margin per product (price vs COGS), ranked highest to lowest**

```sql
SELECT
	product_id,
	product_name,
	profit_margin,
	DENSE_RANK() OVER(ORDER BY profit_margin DESC) AS product_ranking
FROM
(
	SELECT
		p.product_id,
		p.product_name,
		SUM(total_saleS - (p.cogs * oi.quantity)) / SUM(total_sales) * 100 AS profit_margin
	FROM order_items oi
	JOIN products p
	ON oi.product_id = p.product_id
	GROUP BY 1, 2
) t1
```

**Q13. Most returned products — top 10 products by number of returns, with return rate as a percentage of total units sold**

```sql
SELECT
	p.product_id,
	p.product_name,
	COUNT(*) AS total_unit_sold,
	SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END) AS total_returns,
	ROUND(SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END)::NUMERIC / COUNT(*)::NUMERIC, 2) * 100 AS return_percentage
FROM order_items oi
JOIN products p
ON oi.product_id = p.product_id
JOIN orders o
ON o.order_id = oi.order_id
GROUP BY 1, 2
ORDER BY 5 DESC;
```

**Q14. Inactive sellers — sellers with no sales in the last 8 months, showing last sale date and last sale amount**

```sql
WITH seller_not_sale AS
(
	SELECT *
	FROM sellers
	WHERE seller_id NOT IN(SELECT seller_id FROM orders WHERE order_date >= CURRENT_DATE - INTERVAL '8 MONTHS')
)
SELECT
	o.seller_id,
	MAX(o.order_date) AS last_sale_date,
	MAX(oi.total_sales) AS last_sale_amount
FROM orders o
JOIN seller_not_sale sns
ON sns.seller_id = o.seller_id
JOIN order_items oi
ON o.order_id = oi.order_id
GROUP BY 1;
```

**Q15. Returning vs new customers — customers with more than 5 returns are categorized as "Returning", otherwise "New"**

```sql
SELECT
	full_name AS customers,
	total_orders
	total_return,
	CASE WHEN total_return > 10 THEN 'Returning_customers'  ELSE 'New' END AS customer_category
FROM
(
	SELECT
		c.first_name || ' ' || c.last_name AS full_name,
		COUNT(o.order_id) AS total_orders,
		SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END) AS total_return
	FROM orders o
	JOIN customers c
	ON c.customer_id = o.customer_id
	JOIN order_items oi
	ON oi.order_id = o.order_id
	GROUP BY 1
);
```

**Q16. Top 5 customers by orders in each state — including number of orders and total sales**

```sql
SELECT *
FROM
(
	SELECT
		c.state,
		c.first_name || ' ' || c.last_name AS customer_name,
		COUNT(o.order_id) AS total_orders,
		SUM(total_sales) AS total_sales,
		DENSE_RANK() OVER(PARTITION BY c.state ORDER BY COUNT(o.order_id) DESC) AS ranking
	FROM orders o
	JOIN order_items oi
	ON oi.order_id = o.order_id
	JOIN customers c
	ON c.customer_id = o.customer_id
	GROUP BY 1, 2
) t1
WHERE ranking <= 5;
```

**Q17. Revenue by shipping provider — total revenue, total orders handled, and average delivery time per provider**

```sql
SELECT
	s.shipping_providers,
	COUNT(o.order_id) AS order_handled,
	SUM(oi.total_sales) AS total_sale,
	ROUND(COALESCE(AVG(return_date - s.shipping_date), 0), 2) AS ave_delivery_days
FROM orders o
JOIN order_items oi
ON o.order_id = oi.order_id
JOIN shipping s
ON s.order_id = o.order_id
GROUP BY 1;
```

**Q18. Top products by revenue decline — top 10 products with the highest revenue decrease from 2024 to 2025**

Decrease ratio = current year revenue / last year revenue × 100.

```sql
WITH last_year_sale AS
(
	SELECT
		p.product_id,
		p.product_name,
		SUM(oi.total_sales) AS revenue
	FROM orders o
	JOIN order_items oi
	ON o.order_id = oi.order_id
	JOIN products p
	ON p.product_id = oi.product_id
	WHERE EXTRACT(YEAR FROM o.order_date) = '2024'
	GROUP BY 1, 2
),

current_year_sale AS
(	
	SELECT
		p.product_id,
		p.product_name,
		SUM(oi.total_sales) AS revenue
	FROM orders o
	JOIN order_items oi
	ON o.order_id = oi.order_id
	JOIN products p
	ON p.product_id = oi.product_id
	WHERE EXTRACT(YEAR FROM o.order_date) = '2025'
	GROUP BY 1, 2
)

SELECT
	cs.product_id,
	ls.revenue AS last_year_revenue,
	cs.revenue AS current_year_revenue,
	ls.revenue - cs.revenue AS revenue_diff,
	ROUND((cs.revenue - ls.revenue)::NUMERIC / ls.revenue::NUMERIC * 100, 2) AS revenue_dec_ratio
FROM last_year_sale ls
JOIN current_year_sale cs
ON ls.product_id = cs.product_id
WHERE ls.revenue > cs.revenue
ORDER BY 5 DESC
LIMIT 5;
```

**Q19. Automated sales & inventory update — a stored procedure that records a new sale and automatically deducts the sold quantity from inventory**

```sql
CREATE OR REPLACE PROCEDURE add_sales (p_order_id INT, p_customer_id INT, p_seller_id INT, p_order_item_id INT, p_product_id INT, p_quantity INT)

LANGUAGE plpgsql
AS
$$

DECLARE
	v_count INT;
	v_price FLOAT;
	v_product_name VARCHAR(50);

BEGIN
-- fetching product name and price based on product_id entered
	SELECT
		price,
		product_name
	
		INTO
		v_price,
		v_product_name
	FROM products
	WHERE product_id = p_product_id;
	
-- checking stock and product availability in inventory
	SELECT
		COUNT(*)
		INTO
		v_count
	FROM inventory
	WHERE product_id = p_product_id AND stock >= p_quantity;

	IF v_count > 0 THEN
		-- add into orders and order_items table
		-- update inventory
		INSERT INTO orders(order_id, order_date, customer_id, seller_id)
		VALUES
			(p_order_id, CURRENT_DATE, p_customer_id, p_seller_id);

		-- adding into order list
		INSERT INTO order_items(order_item_id, order_id, product_id, quantity, price_per_unit, total_sales)
		VALUES
			(p_order_item_id, p_order_id, p_product_id, p_quantity, v_price, v_price * p_quantity);

		-- updating inventory
		UPDATE inventory
		SET stock = (stock - p_quantity)
		WHERE product_id = p_product_id;

		RAISE NOTICE 'Thank you, : % product sale for has been added also inventory stock updates', v_product_name;

	ELSE
	RAISE NOTICE 'Thank you, for your info the product: % is not available', v_product_name;

	END IF;

END;
$$;
```

**Calling the procedure:**

```sql
CALL add_sales (25000, 2, 5, 25001, 1, 40);

SELECT * FROM inventory
WHERE product_id = 1

CALL add_sales (25002, 2, 5, 25003, 1, 40);
```

## Findings

- **Sales Concentration** — A relatively small set of top products and top sellers drive a disproportionate share of total revenue.
- **Customer Value** — Customer Lifetime Value (CLTV) is highly skewed, with a handful of customers contributing significantly more than the average.
- **Category Performance** — Revenue contribution varies widely by category, and the "best-selling category" differs by state, pointing to regional preference patterns.
- **Operational Risk** — Some products have very low inventory levels, and some sellers have gone inactive for 8+ months, both of which are actionable operational flags.
- **Shipping Performance** — Delivery time and revenue handled vary by shipping provider, useful for logistics partner evaluation.
- **Profitability** — Profit margin (price vs COGS) varies significantly across products, independent of raw sales volume — a high-revenue product isn't always a high-margin one.
- **Returns** — A subset of products and customers show disproportionately high return rates, which is useful for quality control and customer segmentation.
- **Automation** — A stored procedure (`add_sales`) demonstrates how sales entry and inventory deduction can be handled atomically in a single transactional call, reducing manual update errors.

## Reports Generated

- Data validation report (duplicates, NULLs, referential integrity, business-rule violations)
- Sales performance (top products, revenue by category, monthly trend)
- Customer insights (AOV, CLTV, returning vs new, top customers by state, customers with no purchases)
- Seller performance (top sellers, inactive sellers, success ratio)
- Inventory & shipping (stock alerts, shipping delays, revenue by provider)
- Profitability & returns (profit margin ranking, most returned products, YoY revenue decline)

## SQL Concepts Used

- ✔ CREATE TABLE / ALTER TABLE / DROP TABLE (with CASCADE)
- ✔ Primary & Foreign Key Constraints
- ✔ Data Validation (duplicates, NULLs, referential integrity, business-rule checks)
- ✔ JOIN (INNER, LEFT)
- ✔ Aggregate Functions
- ✔ GROUP BY / HAVING
- ✔ CASE WHEN
- ✔ CTEs (Common Table Expressions)
- ✔ Window Functions (`RANK`, `DENSE_RANK`, `LAG`)
- ✔ Subqueries
- ✔ Date Functions (`EXTRACT`, `INTERVAL`, `CURRENT_DATE`)
- ✔ Stored Procedures (PL/pgSQL — `CREATE OR REPLACE PROCEDURE`, `DECLARE`, `IF/ELSE`, `RAISE NOTICE`)
- ✔ Business Analysis

## Conclusion

This project helped strengthen my practical SQL and PostgreSQL skills on a complex, multi-table e-commerce schema — going beyond querying into data validation, business-rule enforcement, and process automation.

It demonstrates practical experience in:

- Relational database design across 9 interlinked tables
- Data quality and business-rule validation
- Exploratory Data Analysis
- Advanced window functions and CTEs
- Business problem solving across sales, customers, sellers, inventory, and shipping
- Writing and calling PL/pgSQL stored procedures for transactional automation
- SQL reporting for stakeholders

The insights generated from this project can support decision-making related to product strategy, seller performance management, inventory planning, shipping provider evaluation, and customer retention.

## How To Use

1. Download or clone this repository.
2. Open PostgreSQL or pgAdmin.
3. Create a database:
   ```sql
   CREATE DATABASE sql_project_p5;
   ```
4. Execute the SQL script in sequence:
   - Database Setup
   - Data Validation
   - Exploratory Data Analysis
   - Business Analysis (Q1–Q18)
   - Stored Procedure (Q19)
5. Review the query outputs and findings.

## Author

**Anand Kumar**

Aspiring Data Analyst

PostgreSQL | SQL | Data Analytics

This project is part of my Data Analytics portfolio showcasing SQL skills required for Data Analyst roles.

Feel free to connect, provide feedback, or collaborate on future projects.
