require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings.
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=#{1.year.to_i}"
  }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Store uploaded files on Amazon S3.
  config.active_storage.service = :amazon

  # Force all access to the app over SSL.
  config.force_ssl = true

  # Log to STDOUT by default. Heroku/Render/Fly.io capture this automatically.
  config.logger = ActiveSupport::Logger.new($stdout)
    .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
    .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  # Prepend all log lines with the following tags.
  config.log_tags = [ :request_id ]

  # Log level (debug, info, warn, error, fatal, unknown).
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Use a real queuing backend for Active Job.
  config.active_job.queue_adapter = :sidekiq
  # config.active_job.queue_name_prefix = "turmaria_production"

  # Action Mailer
  config.action_mailer.perform_caching = false
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.default_url_options = { host: ENV.fetch("APP_HOST", "localhost"), protocol: "https" }
  config.action_mailer.smtp_settings = {
    address:              "smtp.gmail.com",
    port:                 ENV["EMAIL_PORT"],
    domain:               "gmail.com",
    user_name:            ENV["EMAIL_USERNAME"],
    password:             ENV["EMAIL_PASSWORD"],
    authentication:       "plain",
    enable_starttls_auto: true
  }

  # Ignore bad email addresses and do not raise email delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Enable DNS rebinding protection and other `Host` header attacks.
  config.hosts << ENV["APP_HOST"] if ENV["APP_HOST"].present?

  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }

  Aws.config.update(logger: Rails.logger, log_level: :info)
end