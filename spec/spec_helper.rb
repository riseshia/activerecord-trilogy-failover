# frozen_string_literal: true

require "active_record"
require "active_record/connection_adapters/trilogy_adapter"
require "activerecord_trilogy_failover"

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
