-->>>> Amazon_Advance_Data_Analysis_SQL_Project <<<<----

--
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


---====>>>> IMPORT DATA <<<<-----

SELECT * FROM category;
SELECT * FROM customers;
SELECT * FROM sellers;
SELECT * FROM products;
SELECT * FROM orders;
SELECT * FROM order_items;
SELECT * FROM payments;
SELECT * FROM shipping;
SELECT * FROM inventory;  


--- >> DATA VALIDATION <<--
-- ROW COUNT

SELECT COUNT(*) FROM category;
SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM sellers;
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM order_items;
SELECT COUNT(*) FROM payments;
SELECT COUNT(*) FROM shipping;
SELECT COUNT(*) FROM inventory;


SELECT DISTINCT order_status FROM orders;

SELECT DISTINCT payment_status FROM payments;

SELECT * FROM payments
WHERE payment_status = 'Refunded';

SELECT DISTINCT delivery_status FROM shipping;

-->> CHECK DUPLICATES <<--

-- 1. Duplicate Primary Keys

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

-- <<- CHECK NULLS -->>
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

-->>> FOREGIN KEY << -- 

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


--==>>> EDA (Exploratory Data Analysis) <<-- =

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


---==>>> BUSINESS PROBLEMS  <<<==---

-- Q.1 - Top Selling products
-- Query the top 10 products by total sales value
-- including product_name, total quantity sold and total sales values.

-- order_items , orders, products

-- Creating new column
ALTER TABLE order_items
ADD COLUMN total_sales FLOAT;

SELECT * FROM order_items;

-- UPDATE DATA IN order_items
UPDATE order_items
SET total_sales = quantity * price_per_unit

SELECT * FROM order_items;



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

-- Q.2 - Revenue by category
-- Calculate total revenue generated by each product category.
-- Including the percentage contribution of each category to totol revenue.

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

-- Q.3 - Average order value (AOV)
-- Compute the average order values for each customer,
-- Including only customers with  more than  30 oders

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



-- Q.4 Monthly sales Trend
-- Monthly total sales over the past year
-- Display the sales trend , grouping by month, return current_month sales, last month sale

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


-- Q.5 Customers wiht no Purchases
-- Find customers who have registered but never placed an order
-- List customer details and the time since their registration.

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


-- Q.6 - Best Selling categories by state
-- Identify the best-selling product category for each state.
-- Include the total sales for that category within each state.

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


-- Q..7 Customer Life tiem value(CLTV)
-- Calculate the total value of orders placed by each customer over their lifetime
-- Rank customer based on their CLTV

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

-- Q. 8 Inventory stock alerts
-- Products with stock levels below  a certain threshold (e.g. less than 10 units).
-- Include last restock date and warehouse information.

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


-- Q. 9 Shipping Delays
-- Inventory orders where the shipping date is later than 3 days after the order date.
-- Include customer, order detail, and delivery provider.


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


-- Q. 10 Payment success rate
-- Calculate teh percentage of successful payment across all orders.
-- Include breakdowns by payment staus (e.g/ failed, pending).

SELECT
	p.payment_status,
	COUNT(*) AS total_cnt,
	ROUND(COUNT(*)::NUMERIC/(SELECT COUNT(*) FROM payments)::NUMERIC * 100, 2) AS success_ratio
FROM orders o
JOIN payments p
ON o.order_id = p.order_id
GROUP BY 1
ORDER BY 2 DESC;


-- Q. 11 Top performing sellers
-- Find the top 5 sellers based on total sales values.
-- Include both successful and failed orders, and display their percentage of successful orders.

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


-- Q.12 - Product Profit Margin
-- Calculate the profit margin for each product (difference between price and cost of goods sold).
-- Rank products by their profit margin. showing highest to lowest.

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


-- Q.13 Most Returned Products
-- Query the top 10 products by the number of returns.
-- Display the return rate as a percentage of total units solf for each products.

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



-- Q.14 Inactive Sellers
-- Identiify sellers who haven't made any sales in the last 8 months. 
-- Show the last sale date and total sales from those sellers.

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


-- Q.15 Identify the customers into returning or new
-- if the customer has done more than 5 return categorize them as returning otherwise new 
-- list customer_id, game, total orders, total returns


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

-- Q.16 Top 5 customers by orders in each states
-- Identify the top5 customers wiht teh highest numbers of orders for each state.
-- Include the number of orders and total sales for each customers.

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


-- Q. 17 Revenue by shipping provider
-- calculate the total revenue handled by each shipping provider.
-- Include the total numbner of orders handled and the average delivery time for each provider.

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


-- Q.18 Top 10 Product with highest decreasing revenue ratio compar to last year(2024) and current year(2025)
-- Return product_id, product-name category_name, revenue and revenue decrease ratio at end round the 
-- Note - Decrease ratio = current year/last year * 100

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



-- Q.19 Create a function as soon as teh product is sold the same quantity should reduced from inventory table
-- after addding any sales records it should update the stock in teh inventory table based on the product and qty purchased



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


CALL add_sales (25000, 2, 5, 25001, 1, 40);


SELECT * FROM inventory
WHERE product_id = 1



CALL add_sales (25002, 2, 5, 25003, 1, 40);


--->>> END PROJECT <<<--- 



