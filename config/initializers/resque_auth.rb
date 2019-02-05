Resque::Server.use(Rack::Auth::Basic) do |user, password|
  user == Rails.application.secrets.background_user
  password == Rails.application.secrets.background_password
end