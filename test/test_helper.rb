ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# テスト全体で使用する基準日時
TEST_BASE_TIME = Time.zone.parse("2025-10-15 10:00:00")

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Include ActiveJob test helpers for job testing
    include ActiveJob::TestHelper

    # Add more helper methods to be used by all tests here...
  end
end

module ActionDispatch
  class IntegrationTest
    # コントローラーテスト用の共通ヘルパーメソッド
    def log_in_as(user)
      post session_url, params: { email_address: user.email_address, password: "password" }
    end
  end
end
