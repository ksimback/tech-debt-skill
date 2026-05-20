# Tech Debt Audit — toy-python-service

This fixture is intentionally tiny. A good audit should not pad to 30 findings.

Expected material findings:

| ID | Category | File:Line | Severity | Effort | Description | Recommendation |
|----|----------|-----------|----------|--------|-------------|----------------|
| F001 | Security hygiene | `app.py:5` | High | S | SQL is built by string concatenating untrusted `user_id`. | Use parameterized queries or a query builder that binds values. |
| F002 | Security hygiene | `app.py:11` | High | S | A hardcoded API key-like secret is present in config. | Read secrets from environment or a secret manager and document required variables. |
| F003 | Dependency & config debt | `app.py:10` | Medium | S | `DATABASE_URL` has an implicit local default that is not documented in the fixture README. | Document the env var or make missing config explicit. |
| F004 | Error handling & observability | `app.py:18` | Low | S | Request handling uses `print` for query logging, which can leak sensitive data and is not structured. | Use structured logging and avoid logging raw queries containing user input. |

Things that look bad but are actually fine:

- The entire service is a single file. For a fixture this small, splitting modules would be noise.
