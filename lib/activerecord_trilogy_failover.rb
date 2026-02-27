# frozen_string_literal: true

require_relative "activerecord_trilogy_failover/version"
require_relative "activerecord_trilogy_failover/railtie" if defined?(Rails::Railtie)
require_relative "activerecord_trilogy_failover/adapter_patch"
