Rails.configuration.middleware.use Browser::Middleware do
  redirect_to "/static/unsupported_browser" if browser.ie? && browser.version.to_i < 10
end