# Project Patterns

## Application Entry Point

```python
# src/project_name/main.py
from contextlib import asynccontextmanager
from fastapi import FastAPI

from .config import settings
from .db import create_pool, close_pool
from .routes import users, health


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    app.state.pool = await create_pool(settings.database_url)
    yield
    # Shutdown
    await close_pool(app.state.pool)


app = FastAPI(title=settings.app_name, lifespan=lifespan)
app.include_router(health.router)
app.include_router(users.router, prefix="/api/v1")
```

## Configuration

```python
# src/project_name/config.py
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    app_name: str = "myservice"
    database_url: str
    db_pool_min_size: int = 5
    db_pool_max_size: int = 20
    debug: bool = False

    model_config = {"env_file": ".env"}


settings = Settings()
```

## Layer Responsibilities

### Routes (thin)
- Parse and validate request (via Pydantic)
- Call service
- Return response
- No business logic

### Services (business logic)
- Orchestrate operations
- Apply business rules
- Call repositories
- Handle transactions

### Repositories (data access)
- Execute SQL queries
- Map results to typed objects
- No business logic
- Return typed data (dataclass or Pydantic model)

## Coding Conventions

- Use `async def` for all I/O operations
- Type annotate every function
- Use `str | None` syntax (not `Optional[str]`)
- Use lowercase generics: `list[str]`, `dict[str, Any]`
- Format with `ruff format`, lint with `ruff check`, type check with `mypy`
- Package management with `uv`
