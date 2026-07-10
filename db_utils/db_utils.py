"""
db_utils.py
-----------
Reusable database utility module (Day 11-13 deliverable:
"Create a reusable database utility script").

Wraps SQLAlchemy + pandas so the rest of the codebase (or a notebook)
can fetch query results as DataFrames with a single call, without
repeating connection boilerplate.

Usage:
    from db_utils import Database

    db = Database("sqlite:///business.db")
    df = db.query("SELECT * FROM customers LIMIT 5")
    db.run_script("queries.sql")   # run every statement in a .sql file
    db.close()
"""

from __future__ import annotations
import pandas as pd
from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine


class Database:
    """Small reusable wrapper around a SQLAlchemy engine."""

    def __init__(self, connection_string: str = "sqlite:///business.db"):
        self.connection_string = connection_string
        self.engine: Engine = create_engine(connection_string)

    def query(self, sql: str, params: dict | None = None) -> pd.DataFrame:
        """Run a SELECT query and return the results as a pandas DataFrame."""
        with self.engine.connect() as conn:
            return pd.read_sql(text(sql), conn, params=params)

    def execute(self, sql: str, params: dict | None = None) -> None:
        """Run a non-SELECT statement (INSERT/UPDATE/CREATE VIEW/etc.)."""
        with self.engine.begin() as conn:
            conn.execute(text(sql), params or {})

    def run_script(self, path: str) -> list[pd.DataFrame]:
        """
        Run every statement in a .sql file. SELECT statements return a
        DataFrame (collected in the result list); everything else is
        just executed.
        """
        with open(path, "r") as f:
            raw = f.read()

        # strip full-line comments, then split into individual statements
        lines = [ln for ln in raw.split("\n") if not ln.strip().startswith("--")]
        statements = [s.strip() for s in "\n".join(lines).split(";") if s.strip()]

        results = []
        with self.engine.begin() as conn:
            for stmt in statements:
                if stmt.strip().upper().startswith("SELECT"):
                    results.append(pd.read_sql(text(stmt), conn))
                else:
                    conn.execute(text(stmt))
        return results

    def table_names(self) -> list[str]:
        """List all tables/views in the database."""
        df = self.query(
            "SELECT name FROM sqlite_master WHERE type IN ('table','view') "
            "AND name NOT LIKE 'sqlite_%'"
        )
        return df["name"].tolist()

    def close(self) -> None:
        self.engine.dispose()


if __name__ == "__main__":
    # quick smoke test when run directly: python db_utils.py
    db = Database("sqlite:///business.db")
    print("Tables/views:", db.table_names())
    print(db.query("SELECT * FROM customers LIMIT 3"))
    db.close()
