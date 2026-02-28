# frozen_string_literal: true

require "bundler/setup"
require "rails"
require "active_record/railtie"
Bundler.require(*Rails.groups)

module FailoverExample
  class Application < Rails::Application
    config.load_defaults 8.0
    config.eager_load = false
    config.logger = Logger.new($stdout)
    config.logger.level = Logger::INFO
  end
end
