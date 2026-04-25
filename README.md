# E-Commerce SQL Project 🛢️

A simple e-commerce database built in **MySQL** that manages customers, products, and orders. The project covers schema design, sample data, common queries and database normalization with an `order_items` table.

## Tech Stack

- **Database:** MySQL 8.x
- **Tool (optional):** MySQL Workbench

## Project Structure

```
ecommerce-sql-project/
├── ecommerce.sql   # Full script: schema + data + queries
└── README.md       # You are here
```

## Database Schema

**customers** — stores customer details
| Column  | Type         | Notes                |
|---------|--------------|----------------------|
| id      | INT          | Primary key, auto-increment |
| name    | VARCHAR(100) | Customer name        |
| email   | VARCHAR(150) | Unique email address |
| address | VARCHAR(255) | Customer address     |

**products** — stores product catalogue
| Column      | Type          | Notes                    |
|-------------|---------------|--------------------------|
| id          | INT           | Primary key, auto-increment |
| name        | VARCHAR(100)  | Product name             |
| price       | DECIMAL(10,2) | Product price            |
| description | TEXT          | Product description      |
| discount    | DECIMAL(5,2)  | Added via ALTER TABLE    |

**orders** — stores each order placed by a customer
| Column       | Type          | Notes                          |
|--------------|---------------|--------------------------------|
| id           | INT           | Primary key, auto-increment    |
| customer_id  | INT           | Foreign key → customers(id)    |
| order_date   | DATE          | Date the order was placed      |
| total_amount | DECIMAL(10,2) | Total amount of the order      |

**order_items** — added during normalization, one row per product per order
| Column     | Type          | Notes                        |
|------------|---------------|------------------------------|
| id         | INT           | Primary key, auto-increment  |
| order_id   | INT           | Foreign key → orders(id)     |
| product_id | INT           | Foreign key → products(id)   |
| quantity   | INT           | Number of units ordered      |
| unit_price | DECIMAL(10,2) | Price per unit at order time |

## Queries Included

1. Customers who placed an order in the last 30 days
2. Total amount of orders per customer
3. Update price of Product C to 45.00
4. Add a `discount` column to products
5. Top 3 most expensive products
6. Customers who ordered Product A
7. Join orders with customers for name and order date
8. Orders with total amount greater than 150.00
9. Average total of all orders
10. Normalization using an `order_items` table

Every query has an inline comment explaining what it does.

## How to Run

### Option 1: MySQL Command Line
```bash
mysql -u your_username -p < ecommerce.sql
```

### Option 2: MySQL Workbench
1. Open MySQL Workbench and connect to your local server
2. Go to **File → Open SQL Script** and select `ecommerce.sql`
3. Click the lightning bolt icon to execute the whole script

## Notes

- The script uses `DROP DATABASE IF EXISTS ecommerce` at the top, so it is safe to re-run.
- Sample order dates use `CURDATE() - INTERVAL n DAY` so the "last 30 days" query always returns realistic results.
