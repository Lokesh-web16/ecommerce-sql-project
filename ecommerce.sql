-- =====================================================================
--  E-Commerce Database Management System
--  Stack: MySQL
--  Description: Creates the `ecommerce` database, defines customers,
--  orders, and products tables, inserts sample data, and runs the
--  required queries. Also includes normalization with an order_items
--  table at the end.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. Create the database and select it
-- ---------------------------------------------------------------------
DROP DATABASE IF EXISTS ecommerce;
CREATE DATABASE ecommerce;
USE ecommerce;


-- ---------------------------------------------------------------------
-- 2. Create the `customers` table
--    Stores customer personal details. `id` is the primary key.
-- ---------------------------------------------------------------------
CREATE TABLE customers (
    id      INT AUTO_INCREMENT PRIMARY KEY,
    name    VARCHAR(100) NOT NULL,
    email   VARCHAR(150) NOT NULL UNIQUE,
    address VARCHAR(255) NOT NULL
);


-- ---------------------------------------------------------------------
-- 3. Create the `products` table
--    Stores product catalogue details.
-- ---------------------------------------------------------------------
CREATE TABLE products (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(100)   NOT NULL,
    price       DECIMAL(10, 2) NOT NULL,
    description TEXT
);


-- ---------------------------------------------------------------------
-- 4. Create the `orders` table
--    Each order is linked to one customer via a foreign key.
-- ---------------------------------------------------------------------
CREATE TABLE orders (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    customer_id  INT            NOT NULL,
    order_date   DATE           NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id) REFERENCES customers(id)
        ON DELETE CASCADE
);


-- ---------------------------------------------------------------------
-- 5. Insert sample data into `customers`
-- ---------------------------------------------------------------------
INSERT INTO customers (name, email, address) VALUES
    ('Aarav Sharma',   'aarav@example.com',   '12 MG Road, Bengaluru'),
    ('Priya Singh',    'priya@example.com',   '45 Park Street, Kolkata'),
    ('Rahul Verma',    'rahul@example.com',   '8 Connaught Place, Delhi'),
    ('Neha Patel',     'neha@example.com',    '23 Marine Drive, Mumbai'),
    ('Vikram Reddy',   'vikram@example.com',  '77 Jubilee Hills, Hyderabad');


-- ---------------------------------------------------------------------
-- 6. Insert sample data into `products`
-- ---------------------------------------------------------------------
INSERT INTO products (name, price, description) VALUES
    ('Product A', 120.00, 'Wireless Bluetooth headphones with noise cancellation'),
    ('Product B',  75.50, 'Ergonomic office chair with lumbar support'),
    ('Product C',  40.00, 'Stainless steel water bottle, 1L capacity'),
    ('Product D', 250.00, '4K Ultra HD smart LED television, 43 inch'),
    ('Product E',  15.00, 'Cotton T-shirt, unisex, multiple colours'),
    ('Product F', 180.00, 'Mechanical gaming keyboard with RGB lighting');


-- ---------------------------------------------------------------------
-- 7. Insert sample data into `orders`
--    Uses CURDATE() and INTERVAL so "last 30 days" queries work
--    regardless of when the script is run.
-- ---------------------------------------------------------------------
INSERT INTO orders (customer_id, order_date, total_amount) VALUES
    (1, CURDATE() - INTERVAL  2 DAY, 195.50),
    (2, CURDATE() - INTERVAL 10 DAY, 250.00),
    (3, CURDATE() - INTERVAL 25 DAY, 120.00),
    (1, CURDATE() - INTERVAL 45 DAY,  75.50),  -- outside 30-day window
    (4, CURDATE() - INTERVAL  5 DAY, 300.00),
    (5, CURDATE() - INTERVAL  1 DAY,  55.00),
    (2, CURDATE() - INTERVAL 60 DAY, 180.00);  -- outside 30-day window


-- =====================================================================
--                           REQUIRED QUERIES
-- =====================================================================


-- Q1. Retrieve all customers who have placed an order in the last 30 days.
--     DISTINCT avoids duplicate rows when a customer has multiple orders.
SELECT DISTINCT c.*
FROM customers AS c
INNER JOIN orders AS o ON o.customer_id = c.id
WHERE o.order_date >= CURDATE() - INTERVAL 30 DAY;


-- Q2. Get the total amount of all orders placed by each customer.
--     LEFT JOIN ensures customers with zero orders still appear (total = 0).
SELECT
    c.id,
    c.name,
    COALESCE(SUM(o.total_amount), 0) AS total_spent
FROM customers AS c
LEFT JOIN orders AS o ON o.customer_id = c.id
GROUP BY c.id, c.name
ORDER BY total_spent DESC;


-- Q3. Update the price of Product C to 45.00.
UPDATE products
SET price = 45.00
WHERE name = 'Product C';


-- Q4. Add a new column `discount` to the products table.
--     DECIMAL(5,2) allows values like 10.50 (percentage) with a default of 0.
ALTER TABLE products
ADD COLUMN discount DECIMAL(5, 2) NOT NULL DEFAULT 0.00;


-- Q5. Retrieve the top 3 products with the highest price.
SELECT *
FROM products
ORDER BY price DESC
LIMIT 3;


-- =====================================================================
--  NORMALIZATION
--  The original `orders` table stores only a total amount, which means
--  we cannot tell which products belong to which order. To fix this we
--  introduce an `order_items` table (one row per product per order).
--  The orders table now references order_items indirectly: every order
--  has many order_items, and each order_item points at a product.
-- =====================================================================


-- 8a. Create the `order_items` table
CREATE TABLE order_items (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    order_id   INT            NOT NULL,
    product_id INT            NOT NULL,
    quantity   INT            NOT NULL DEFAULT 1,
    unit_price DECIMAL(10, 2) NOT NULL,
    CONSTRAINT fk_items_order
        FOREIGN KEY (order_id)   REFERENCES orders(id)   ON DELETE CASCADE,
    CONSTRAINT fk_items_product
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT
);


-- 8b. Populate `order_items` with sample rows so the remaining queries
--     (like "customers who ordered Product A") return meaningful results.
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
    (1, 1, 1, 120.00),  -- Aarav  -> Product A
    (1, 3, 1,  45.00),  -- Aarav  -> Product C (updated price)
    (1, 5, 2,  15.00),  -- Aarav  -> Product E x2
    (2, 4, 1, 250.00),  -- Priya  -> Product D
    (3, 1, 1, 120.00),  -- Rahul  -> Product A
    (4, 2, 1,  75.50),  -- Aarav  -> Product B
    (5, 6, 1, 180.00),  -- Neha   -> Product F
    (5, 1, 1, 120.00),  -- Neha   -> Product A
    (6, 5, 1,  15.00),  -- Vikram -> Product E
    (6, 3, 1,  40.00),  -- Vikram -> Product C
    (7, 6, 1, 180.00);  -- Priya  -> Product F


-- 8c. Recalculate each order's `total_amount` from its line items so the
--     orders table stays consistent with the normalized data.
UPDATE orders AS o
JOIN (
    SELECT order_id, SUM(quantity * unit_price) AS computed_total
    FROM order_items
    GROUP BY order_id
) AS t ON t.order_id = o.id
SET o.total_amount = t.computed_total;


-- =====================================================================
--  Remaining queries (run AFTER normalization so Product A lookups work)
-- =====================================================================


-- Q6. Get the names of customers who have ordered Product A.
--     DISTINCT because a customer could order Product A in multiple orders.
SELECT DISTINCT c.name
FROM customers  AS c
JOIN orders     AS o  ON o.customer_id = c.id
JOIN order_items AS oi ON oi.order_id  = o.id
JOIN products   AS p  ON p.id          = oi.product_id
WHERE p.name = 'Product A';


-- Q7. Join orders and customers to retrieve the customer's name and
--     order date for every order.
SELECT
    o.id         AS order_id,
    c.name       AS customer_name,
    o.order_date,
    o.total_amount
FROM orders   AS o
JOIN customers AS c ON c.id = o.customer_id
ORDER BY o.order_date DESC;


-- Q8. Retrieve orders with a total amount greater than 150.00.
SELECT *
FROM orders
WHERE total_amount > 150.00
ORDER BY total_amount DESC;


-- Q9. Retrieve the average total of all orders.
SELECT ROUND(AVG(total_amount), 2) AS average_order_total
FROM orders;


-- =====================================================================
--  End of script
-- =====================================================================
