# Async Patterns

## Concurrency with Semaphores

```python
import asyncio

async def fetch_batch(ids: list[int], pool, max_concurrent: int = 10) -> list[Result]:
    sem = asyncio.Semaphore(max_concurrent)

    async def bounded_fetch(id: int) -> Result:
        async with sem:
            async with pool.acquire() as conn:
                row = await conn.fetchrow("SELECT * FROM items WHERE id = $1", id)
                return Result(**dict(row))

    return await asyncio.gather(*[bounded_fetch(id) for id in ids])
```

## Background Tasks

```python
import asyncio
from collections.abc import Set

# Store task references to prevent garbage collection
_background_tasks: Set[asyncio.Task] = set()

def create_background_task(coro) -> asyncio.Task:
    task = asyncio.create_task(coro)
    _background_tasks.add(task)
    task.add_done_callback(_background_tasks.discard)
    return task
```

## Timeout Patterns

```python
import asyncio

async def fetch_with_timeout(url: str, timeout_seconds: float = 5.0) -> Response:
    async with asyncio.timeout(timeout_seconds):
        return await http_client.get(url)
```

## Graceful Shutdown

```python
import signal
import asyncio

async def shutdown(signal_received, loop):
    """Cleanup tasks tied to the service's shutdown."""
    tasks = [t for t in asyncio.all_tasks() if t is not asyncio.current_task()]
    for task in tasks:
        task.cancel()
    await asyncio.gather(*tasks, return_exceptions=True)
    loop.stop()
```

## CPU-Bound Work

```python
import asyncio
from concurrent.futures import ProcessPoolExecutor

executor = ProcessPoolExecutor(max_workers=4)

async def process_heavy(data: bytes) -> Result:
    loop = asyncio.get_event_loop()
    return await loop.run_in_executor(executor, heavy_computation, data)
```

## Async Generators for Streaming

```python
from collections.abc import AsyncGenerator

async def stream_rows(pool, query: str) -> AsyncGenerator[dict, None]:
    async with pool.acquire() as conn:
        async with conn.transaction():
            async for row in conn.cursor(query):
                yield dict(row)
```
