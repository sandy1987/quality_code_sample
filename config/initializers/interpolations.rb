module Paperclip
  module Interpolations

    def user_file attachment, style_name
      Digest::MD5.hexdigest( attachment.instance.id.to_s )
    end

  end
end