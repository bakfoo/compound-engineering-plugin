---
name: pytest-patterns
description: Pytest patterns for async web services. Use when writing tests for async APIs, database operations, or integration tests.
---

# Pytest Patterns for Async Web Services

Testing patterns for Python async web services with raw SQL, using pytest and pytest-asyncio.

## Test Structure

```
tests/
├── conftest.py              # Shared fixtures (DB pool, test client)
├── test_routes/              # API endpoint tests
│   ├── conftest.py           # Route-specific fixtures
│   ├── test_users.py
│   └── test_health.py
├── test_services/            # Business logic tests
│   └── test_user_service.py
├── test_repositories/        # Data access tests
│   └── test_user_repo.py
└── test_integration/         # End-to-end tests
    └── test_user_flow.py     # Full workflow tests
```

## References

- [Fixture patterns](./references/fixture-patterns.md)
- [Async test patterns](./references/async-test-patterns.md)
- [Integration test patterns](./references/integration-test-patterns.md)
