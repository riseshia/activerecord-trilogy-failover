# frozen_string_literal: true

RSpec.describe ActiveRecordTrilogyFailover::AdapterPatch do
  # Build a test adapter that mimics TrilogyAdapter's translate_exception
  # without needing a real DB connection
  let(:test_adapter_class) do
    Class.new do
      prepend ActiveRecordTrilogyFailover::AdapterPatch

      attr_reader :pool

      def initialize(pool: nil)
        @pool = pool
      end

      private

      # Minimal reproduction of TrilogyAdapter#translate_exception fallback:
      # wraps into StatementInvalid (same as the real adapter's super chain)
      def translate_exception(exception, message:, sql:, binds:)
        ActiveRecord::StatementInvalid.new(message, connection_pool: @pool)
      end
    end
  end

  let(:pool) { instance_double(ActiveRecord::ConnectionAdapters::ConnectionPool) }
  let(:adapter) { test_adapter_class.new(pool: pool) }

  def mysql_error(error_code, message = "error")
    error = Trilogy::BaseError.new(message)
    allow(error).to receive(:error_code).and_return(error_code)
    error
  end

  describe "#translate_exception" do
    context "when MySQL returns ER_OPTION_PREVENTS_STATEMENT (1290)" do
      let(:error) do
        mysql_error(1290, "The MySQL server is running with the --read-only option")
      end

      it "returns ActiveRecord::ConnectionFailed" do
        result = adapter.send(
          :translate_exception, error,
          message: error.message, sql: "UPDATE users SET name = 'test'", binds: []
        )

        expect(result).to be_a(ActiveRecord::ConnectionFailed)
      end

      it "preserves the original error message" do
        result = adapter.send(
          :translate_exception, error,
          message: error.message, sql: "UPDATE users SET name = 'test'", binds: []
        )

        expect(result.message).to include("read-only")
      end

      it "includes the connection pool" do
        result = adapter.send(
          :translate_exception, error,
          message: error.message, sql: "UPDATE users SET name = 'test'", binds: []
        )

        expect(result.connection_pool).to eq(pool)
      end
    end

    context "when MySQL returns a different error code" do
      it "delegates to the original translate_exception" do
        error = mysql_error(1045, "Access denied for user 'root'@'localhost'")

        result = adapter.send(
          :translate_exception, error,
          message: error.message, sql: "SELECT 1", binds: []
        )

        expect(result).to be_a(ActiveRecord::StatementInvalid)
        expect(result).not_to be_a(ActiveRecord::ConnectionFailed)
      end
    end

    context "when the exception does not respond to error_code" do
      it "delegates to the original translate_exception" do
        error = StandardError.new("something went wrong")

        result = adapter.send(
          :translate_exception, error,
          message: error.message, sql: "SELECT 1", binds: []
        )

        expect(result).to be_a(ActiveRecord::StatementInvalid)
        expect(result).not_to be_a(ActiveRecord::ConnectionFailed)
      end
    end
  end
end
