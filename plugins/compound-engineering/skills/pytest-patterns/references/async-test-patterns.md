# Async Test Patterns

## Basic Async Test

```python
import pytest

@pytest.mark.asyncio
async def test_get_user(client, sample_user):
    response = await client.get(f"/api/v1/users/{sample_user['id']}")
    assert response.status_code == 200
    data = response.json()
    assert data["email"] == sample_user["email"]
```

## Parameterized Tests

```python
@pytest.mark.asyncio
@pytest.mark.parametrize(
    "email,expected_status",
    [
        ("valid@example.com", 201),
        ("", 422),
        ("not-an-email", 422),
        ("a" * 256 + "@example.com", 422),
    ],
)
async def test_create_user_validation(client, email, expected_status):
    response = await client.post(
        "/api/v1/users",
        json={"email": email, "name": "Test"},
    )
    assert response.status_code == expected_status
```

## Testing Error Cases

```python
@pytest.mark.asyncio
async def test_user_not_found(client):
    response = await client.get("/api/v1/users/99999")
    assert response.status_code == 404
    assert "not found" in response.json()["error"].lower()


@pytest.mark.asyncio
async def test_duplicate_email(client, sample_user):
    response = await client.post(
        "/api/v1/users",
        json={"email": sample_user["email"], "name": "Another"},
    )
    assert response.status_code == 409
```

## Testing Async Generators

```python
@pytest.mark.asyncio
async def test_stream_events(db_conn):
    # Setup
    for i in range(5):
        await db_conn.execute("INSERT INTO events (data) VALUES ($1)", f"event-{i}")

    # Test async generator
    events = []
    async for event in stream_events(db_conn):
        events.append(event)

    assert len(events) == 5
```

## Testing with Timeouts

```python
@pytest.mark.asyncio
async def test_slow_operation_timeout():
    with pytest.raises(asyncio.TimeoutError):
        async with asyncio.timeout(0.1):
            await slow_operation()
```

## Mocking Async Functions

```python
from unittest.mock import AsyncMock, patch

@pytest.mark.asyncio
async def test_service_with_mock():
    mock_repo = AsyncMock()
    mock_repo.get_by_id.return_value = UserRow(id=1, email="test@example.com", name="Test")

    service = UserService(mock_repo)
    result = await service.get_user(1)

    assert result.email == "test@example.com"
    mock_repo.get_by_id.assert_awaited_once_with(1)
```
