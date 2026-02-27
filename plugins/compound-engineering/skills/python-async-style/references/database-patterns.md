# Database Patterns (Raw SQL, No ORM)

## Connection Pool Setup

```python
# src/project_name/db.py
import asyncpg

async def create_pool(
    dsn: str,
    min_size: int = 5,
    max_size: int = 20,
) -> asyncpg.Pool:
    return await asyncpg.create_pool(
        dsn=dsn,
        min_size=min_size,
        max_size=max_size,
    )

async def close_pool(pool: asyncpg.Pool) -> None:
    await pool.close()
```

## Repository Pattern

```python
# src/project_name/repositories/user_repo.py
from dataclasses import dataclass
import asyncpg


@dataclass
class UserRow:
    id: int
    email: str
    name: str
    created_at: datetime


class UserRepository:
    def __init__(self, pool: asyncpg.Pool) -> None:
        self._pool = pool

    async def get_by_id(self, user_id: int) -> UserRow | None:
        async with self._pool.acquire() as conn:
            row = await conn.fetchrow(
                "SELECT id, email, name, created_at FROM users WHERE id = $1",
                user_id,
            )
            if row is None:
                return None
            return UserRow(**dict(row))

    async def create(self, email: str, name: str) -> UserRow:
        async with self._pool.acquire() as conn:
            row = await conn.fetchrow(
                """
                INSERT INTO users (email, name)
                VALUES ($1, $2)
                RETURNING id, email, name, created_at
                """,
                email,
                name,
            )
            return UserRow(**dict(row))

    async def list_all(self, limit: int = 100, offset: int = 0) -> list[UserRow]:
        async with self._pool.acquire() as conn:
            rows = await conn.fetch(
                "SELECT id, email, name, created_at FROM users ORDER BY id LIMIT $1 OFFSET $2",
                limit,
                offset,
            )
            return [UserRow(**dict(r)) for r in rows]
```

## Transaction Pattern

```python
async def transfer_funds(
    pool: asyncpg.Pool,
    from_id: int,
    to_id: int,
    amount: Decimal,
) -> None:
    async with pool.acquire() as conn:
        async with conn.transaction():
            await conn.execute(
                "UPDATE accounts SET balance = balance - $1 WHERE id = $2",
                amount,
                from_id,
            )
            await conn.execute(
                "UPDATE accounts SET balance = balance + $1 WHERE id = $2",
                amount,
                to_id,
            )
```

## Dynamic Query Builder

```python
from typing import Any


def build_search_query(
    filters: dict[str, Any],
    sort_by: str = "id",
    limit: int = 100,
) -> tuple[str, list[Any]]:
    ALLOWED_SORT = {"id", "name", "email", "created_at"}
    if sort_by not in ALLOWED_SORT:
        raise ValueError(f"Invalid sort column: {sort_by}")

    conditions: list[str] = []
    params: list[Any] = []
    idx = 1

    if "email" in filters:
        conditions.append(f"email = ${idx}")
        params.append(filters["email"])
        idx += 1

    if "name_like" in filters:
        conditions.append(f"name ILIKE ${idx}")
        params.append(f"%{filters['name_like']}%")
        idx += 1

    where = " AND ".join(conditions) if conditions else "TRUE"
    params.append(limit)

    query = f"""
        SELECT id, email, name, created_at
        FROM users
        WHERE {where}
        ORDER BY {sort_by}
        LIMIT ${idx}
    """
    return query, params
```

## Migration Scripts

```sql
-- migrations/001_create_users.sql
BEGIN;

CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users (email);

COMMIT;
```
