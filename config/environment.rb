# Load the Rails application.
require File.expand_path('../application', __FILE__)
require "rails_admin/support/hash_helper"

# Setup all config
_yf = YAML.load_file("#{Rails.root}/config/config.yml").symbolize

## Changed symbolize to with_indifferent_access, as it was giving "undefined method" on local
APP_CONFIG = _yf[:common].merge(_yf[Rails.env.to_sym])
# Initialize the Rails application.
Rails.application.initialize!
# Redis and resque
APP_CONFIG[:redis] = if Rails.application.secrets.aredis['url']
  Redis.new url: Rails.application.secrets.aredis['url'] # for production, on heroku, it is URL
else
  Redis.new host: Rails.application.secrets.aredis['host'], port: Rails.application.secrets.aredis['port']
end
Resque.redis = APP_CONFIG[:redis]

# Sendgrid settings
ActionMailer::Base.smtp_settings = Rails.application.secrets.sendgrid.symbolize
