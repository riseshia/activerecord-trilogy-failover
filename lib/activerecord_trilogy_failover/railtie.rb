# frozen_string_literal: true

module ActiveRecordTrilogyFailover
  class Railtie < Rails::Railtie
    initializer "activerecord_trilogy_failover.patch" do
      ActiveSupport.on_load(:active_record_trilogyadapter) do
        prepend ActiveRecordTrilogyFailover::AdapterPatch
      end
    end
  end
end
