Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  config.action_mailer.delivery_method = :smtp 

  config.action_mailer.default_url_options = APP_CONFIG[:default_url_option]
  # config.action_view.raise_on_missing_translations = true

  # only for development & test
  Zencoder.api_key = Rails.application.secrets.zencoder["api_key"]

  config.paperclip_defaults = {
    storage: APP_CONFIG[:images][:storage],
    s3_credentials: Rails.application.secrets["aws"],
    bucket: APP_CONFIG[:avatar_image_bucket]
  }

end