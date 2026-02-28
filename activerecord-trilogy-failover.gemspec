# frozen_string_literal: true

require_relative "lib/activerecord_trilogy_failover/version"

Gem::Specification.new do |spec|
  spec.name = "activerecord-trilogy-failover"
  spec.version = ActiveRecordTrilogyFailover::VERSION
  spec.authors = ["Shia"]
  spec.email = ["rise.and.and@gmail.com"]

  spec.summary = "Automatic reconnection on MySQL read-only errors for ActiveRecord Trilogy adapter"
  spec.description = <<~DESC
    Handles MySQL ER_OPTION_PREVENTS_STATEMENT (1290) errors by translating them
    into ActiveRecord::ConnectionFailed, enabling Rails' built-in retry mechanism
    to transparently reconnect. Useful for Aurora failover, ProxySQL, RDS Multi-AZ,
    or any MySQL read-only switchover scenario.
  DESC
  spec.homepage = "https://github.com/riseshia/activerecord-trilogy-failover"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/])
    end
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 7.1"
  spec.add_dependency "trilogy", ">= 2.0"
end
