---
name: python-async-style
description: Python async web service style guide. Use when writing async APIs, database operations, or structuring Python web projects.
---

# Python Async Web Development Style Guide

Conventions and patterns for building async Python web services with raw SQL (no ORM).

## Project Structure

Follow the `src` layout with clear separation:

```
project-name/
├── pyproject.toml          # Project metadata and dependencies (uv)
├── src/
│   └── project_name/
│       ├── __init__.py
│       ├── main.py          # Application entry point and lifespan
│       ├── config.py         # Settings and environment variables
│       ├── db.py             # Database connection pool management
│       ├── routes/           # Route handlers (thin layer)
│       │   ├── __init__.py
│       │   ├── users.py
│       │   └── health.py
│       ├── services/         # Business logic
│       │   ├── __init__.py
│       │   └── user_service.py
│       ├── repositories/     # SQL queries and data access
│       │   ├── __init__.py
│       │   └── user_repo.py
│       ├── models/           # Pydantic models (request/response)
│       │   ├── __init__.py
│       │   └── user.py
│       └── middleware/       # Custom middleware
│           └── __init__.py
├── tests/
│   ├── conftest.py          # Shared fixtures
│   ├── test_routes/
│   ├── test_services/
│   └── test_integration/    # End-to-end tests
├── migrations/              # SQL migration scripts
│   ├── 001_create_users.sql
│   └── 002_add_indexes.sql
└── scripts/                 # Utility scripts
    └── migrate.py
```

## References

- [Project patterns](./references/project-patterns.md)
- [Async patterns](./references/async-patterns.md)
- [Database patterns](./references/database-patterns.md)
- [Error handling](./references/error-handling.md)
