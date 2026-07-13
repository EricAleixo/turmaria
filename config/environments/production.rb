require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=#{1.year.to_i}"
  }
  config.active_storage.service = :local
  config.force_ssl = true
  config.logger = ActiveSupport::Logger.new($stdout)
    .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
    .then { |logger| ActiveSupport::TaggedLogging.new(logger) }
  config.log_tags = [ :request_id ]
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.active_job.queue_adapter = :inline
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
  config.i18n.fallbacks = true
  config.active_support.report_deprecations = false
  config.active_record.dump_schema_after_migration = false

  config.hosts << ENV["APP_HOST"] if ENV["APP_HOST"].present?
  config.hosts << "turmaria.onrender.com"
  config.host_authorization = { exclude: ->(request) { true } }

  Aws.config.update(logger: Rails.logger, log_level: :info)
end