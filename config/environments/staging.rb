Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  config.action_controller.page_cache_directory = "#{Rails.root.to_s}/public"

  # Enable Rack::Cache to put a simple HTTP cache in front of your application
  # Add `rack-cache` to your Gemfile before enabling this.
  # For large-scale production use, consider using a caching reverse proxy like nginx, varnish or squid.
  # config.action_dispatch.rack_cache = true

  # Disable Rails's static asset server (Apache or nginx will already do this).
  config.serve_static_files = false

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = :uglifier
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = true

  # Generate digests for assets URLs.
  config.assets.digest = true

  # `config.assets.precompile` has moved to config/initializers/assets.rb

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # Set to :debug to see everything in the log.
  config.log_level = :info

  # Prepend all log lines with the following tags.
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups.
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store
  config.cache_store = :redis_store, "redis://#{Rails.application.secrets.redis_host}:6980/10/cache", { expires_in: 90.minutes }
  # Rails.application.secrets.dalli.tap do |dalli|
  #   config.cache_store = :dalli_store, '698fcc1a0dfe438e.m.cnbjalicm12pub001.ocs.aliyuncs.com:11211',
  #     { :namespace => "OWHAT_PRODUCTION", username: dalli["username"], password: dalli["password"], :expires_in => 1.day, :compress => true }
  # end

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = 'qimage.owhat.cn'
  config.assets_cdn_server = "http://cdn.owhat.cn"

  # Precompile additional assets.
  # application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
  # config.assets.precompile += %w( search.js )

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Disable automatic flushing of the log to improve performance.
  # config.autoflush_log = false

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  config.action_mailer.delivery_method = :sendmail
  Rails.application.config.middleware.use ExceptionNotification::Rack,
  :email => {
    :email_prefix         => "Owhat3-[#{Rails.env}]",
    :sender_address       => %{"noreply" <noreply@owhat.cn>},
    :exception_recipients => Rails.env.production? ? %w{saler_alert@owhat.cn} : %w{staging_alert@owhat.cn},
    :delivery_method => :smtp,
    :smtp_settings => {
      :port           => 25,
      :address        => 'smtp.exmail.qq.com',
      :user_name      => 'noreply@owhat.cn',
      :password       => 'owhat123123',
      :domain         => 'owhat.cn',
      :authentication => :plain,
    }
  }
  config.action_mailer.perform_deliveries = true
end

Rails.application.routes.default_url_options[:host] = 'http://mobile.owhat.cn'
