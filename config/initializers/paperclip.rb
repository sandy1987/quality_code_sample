Paperclip::Attachment.default_options[:path] = APP_CONFIG[:avatar_image][:path] 
Paperclip::Attachment.default_options[:s3_host_name] = APP_CONFIG[:avatar_image][:s3_host_name]
Paperclip::Attachment.default_options[:s3_protocol] = APP_CONFIG[:https_eanbled] ? :https : :http