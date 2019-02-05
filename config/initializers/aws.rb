# Set AWS config
Aws.config.update({
  region: Rails.application.secrets.aws["region"] || 'us-west-2',
  credentials: Aws::Credentials.new(Rails.application.secrets.aws["access_key_id"], Rails.application.secrets.aws["secret_access_key"])
})
