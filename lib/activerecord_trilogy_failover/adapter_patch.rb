# frozen_string_literal: true

module ActiveRecordTrilogyFailover
  module AdapterPatch
    # MySQL error code for ER_OPTION_PREVENTS_STATEMENT
    # Raised when the server is running with --read-only
    MYSQL_READ_ONLY_ERROR_CODE = 1290

    private

    def translate_exception(exception, message:, sql:, binds:)
      if read_only_error?(exception)
        # Close the underlying TCP connection to prevent pool reuse.
        # A read-only server still accepts ROLLBACK, SELECT 1, and ping,
        # so without closing, the connection passes verify! and stays in the pool.
        @raw_connection&.close rescue nil

        return ActiveRecord::ConnectionFailed.new(
          "#{exception.class}: #{exception.message}",
          connection_pool: @pool
        )
      end
      super
    end

    def read_only_error?(exception)
      exception.respond_to?(:error_code) &&
        exception.error_code == MYSQL_READ_ONLY_ERROR_CODE &&
        exception.message.include?("--read-only")
    end
  end
end
