class DeviseMailer < Devise::Mailer
  layout 'mailer'
  default from: "#{APP_CONFIG[:mail_settings][:from_name]} <#{APP_CONFIG[:mail_settings][:no_reply_email]}>",
    reply_to: APP_CONFIG[:mail_settings][:no_reply_email]
end