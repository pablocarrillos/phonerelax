# config/initializers/rollbar.rb

Rollbar.configure do |config|
  config.access_token = ENV['ROLLBAR_ACCESS_TOKEN']

  # Solo reporta en producción (y si hay token configurado).
  config.enabled = Rails.env.production? && ENV['ROLLBAR_ACCESS_TOKEN'].present?

  # Set environment from Rails
  config.environment = ENV['ROLLBAR_ENV'].presence || Rails.env

  # Optional: Set code version (dokku expone GIT_REV)
  config.code_version = ENV['GIT_SHA'].presence || ENV['GIT_REV']

  # Add exception exclusions
  config.exception_level_filters.merge!(
    'ActionController::RoutingError' => 'ignore'
  )

  # Enable async reporting (optional, recommended)
  # config.use_async = true
end
