# frozen_string_literal: true

require "spec_helper"

MYSQL_PORT = ENV.fetch("MYSQL_PORT", 3307).to_i

# Check MySQL connectivity and skip integration tests if unavailable
MYSQL_AVAILABLE = begin
  conn = Trilogy.new(
    host: "127.0.0.1",
    port: MYSQL_PORT,
    username: "app",
    password: "app",
    database: "failover_test"
  )
  conn.close
  true
rescue Trilogy::ConnectionError
  false
end

if MYSQL_AVAILABLE
  # Apply the adapter patch (same as Railtie does in Rails apps)
  ActiveRecord::ConnectionAdapters::TrilogyAdapter.prepend(
    ActiveRecordTrilogyFailover::AdapterPatch
  )

  # Create test schema
  ActiveRecord::Base.establish_connection(
    adapter: "trilogy",
    host: "127.0.0.1",
    port: MYSQL_PORT,
    username: "app",
    password: "app",
    database: "failover_test"
  )

  ActiveRecord::Schema.define do
    create_table :posts, force: true do |t|
      t.string :title, null: false
      t.timestamps
    end
  end

  # Define test model
  class Post < ActiveRecord::Base; end
end

def with_admin_connection
  conn = Trilogy.new(
    host: "127.0.0.1",
    port: MYSQL_PORT,
    username: "admin",
    password: "admin",
    database: "failover_test"
  )
  yield conn
ensure
  conn&.close
end

def set_read_only!
  with_admin_connection { |c| c.query("SET GLOBAL read_only = 1") }
end

def fetch_connection_id
  ActiveRecord::Base.lease_connection
    .raw_connection.query("SELECT CONNECTION_ID() AS id").first
end

def unset_read_only!
  with_admin_connection { |c| c.query("SET GLOBAL read_only = 0") }
end

RSpec.configure do |config|
  config.before(:each, :integration) do
    Post.delete_all
  end

  config.after(:each, :integration) do
    unset_read_only!
  end
end
