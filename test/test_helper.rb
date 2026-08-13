ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Los contadores de rate_limit viven en la caché y persisten entre tests
    # (memory_store): se vacía en cada test para que un límite por IP no salte
    # por el goteo acumulado de toda la suite.
    setup { Rails.cache.clear }

    # Add more helper methods to be used by all tests here...
  end
end
