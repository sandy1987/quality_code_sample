ruby '2.2.2'

source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.4'

group :production, :staging do
  # To prevent this error on heroku - Error encountered while saving cache bc744e6b23974a979ff2b80fba17d0a578f6991c/global.css.scssc: can't dump anonymous class #<Class:0x007f504d2d00b0>
  # Ref. http://stackoverflow.com/questions/22276991/heroku-error-encountered-while-saving-cache
  # gem 'sass' '~> 3.3.6'   #instead of adding this gem just run=   heroku rake assets:clobber   before deployment
  # Use unicorn as the app server
  gem 'unicorn', '~> 4.9.0'
  # For heroku logs https://devcenter.heroku.com/articles/rails-integration-gems
  # https://devcenter.heroku.com/articles/rails-4-asset-pipeline
  gem 'rails_12factor', '~> 0.0.3'
  gem "newrelic_rpm"
end

# Social login
gem 'omniauth'
gem 'omniauth-facebook'
gem 'omniauth-google-oauth2'
gem 'omniauth-twitter'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby
# User role
gem 'rolify'

# Use jquery as the JavaScript library
gem 'jquery-rails', '~> 4.0.4'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
# gem 'turbolinks', '~> 2.5.3'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

# Uploading image
gem 'mongoid-paperclip', :require => 'mongoid_paperclip'
# Infinite scrolling
gem 'will_paginate_mongoid'

# To interact with maxmind geoip web service
# used this to resolve ffi issue - https://github.com/ffi/ffi/issues/342#issuecomment-151662980
gem 'geoip2'
gem 'city-state'
#gem 'rails_admin', '~> 0.7.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

# Algolia search
gem "algoliasearch-rails"
# ===================== All developer defined gems are placed below =====================

gem 'haml-rails', '~> 0.9.0'
gem 'bson_ext'
gem 'mongoid', '~> 4.0.2'
# For accessing ruby variables in javascript
gem 'gon', '~> 6.0.1'
gem 'rest-client', '~> 1.8.0'
gem 'resque', require: 'resque/server'
# For Javascript internationalisation
gem 'i18n-js', '~> 2.1.2'
# For user authentication
gem 'devise', '~> 3.5.2'
# For configuring devise to send email using resque queue
gem 'devise-async', '~> 0.10.1'
gem 'aws-sdk', '~> 2.1.14'
# For library file dependencies
gem 'aws-sdk-v1'
gem 'jquery-ui-rails', '~> 5.0.5'
gem 'mobile-fu', '~> 1.3.1'
gem 'zencoder', '~> 2.5.1'
gem 'active_model_serializers'
gem 'rails_autolink'
gem "browser"
gem 'addressable'

gem 'roo'

group :development, :test do
  gem 'awesome_print'
  gem 'pry'
  gem 'pry-remote'
  gem 'pry-nav'
  gem 'factory_girl_rails'
  gem 'rspec-rails'
end


# ====================== All developer defined gems end here ============================

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'pry-rails'
  gem 'byebug'
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  # gem 'resque_spec'
end

