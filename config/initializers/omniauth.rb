Rails.application.config.middleware.use OmniAuth::Builder do
  
  ## Facebook API keys
  # https://github.com/plataformatec/devise/wiki/OmniAuth:-Overview#facebook-example
  # http://stackoverflow.com/a/31477674
  # Ref. https://github.com/mkdynamic/omniauth-facebook#configuring
  provider :facebook, Rails.application.secrets.facebook['client_id'], Rails.application.secrets.facebook['client_secret'], { 
    scope: Rails.application.secrets.facebook['scope'],
    info_fields: 'id,verified,gender,link,name,email,first_name,last_name,age_range',
    secure_image_url: true,
    image_size: 'large'
  }

  ## Google API keys
  provider :google_oauth2, Rails.application.secrets.google_oauth2['client_id'], Rails.application.secrets.google_oauth2['client_secret'], Rails.application.secrets.google_oauth2['scopes']

end
