# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

activerecord-trilogy-failover is a Ruby gem that translates MySQL error 1290 (read-only) into `ActiveRecord::ConnectionFailed`, enabling Rails' built-in retry mechanism to reconnect after failover events (Aurora failover, ProxySQL routing, RDS Multi-AZ switchover).

## Commands

```bash
# Install dependencies
bundle install

# Run all tests
bundle exec rspec

# Run a specific test file
bundle exec rspec spec/adapter_patch_spec.rb

# Run a specific test by description
bundle exec rspec spec/adapter_patch_spec.rb -e "returns ActiveRecord::ConnectionFailed"

# Integration test (requires Docker)
docker compose up -d                              # Start MySQL on port 3307
MYSQL_PORT=3307 bundle exec rspec spec/integration/
docker compose down -v                            # Cleanup
```

## Architecture

The gem has three components:

- **AdapterPatch** (`lib/activerecord_trilogy_failover/adapter_patch.rb`): Core logic. Uses `prepend` to override `TrilogyAdapter#translate_exception`. Detects error code 1290, returns `ActiveRecord::ConnectionFailed` instead, delegates all other errors to `super`.

- **Railtie** (`lib/activerecord_trilogy_failover/railtie.rb`): Auto-loads the patch in Rails via `ActiveSupport.on_load(:active_record_trilogyadapter)`. No manual setup needed in Rails apps.

- **Entry points** (`lib/activerecord_trilogy_failover.rb`, `lib/activerecord-trilogy-failover.rb`): The hyphenated file is an alias for the underscored one.

**Error flow:** MySQL 1290 → `translate_exception` intercepted by AdapterPatch → `read_only_error?` check → `ActiveRecord::ConnectionFailed` → Rails retries with fresh connection to new writer.

**Dependencies:** activerecord >= 7.1, trilogy >= 2.0, Ruby >= 3.2.0.

## Test Structure

Unit tests in `spec/adapter_patch_spec.rb` use mocked TrilogyAdapter (no real DB needed). Integration tests in `spec/integration/` run against a real MySQL instance (Docker or CI service container). Integration tests are automatically skipped when MySQL is unavailable.
