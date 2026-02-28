# activerecord-trilogy-failover

Automatic reconnection on MySQL read-only errors for ActiveRecord's Trilogy adapter.

When a MySQL server switches to read-only mode (e.g., Aurora failover, ProxySQL routing change, RDS Multi-AZ switchover), existing connections receive `ER_OPTION_PREVENTS_STATEMENT (1290)` on write attempts. This gem translates that error into `ActiveRecord::ConnectionFailed`, enabling Rails' built-in retry mechanism to transparently reconnect to the new writer.

## How it works

The gem prepends a thin patch to `TrilogyAdapter#translate_exception`:

```
Write attempt → 1290 error → ConnectionFailed → Rails retry → reconnect! → new writer
```

- **SELECT** (with `allow_retry: true`): Automatically retried and reconnected
- **INSERT / UPDATE / DELETE**: Error propagates to the caller (no double-execution risk)

This is the correct behavior — writes should not be silently retried.

## Installation

Add to your Gemfile:

```ruby
gem "activerecord-trilogy-failover", github: "riseshia/activerecord-trilogy-failover"
```

## Usage

**With Rails**: No configuration needed. The Railtie automatically patches `TrilogyAdapter` on load.

**Without Rails**: Manually prepend the patch:

```ruby
require "activerecord_trilogy_failover"

ActiveRecord::ConnectionAdapters::TrilogyAdapter.prepend(
  ActiveRecordTrilogyFailover::AdapterPatch
)
```

### database.yml tuning

Rails' built-in retry settings work with this gem:

```yaml
production:
  adapter: trilogy
  connection_retries: 2    # default: 1
  retry_deadline: 5        # seconds, default: none
```

## Compatibility

- Ruby >= 3.2
- ActiveRecord >= 7.1
- Trilogy >= 2.0

## Development

```bash
bundle install
bundle exec rspec
```

### Integration test

Integration tests run against a real MySQL instance using Docker:

```bash
docker compose up -d            # start MySQL on port 3307
MYSQL_PORT=3307 bundle exec rspec spec/integration/
docker compose down -v          # cleanup
```

## License

MIT
