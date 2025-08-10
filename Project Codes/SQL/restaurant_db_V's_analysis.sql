USE restaurant_db;

-- Quick scan on both tables
SELECT * FROM menu_items;
SELECT * FROM order_details;

-- 1. MENU_ITEMS
SELECT * FROM menu_items;

-- Count the total rows in menu_items
SELECT COUNT(*) 
FROM menu_items;

-- Simple way to find highest and lowest price
SELECT * FROM menu_items
ORDER BY price; -- By default = ASC (low to high)
SELECT * FROM menu_items
ORDER BY price DESC; -- DESC (high to low)

-- Selecting highest and lowest price in 1 query with their data 
SELECT *
FROM menu_items 
WHERE price IN
(
	(SELECT MAX(price) FROM menu_items),
    (SELECT MIN(price) FROM menu_items)
);

-- Showing all menu from Italy
SELECT * FROM menu_items WHERE category = "Italian";

-- Showing the most expensive and the cheapest menu in Italy
SELECT * FROM menu_items
WHERE category = 'Italian' AND price IN
(
	(SELECT MAX(price) FROM menu_items WHERE category = 'Italian'),
    (SELECT MIN(price) FROM menu_items WHERE category = 'Italian')
);

-- Showing all menu count and average price by their categories 
SELECT 
	category, 
	COUNT(*) AS menu_count, 
	ROUND(AVG(price), 2) AS average_price
FROM menu_items
GROUP BY category;



-- 2. ORDER_DETAILS
SELECT * FROM order_details;

-- View the order_details table. What is the date range of the table?
SELECT 
	MIN(order_date) AS First_Order_Date, 
	MAX(order_date) AS Last_Order_Date
FROM order_details;

-- How many orders were made within this date range? How many items were ordered within this date range?
SELECT COUNT(DISTINCT order_id) AS total_orders
FROM order_details;

SELECT COUNT(DISTINCT order_details_id) AS total_items_ordered
FROM order_details;

-- Which orders had the most number of items?
SELECT 
	order_id, 
	COUNT(order_id) AS order_count, 
	COUNT(order_details_id)
FROM order_details
GROUP BY order_id
ORDER BY 3 DESC;

-- How many orders had more than 12 items?
SELECT * FROM order_details;

SELECT 
	order_id, 
	COUNT(order_id) AS order_count
FROM order_details
GROUP BY order_id
HAVING order_count >= 12
ORDER BY 2;

SELECT COUNT(*) AS order_count
FROM (
    SELECT order_id
    FROM order_details
    GROUP BY order_id
    HAVING COUNT(order_id) >= 12
) AS total;



-- 3. Combining 2 tables
SELECT * 
FROM order_details od
INNER JOIN menu_items mi
ON od.item_id = mi.menu_item_id;

-- Most favorite menu
SELECT 
	mi.item_name, 
	mi.category, 
	mi.price,
	COUNT(*) AS order_count
FROM order_details od
INNER JOIN menu_items mi
ON od.item_id = mi.menu_item_id
GROUP BY mi.item_name, mi.category, mi.price
ORDER BY 4 DESC;

-- Least favorite menu
SELECT 
	mi.item_name, 
	mi.category, 
	mi.price,
	COUNT(*) AS order_count
FROM order_details od
INNER JOIN menu_items mi
ON od.item_id = mi.menu_item_id
GROUP BY mi.item_name, mi.category, mi.price
ORDER BY 4;

-- Top 5 orders by spent money
SELECT od.order_id, SUM(mi.price) AS total_spent
FROM order_details od
INNER JOIN menu_items mi
ON od.item_id = mi.menu_item_id
GROUP BY od.order_id
ORDER BY 2 DESC
LIMIT 5;

-- View the details of the highest spend order. Which specific items were purchased?
SELECT 
    od.order_id,
    mi.item_name,
    mi.category,
    mi.price
FROM order_details od
INNER JOIN menu_items mi
    ON od.item_id = mi.menu_item_id
WHERE od.order_id = (
    SELECT order_id
    FROM order_details od2
    INNER JOIN menu_items mi2
        ON od2.item_id = mi2.menu_item_id
    GROUP BY od2.order_id
    ORDER BY SUM(mi2.price) DESC
    LIMIT 1
);

-- View the details of the top 5 highest spend orders
SELECT 
    od.order_id,
    mi.item_name,
    mi.category,
    mi.price
FROM order_details od
INNER JOIN menu_items mi
    ON od.item_id = mi.menu_item_id
INNER JOIN (
    SELECT 
        od2.order_id,
        SUM(mi2.price) AS total_spent
    FROM order_details od2
    INNER JOIN menu_items mi2
        ON od2.item_id = mi2.menu_item_id
    GROUP BY od2.order_id
    ORDER BY total_spent DESC
    LIMIT 5
) top_orders
    ON od.order_id = top_orders.order_id
ORDER BY top_orders.total_spent DESC, od.order_id;

SELECT 
    od.order_id,
    mi.item_name,
    mi.category,
    mi.price
FROM order_details od
INNER JOIN menu_items mi
    ON od.item_id = mi.menu_item_id
WHERE od.order_id IN (
    SELECT order_id
    FROM (
        SELECT od.order_id
        FROM order_details od
        INNER JOIN menu_items mi
            ON od.item_id = mi.menu_item_id
        GROUP BY od.order_id
        ORDER BY SUM(mi.price) DESC
        LIMIT 5
    ) AS top_5
);