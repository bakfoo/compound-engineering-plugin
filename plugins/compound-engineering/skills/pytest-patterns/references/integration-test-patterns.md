# Integration Test Patterns

## Full Workflow Test

```python
# tests/test_integration/test_user_flow.py
import pytest


@pytest.mark.asyncio
@pytest.mark.integration
async def test_user_lifecycle(client):
    """Test complete user CRUD lifecycle."""
    # Create
    create_resp = await client.post(
        "/api/v1/users",
        json={"email": "lifecycle@example.com", "name": "Lifecycle User"},
    )
    assert create_resp.status_code == 201
    user_id = create_resp.json()["id"]

    # Read
    get_resp = await client.get(f"/api/v1/users/{user_id}")
    assert get_resp.status_code == 200
    assert get_resp.json()["email"] == "lifecycle@example.com"

    # Update
    update_resp = await client.put(
        f"/api/v1/users/{user_id}",
        json={"name": "Updated Name"},
    )
    assert update_resp.status_code == 200
    assert update_resp.json()["name"] == "Updated Name"

    # Delete
    delete_resp = await client.delete(f"/api/v1/users/{user_id}")
    assert delete_resp.status_code == 204

    # Verify deleted
    verify_resp = await client.get(f"/api/v1/users/{user_id}")
    assert verify_resp.status_code == 404
```

## Database Integration Test

```python
@pytest.mark.asyncio
@pytest.mark.integration
async def test_concurrent_user_creation(db_pool):
    """Test that concurrent inserts with unique constraint work correctly."""
    import asyncio

    async def create_user(email: str) -> int | None:
        try:
            async with db_pool.acquire() as conn:
                row = await conn.fetchrow(
                    "INSERT INTO users (email, name) VALUES ($1, $2) RETURNING id",
                    email,
                    "Test",
                )
                return row["id"]
        except asyncpg.UniqueViolationError:
            return None

    # Two concurrent inserts with same email
    results = await asyncio.gather(
        create_user("concurrent@example.com"),
        create_user("concurrent@example.com"),
    )

    # Exactly one should succeed
    successes = [r for r in results if r is not None]
    assert len(successes) == 1
```

## Transaction Rollback Test

```python
@pytest.mark.asyncio
@pytest.mark.integration
async def test_transaction_rollback_on_error(db_pool):
    """Verify that failed transactions leave no partial state."""
    async with db_pool.acquire() as conn:
        initial_count = await conn.fetchval("SELECT COUNT(*) FROM orders")

    try:
        async with db_pool.acquire() as conn:
            async with conn.transaction():
                await conn.execute("INSERT INTO orders (user_id, total) VALUES ($1, $2)", 1, 100)
                raise ValueError("Simulated failure")
    except ValueError:
        pass

    async with db_pool.acquire() as conn:
        final_count = await conn.fetchval("SELECT COUNT(*) FROM orders")

    assert final_count == initial_count
```

## Running Integration Tests

```bash
# Run all tests
uv run pytest

# Run only integration tests
uv run pytest -m integration

# Run only unit tests (skip integration)
uv run pytest -m "not integration"

# Run with verbose output
uv run pytest -v --tb=short
```

## pytest.ini / pyproject.toml Configuration

```toml
[tool.pytest.ini_options]
asyncio_mode = "auto"
markers = [
    "integration: marks tests as integration tests (may be slow)",
]
testpaths = ["tests"]
```
