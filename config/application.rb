require File.expand_path('../boot', __FILE__)

require "rails"
require_relative 'class_helper'

# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
# require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "sprockets/railtie"
require "rails/test_unit/railtie"
require "mongoid/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Askorty
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :en

    GC::Profiler.enable # enabling garbage collection timing for NewRelic - https://docs.newrelic.com/docs/agents/ruby-agent/features/garbage-collection

    # Will generated related test files for rspec on rails generate
    config.generators do |g|
      g.template_engine :haml
      g.assets false
      g.orm :mongoid
      g.test_framework :rspec
      g.integration_tool :rspec
    end

    # http://rubysource.com/get-your-app-ready-for-rails-4/
    config.autoload_paths += Dir["#{config.root}/lib"]

    config.to_prepare do
      Devise::Mailer.layout "mailer" # mailer.html.haml
    end

    # http://mongoid.org/en/mongoid/docs/installation.html
    # TODO turn this off in production
    Mongoid.logger.level = Logger::DEBUG
    Mongoid.raise_not_found_error = false

    # http://easyactiverecord.com/blog/2014/08/19/redirecting-to-custom-404-and-500-pages-in-rails/
    config.exceptions_app = self.routes

  end
end
