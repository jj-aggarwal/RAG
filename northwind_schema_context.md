# Northwind Database – Schema Context (PostgreSQL)

Sample trading-company database: a fictional specialty-food importer/exporter. Customers place orders, handled by employees, containing products supplied by suppliers and shipped via shippers.

## SQL dialect: PostgreSQL

Generate PostgreSQL only. Rules:

- All table and column names are **lowercase snake_case**. Use them exactly as written below. Do NOT use PascalCase names (`Customers`, `CustomerID`) and do NOT use brackets (`[Order Details]`).
- Do not double-quote identifiers; none of them need quoting.
- Limit rows with `LIMIT n` (never `TOP n`).
- Concatenate strings with `||` or `CONCAT(a, ' ', b)` (never `+`).
- Dates are `date` type. Use `EXTRACT(YEAR FROM order_date)`, `DATE_TRUNC('month', order_date)`, or `TO_CHAR(order_date, 'YYYY-MM')`.
- Use `TRIM()` when comparing `char`-padded text columns (see Notes).
- If the tables live in a non-default schema, prefix every table with it (e.g. `northwind.customers`) or run `SET search_path TO <schema>;` first.

## Entity relationship overview

```
categories 1──∞ products ∞──1 suppliers
products   1──∞ order_details ∞──1 orders
orders     ∞──1 customers
orders     ∞──1 employees
orders     ∞──1 shippers (via ship_via)
employees  1──∞ employees (reports_to, self-reference)
employees  ∞──∞ territories (via employee_territories)
territories ∞──1 region
customers  ∞──∞ customer_demographics (via customer_customer_demo)
```

## Tables

### categories
Product categories (8 rows).

| Column        | Type        | Notes    |
| ------------- | ----------- | -------- |
| category_id   | smallint    | **PK**   |
| category_name | varchar(15) | not null |
| description   | text        |          |
| picture       | bytea       | binary   |

### customers
| Column        | Type        | Notes                                |
| ------------- | ----------- | ------------------------------------ |
| customer_id   | bpchar(5)   | **PK**, 5-letter code (e.g. `ALFKI`) |
| company_name  | varchar(40) | not null                             |
| contact_name  | varchar(30) |                                      |
| contact_title | varchar(30) |                                      |
| address       | varchar(60) |                                      |
| city          | varchar(15) |                                      |
| region        | varchar(15) | often NULL                           |
| postal_code   | varchar(10) |                                      |
| country       | varchar(15) |                                      |
| phone         | varchar(24) |                                      |
| fax           | varchar(24) |                                      |

### customer_demographics
| Column           | Type   | Notes  |
| ---------------- | ------ | ------ |
| customer_type_id | bpchar | **PK** |
| customer_desc    | text   |        |

### customer_customer_demo
Junction table (typically empty in sample data).

| Column           | Type   | Notes                                               |
| ---------------- | ------ | --------------------------------------------------- |
| customer_id      | bpchar | **PK**, FK → customers.customer_id                  |
| customer_type_id | bpchar | **PK**, FK → customer_demographics.customer_type_id |

### employees
| Column            | Type         | Notes                                |
| ----------------- | ------------ | ------------------------------------ |
| employee_id       | smallint     | **PK**                               |
| last_name         | varchar(20)  | not null                             |
| first_name        | varchar(10)  | not null                             |
| title             | varchar(30)  | e.g. Sales Representative            |
| title_of_courtesy | varchar(25)  | Mr., Ms., Dr.                        |
| birth_date        | date         |                                      |
| hire_date         | date         |                                      |
| address           | varchar(60)  |                                      |
| city              | varchar(15)  |                                      |
| region            | varchar(15)  |                                      |
| postal_code       | varchar(10)  |                                      |
| country           | varchar(15)  |                                      |
| home_phone        | varchar(24)  |                                      |
| extension         | varchar(4)   |                                      |
| photo             | bytea        | binary                               |
| notes             | text         |                                      |
| reports_to        | smallint     | FK → employees.employee_id (manager) |
| photo_path        | varchar(255) |                                      |

### region
| Column             | Type     | Notes                                 |
| ------------------ | -------- | ------------------------------------- |
| region_id          | smallint | **PK**                                |
| region_description | bpchar   | not null, padded with trailing spaces |

### territories
| Column                | Type        | Notes                                 |
| --------------------- | ----------- | ------------------------------------- |
| territory_id          | varchar(20) | **PK**                                |
| territory_description | bpchar      | not null, padded with trailing spaces |
| region_id             | smallint    | FK → region.region_id                 |

### employee_territories
| Column       | Type        | Notes                                 |
| ------------ | ----------- | ------------------------------------- |
| employee_id  | smallint    | **PK**, FK → employees.employee_id    |
| territory_id | varchar(20) | **PK**, FK → territories.territory_id |

### suppliers
| Column        | Type        | Notes    |
| ------------- | ----------- | -------- |
| supplier_id   | smallint    | **PK**   |
| company_name  | varchar(40) | not null |
| contact_name  | varchar(30) |          |
| contact_title | varchar(30) |          |
| address       | varchar(60) |          |
| city          | varchar(15) |          |
| region        | varchar(15) |          |
| postal_code   | varchar(10) |          |
| country       | varchar(15) |          |
| phone         | varchar(24) |          |
| fax           | varchar(24) |          |
| homepage      | text        |          |

### products
| Column            | Type        | Notes                                  |
| ----------------- | ----------- | -------------------------------------- |
| product_id        | smallint    | **PK**                                 |
| product_name      | varchar(40) | not null                               |
| supplier_id       | smallint    | FK → suppliers.supplier_id             |
| category_id       | smallint    | FK → categories.category_id            |
| quantity_per_unit | varchar(20) | free text, e.g. "24 - 12 oz bottles"   |
| unit_price        | real        |                                        |
| units_in_stock    | smallint    |                                        |
| units_on_order    | smallint    |                                        |
| reorder_level     | smallint    |                                        |
| discontinued      | integer     | not null, 1 = discontinued, 0 = active |

### shippers
| Column       | Type        | Notes    |
| ------------ | ----------- | -------- |
| shipper_id   | smallint    | **PK**   |
| company_name | varchar(40) | not null |
| phone        | varchar(24) |          |

### orders
| Column           | Type        | Notes                      |
| ---------------- | ----------- | -------------------------- |
| order_id         | smallint    | **PK**                     |
| customer_id      | bpchar(5)   | FK → customers.customer_id |
| employee_id      | smallint    | FK → employees.employee_id |
| order_date       | date        |                            |
| required_date    | date        |                            |
| shipped_date     | date        | NULL = not yet shipped     |
| ship_via         | smallint    | FK → shippers.shipper_id   |
| freight          | real        |                            |
| ship_name        | varchar(40) |                            |
| ship_address     | varchar(60) |                            |
| ship_city        | varchar(15) |                            |
| ship_region      | varchar(15) |                            |
| ship_postal_code | varchar(10) |                            |
| ship_country     | varchar(15) |                            |

### order_details
Line items. Note the table name is `order_details` (underscore, no space).

| Column     | Type     | Notes                                                       |
| ---------- | -------- | ----------------------------------------------------------- |
| order_id   | smallint | **PK**, FK → orders.order_id                                |
| product_id | smallint | **PK**, FK → products.product_id                            |
| unit_price | real     | price at time of sale (may differ from products.unit_price) |
| quantity   | smallint |                                                             |
| discount   | real     | fraction 0–1 (e.g. 0.05 = 5%)                               |

### us_states
Extra lookup table in the PostgreSQL port (not used by any foreign key).

| Column       | Type         | Notes  |
| ------------ | ------------ | ------ |
| state_id     | smallint     | **PK** |
| state_name   | varchar(100) |        |
| state_abbr   | varchar(2)   |        |
| state_region | varchar(50)  |        |

## Foreign keys (summary)

| Child                  | Column           | Parent                | Column           |
| ---------------------- | ---------------- | --------------------- | ---------------- |
| products               | supplier_id      | suppliers             | supplier_id      |
| products               | category_id      | categories            | category_id      |
| orders                 | customer_id      | customers             | customer_id      |
| orders                 | employee_id      | employees             | employee_id      |
| orders                 | ship_via         | shippers              | shipper_id       |
| order_details          | order_id         | orders                | order_id         |
| order_details          | product_id       | products              | product_id       |
| employees              | reports_to       | employees             | employee_id      |
| employee_territories   | employee_id      | employees             | employee_id      |
| employee_territories   | territory_id     | territories           | territory_id     |
| territories            | region_id        | region                | region_id        |
| customer_customer_demo | customer_id      | customers             | customer_id      |
| customer_customer_demo | customer_type_id | customer_demographics | customer_type_id |

## Known values (complete lists)

- **categories.category_name** (8): Beverages, Condiments, Confections, Dairy Products, Grains/Cereals, Meat/Poultry, Produce, Seafood
- **shippers.company_name** (3): Speedy Express, United Package, Federal Shipping
- **region.region_description** (4): Eastern, Western, Northern, Southern

Other columns (customer countries, product names, employee names, cities, and so on) have many values; this file does not list them all, so absence from this file does not mean a value doesn't exist.

## Business rules and query conventions

- **Line revenue** = `unit_price * quantity * (1 - discount)` using `order_details.unit_price`, not `products.unit_price`.
- **Order total** = sum of line revenue; `freight` is separate and not included in revenue.
- **Unshipped orders**: `shipped_date IS NULL`.
- **Late orders**: `shipped_date > required_date`.
- **Active products**: `discontinued = 0`.
- **Manager hierarchy**: self-join `employees` on `reports_to`; NULL means top of hierarchy.
- **Customer-to-employee region**: no direct link; go via `orders` or via `employee_territories → territories → region`.
- `region.region_description` and `territories.territory_description` are char-padded: use `TRIM()` when comparing or displaying.
- `customers.region`, `suppliers.region`, `employees.region`, and `orders.ship_region` are frequently NULL.
- Order dates span roughly July 1996 to May 1998; avoid "relative to today" logic.
- Approximate row counts: categories 8, customers 91, employees 9, orders 830, order_details 2,155, products 77, shippers 3, suppliers 29, region 4, territories 53.

## Example queries (PostgreSQL)

```sql
-- Top 10 customers by revenue
SELECT c.company_name,
       SUM(od.unit_price * od.quantity * (1 - od.discount)) AS revenue
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
JOIN order_details od ON od.order_id = o.order_id
GROUP BY c.company_name
ORDER BY revenue DESC
LIMIT 10;

-- Revenue by category
SELECT cat.category_name,
       SUM(od.unit_price * od.quantity * (1 - od.discount)) AS revenue
FROM categories cat
JOIN products p ON p.category_id = cat.category_id
JOIN order_details od ON od.product_id = p.product_id
GROUP BY cat.category_name
ORDER BY revenue DESC;

-- Employee and manager
SELECT e.first_name || ' ' || e.last_name AS employee,
       m.first_name || ' ' || m.last_name AS manager
FROM employees e
LEFT JOIN employees m ON m.employee_id = e.reports_to;

-- Monthly revenue in 1997
SELECT DATE_TRUNC('month', o.order_date) AS month,
       SUM(od.unit_price * od.quantity * (1 - od.discount)) AS revenue
FROM orders o
JOIN order_details od ON od.order_id = o.order_id
WHERE EXTRACT(YEAR FROM o.order_date) = 1997
GROUP BY 1
ORDER BY 1;
```