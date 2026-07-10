# Task 2: SQL for Data Extraction

Deliverables for the "SQL for Data Extraction" task — SQL fundamentals,
advanced SQL, and Python + SQL integration.

## Files

| File | Purpose |
|---|---|
| `generate_data.py` | Builds a synthetic-but-realistic dataset (120 customers, 20 products, 2,500 orders across a 12-month window) and loads it into `business.db` (SQLite). Run once to set up the DB. |
| `business.db` | The SQLite database (customers, products, orders tables + `vw_order_revenue` view). |
| `queries.sql` | All SQL: Day 7-8 fundamentals (SELECT/WHERE/ORDER BY/LIMIT/GROUP BY/HAVING/JOINs), Day 9-10 advanced SQL (subqueries, CTEs, window functions — ROW_NUMBER/RANK/LAG/LEAD, views), and the 10 business questions. Every statement has been verified to run against `business.db`. |
| `db_utils.py` | Reusable database utility module (`Database` class) wrapping SQLAlchemy + `pandas.read_sql()`, so any script/notebook can run SQL with one line: `db.query(sql)`. |
| `sql_python_integration.ipynb` | Jupyter notebook: connects Python to the database via SQLAlchemy, uses `pandas.read_sql()`, and answers all 10 business questions (with a monthly sales trend chart). Already executed end-to-end with real output. |

## How to reproduce

```bash
pip install sqlalchemy pandas matplotlib jupyter --break-system-packages
python3 generate_data.py                 # creates business.db
python3 db_utils.py                      # quick smoke test
jupyter notebook sql_python_integration.ipynb
```

## The 10 business questions answered

1. Top 5 products by sales
2. Monthly sales trend
3. Customer segmentation by spend (High / Medium / Low)
4. Revenue by region
5. Average order value (AOV) per customer
6. Repeat customers vs. one-time customers
7. Product category performance
8. Month-over-month sales growth %
9. Top 10 customers ranked by total spend (window function: RANK)
10. Running total (cumulative) of monthly sales (window function: SUM OVER)

## Suggested LinkedIn post

> Task 2 done! Mastered SQL queries for business insights. Integrated
> Python with SQLite for automated data extraction. #SQL #DataAnalytics
