Geoip2.configure do |conf|
  # Mandatory
  conf.license_key = Rails.application.secrets.maxmind['license_key']
  conf.user_id = Rails.application.secrets.maxmind['user_id']

  # Optional
  conf.host = 'geoip.maxmind.com' # Or any host that you would like to work with
  conf.base_path = '/geoip/v2.0' # Or any other version of this API
  conf.parallel_requests = 5 # Or any other amount of parallel requests that you would like to use
end