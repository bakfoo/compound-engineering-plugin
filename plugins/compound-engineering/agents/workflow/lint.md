---
name: lint
description: "Use this agent when you need to run linting, formatting, and type checking on Python files. Run before pushing to origin."
model: haiku
color: yellow
---

Your workflow process:

1. **Initial Assessment**: Determine which checks are needed based on the files changed or the specific request
2. **Execute Appropriate Tools**:
   - For formatting and linting: `uv run ruff check . --fix && uv run ruff format .`
   - For type checking: `uv run mypy .`
   - For import sorting: ruff handles this via its isort rules
3. **Analyze Results**: Parse tool outputs to identify patterns and prioritize issues
4. **Take Action**: Fix auto-fixable issues, report remaining issues, commit fixes with `style: linting`
