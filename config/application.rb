require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

Rack::Utils.multipart_part_limit = 0

module Owhat
  class Application < Rails::Application
    # require core ext files
    config.autoload_paths += [config.root.join('lib')]
    Dir[File.join(Rails.root, "lib", "core_ext", "*.rb")].each {|l| require l }
    Dir[File.join(Rails.root, "app", "models/lean_cloud", "*.rb")].each {|l| require l }
    config.assets.paths << Rails.root.join("vendor", "assets", "images")
    config.generators do |g|
      g.test_framework :rspec,
        fixture:            false,
        view_specs:         false,
        routing_specs:      false,
        request_specs:      false,
        helper_specs:       false,
        integration_specs:  false
      g.integration_tool :rspec
      g.helper false
      g.assets false
      g.fixture_replacement :factory_girl, dir: 'spec/factories'
      g.form_builder :simple_form
    end
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Beijing'
    config.active_record.default_timezone = :local
    config.active_record.time_zone_aware_attributes = false


    # config.active_record.observers = [:event_cache_observer, :feed_observer]

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]
    config.i18n.default_locale = 'zh-CN'

    config.middleware.insert_before 0, "Rack::Cors" do
      allow do
        origins 'localhost:9000', 'localhost:8090', 'localhost:8000', 'localhost:3000', 'www.owhat.cn', 'owhat.cn', 'dev.owhat.avosapps.com', 'cloud.owhat.cn', 'backend.owhat.dev'
        resource '*', :headers => :any, :methods => [:get, :put, :post, :options]
      end
    end
    ::HOSTS = YAML::load_file("#{Rails.root}/config/host.yml")[Rails.env]
    ::MAILER_CONFIG = YAML.load(File.open("#{Rails.root}/config/mailer.yml"))[Rails.env]
    config.action_mailer.smtp_settings = ::MAILER_CONFIG.to_a.map{|k,v|{k.to_sym=>v}}.inject(&:merge)
    config.active_record.raise_in_transactional_callbacks = true
    config.middleware.insert 0, Rack::UTF8Sanitizer
    ::RAILS_ROOT = Rails.root
    ::RAILS_ENV = Rails.env
    ::RAILS_DEFAULT_LOGGER = Rails.logger
  end
end
