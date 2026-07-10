"""
generate_data.py
----------------
Creates a synthetic "cleaned dataset" (customers, products, orders) and
loads it into a SQLite database (business.db), matching Day 7-8 step:
"Import cleaned dataset into database".
"""

import sqlite3
import random
from datetime import datetime, timedelta

random.seed(42)

DB_PATH = "business.db"

# ---------------------------------------------------------------------------
# 1. Build synthetic reference data
# ---------------------------------------------------------------------------
regions = ["North", "South", "East", "West"]
categories = ["Electronics", "Home & Kitchen", "Apparel", "Sports", "Books"]

first_names = ["Aarav", "Priya", "Rohan", "Ananya", "Vikram", "Sneha", "Karan",
               "Ishita", "Aditya", "Meera", "Sahil", "Divya", "Nikhil", "Pooja",
               "Arjun", "Kavya", "Rahul", "Neha", "Manav", "Riya"]
last_names = ["Sharma", "Verma", "Patel", "Gupta", "Iyer", "Nair", "Reddy",
              "Kapoor", "Malhotra", "Joshi"]

product_catalog = [
    ("Wireless Mouse", "Electronics", 599),
    ("Bluetooth Speaker", "Electronics", 1499),
    ("USB-C Charger", "Electronics", 899),
    ("Noise Cancelling Headphones", "Electronics", 3499),
    ("Smartwatch", "Electronics", 4999),
    ("Non-stick Pan Set", "Home & Kitchen", 1299),
    ("Electric Kettle", "Home & Kitchen", 999),
    ("Blender", "Home & Kitchen", 1999),
    ("Bedsheet Set", "Home & Kitchen", 799),
    ("LED Desk Lamp", "Home & Kitchen", 649),
    ("Men's T-Shirt", "Apparel", 499),
    ("Women's Kurti", "Apparel", 899),
    ("Denim Jacket", "Apparel", 1799),
    ("Running Shoes", "Sports", 2499),
    ("Yoga Mat", "Sports", 699),
    ("Dumbbell Set (10kg)", "Sports", 2199),
    ("Cricket Bat", "Sports", 1599),
    ("Data Analytics Handbook", "Books", 449),
    ("Python for Beginners", "Books", 399),
    ("SQL in 30 Days", "Books", 349),
]

# ---------------------------------------------------------------------------
# 2. Generate customers
# ---------------------------------------------------------------------------
customers = []
start_signup = datetime(2024, 1, 1)
for cid in range(1, 121):  # 120 customers
    name = f"{random.choice(first_names)} {random.choice(last_names)}"
    region = random.choice(regions)
    signup_date = start_signup + timedelta(days=random.randint(0, 500))
    customers.append((cid, name, region, signup_date.strftime("%Y-%m-%d")))

# ---------------------------------------------------------------------------
# 3. Generate products
# ---------------------------------------------------------------------------
products = []
for pid, (pname, cat, price) in enumerate(product_catalog, start=1):
    products.append((pid, pname, cat, price))

# ---------------------------------------------------------------------------
# 4. Generate orders across a 12-month window (2025-07-01 to 2026-06-30)
# ---------------------------------------------------------------------------
orders = []
order_start = datetime(2025, 7, 1)
order_end = datetime(2026, 6, 30)
total_days = (order_end - order_start).days

order_id = 1
for _ in range(2500):  # 2500 order line items
    cust_id = random.randint(1, 120)
    prod_id = random.randint(1, len(product_catalog))
    quantity = random.choices([1, 2, 3, 4], weights=[60, 25, 10, 5])[0]
    day_offset = random.randint(0, total_days)
    order_date = order_start + timedelta(days=day_offset)
    orders.append((order_id, cust_id, prod_id, quantity, order_date.strftime("%Y-%m-%d")))
    order_id += 1

# ---------------------------------------------------------------------------
# 5. Load into SQLite
# ---------------------------------------------------------------------------
conn = sqlite3.connect(DB_PATH)
cur = conn.cursor()

cur.executescript("""
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;

CREATE TABLE customers (
    customer_id INTEGER PRIMARY KEY,
    customer_name TEXT NOT NULL,
    region TEXT NOT NULL,
    signup_date TEXT NOT NULL
);

CREATE TABLE products (
    product_id INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    category TEXT NOT NULL,
    price REAL NOT NULL
);

CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    order_date TEXT NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);
""")

cur.executemany("INSERT INTO customers VALUES (?, ?, ?, ?)", customers)
cur.executemany("INSERT INTO products VALUES (?, ?, ?, ?)", products)
cur.executemany("INSERT INTO orders VALUES (?, ?, ?, ?, ?)", orders)

conn.commit()

print(f"Loaded {len(customers)} customers, {len(products)} products, {len(orders)} orders into {DB_PATH}")
conn.close()
