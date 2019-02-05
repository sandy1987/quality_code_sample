class SendMail
  @queue = :background_jobs
  
  def self.perform type, user_id
    user = User.find(user_id)
    case type
    when "reset_password" 
      SendMail.reset_password user   
    end
  end

  def self.reset_password user
    user.send_reset_password_instructions
  end

end