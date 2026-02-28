# activerecord-trilogy-failover Example

Demonstrates the gem handling MySQL read-only errors (Aurora failover) with a real MySQL instance.

## Prerequisites

- Docker & Docker Compose
- Ruby >= 3.2
- Bundler

## Setup

```bash
cd example
docker compose up -d
bundle install
bundle exec ruby bin/setup
```

## Run the Demo

```bash
bundle exec ruby bin/demo
```

## What it demonstrates

1. **Railtie auto-loading** — The gem patches TrilogyAdapter automatically on Rails boot
2. **Normal operations** — SELECT/INSERT work as expected
3. **Error detection** — `SET GLOBAL read_only = 1` simulates Aurora failover; MySQL error 1290 becomes `ActiveRecord::ConnectionFailed`
4. **Auto-recovery** — Rails retry mechanism reconnects when read_only is restored (simulated via background thread)

## How the simulation works

- **admin user** (SUPER privilege) can toggle `SET GLOBAL read_only` and is not blocked
- **app user** (no SUPER) gets error 1290 on writes when `read_only = 1` — identical to Aurora failover behavior
- Port 3307 is used to avoid conflicts with local MySQL

## Cleanup

```bash
docker compose down -v
```
