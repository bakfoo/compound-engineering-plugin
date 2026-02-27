# Error Handling Patterns

## Application Exception Hierarchy

```python
# src/project_name/exceptions.py

class AppError(Exception):
    """Base application error."""
    def __init__(self, message: str, status_code: int = 500) -> None:
        self.message = message
        self.status_code = status_code
        super().__init__(message)


class NotFoundError(AppError):
    def __init__(self, resource: str, id: str | int) -> None:
        super().__init__(f"{resource} {id} not found", status_code=404)


class ValidationError(AppError):
    def __init__(self, message: str) -> None:
        super().__init__(message, status_code=422)


class ConflictError(AppError):
    def __init__(self, message: str) -> None:
        super().__init__(message, status_code=409)
```

## Global Error Handler (FastAPI)

```python
from fastapi import Request
from fastapi.responses import JSONResponse

@app.exception_handler(AppError)
async def app_error_handler(request: Request, exc: AppError) -> JSONResponse:
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": exc.message},
    )
```

## Database Error Handling

```python
import asyncpg

async def create_user(pool: asyncpg.Pool, email: str, name: str) -> UserRow:
    try:
        async with pool.acquire() as conn:
            row = await conn.fetchrow(
                "INSERT INTO users (email, name) VALUES ($1, $2) RETURNING *",
                email,
                name,
            )
            return UserRow(**dict(row))
    except asyncpg.UniqueViolationError:
        raise ConflictError(f"User with email {email} already exists")
    except asyncpg.PostgresError as e:
        logger.error("Database error creating user", exc_info=e)
        raise AppError("Internal database error")
```

## Logging

```python
import logging
import structlog

# Configure structured logging
structlog.configure(
    processors=[
        structlog.contextvars.merge_contextvars,
        structlog.processors.add_log_level,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.dev.ConsoleRenderer(),  # Use JSONRenderer in production
    ],
)

logger = structlog.get_logger()

# Usage
await logger.ainfo("user_created", user_id=user.id, email=user.email)
await logger.aerror("database_error", error=str(e), query=query)
```
