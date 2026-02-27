# Fixture Patterns

## Root conftest.py

```python
# tests/conftest.py
import asyncio
from collections.abc import AsyncGenerator

import asyncpg
import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient

from project_name.config import Settings
from project_name.main import app


@pytest.fixture(scope="session")
def event_loop():
    """Create event loop for the entire test session."""
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


@pytest_asyncio.fixture(scope="session")
async def db_pool() -> AsyncGenerator[asyncpg.Pool, None]:
    """Create a database pool for the test session."""
    settings = Settings(database_url="postgresql://test:test@localhost/test_db")
    pool = await asyncpg.create_pool(dsn=settings.database_url, min_size=2, max_size=5)
    yield pool
    await pool.close()


@pytest_asyncio.fixture
async def db_conn(db_pool: asyncpg.Pool) -> AsyncGenerator[asyncpg.Connection, None]:
    """Get a connection with transaction rollback for test isolation."""
    async with db_pool.acquire() as conn:
        tx = conn.transaction()
        await tx.start()
        yield conn
        await tx.rollback()


@pytest_asyncio.fixture
async def client(db_pool: asyncpg.Pool) -> AsyncGenerator[AsyncClient, None]:
    """Create an async test client."""
    app.state.pool = db_pool
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test",
    ) as ac:
        yield ac
```

## Factory Fixtures

```python
@pytest_asyncio.fixture
async def create_user(db_conn: asyncpg.Connection):
    """Factory fixture to create test users."""
    async def _create(
        email: str = "test@example.com",
        name: str = "Test User",
    ) -> dict:
        row = await db_conn.fetchrow(
            "INSERT INTO users (email, name) VALUES ($1, $2) RETURNING *",
            email,
            name,
        )
        return dict(row)
    return _create


@pytest_asyncio.fixture
async def sample_user(create_user):
    """Create a single sample user."""
    return await create_user()
```

## Scope and Isolation

- `scope="session"`: DB pool, event loop (expensive to create)
- `scope="function"` (default): Individual connections, test data (rollback per test)
- Use transaction rollback for test isolation (not table truncation)
