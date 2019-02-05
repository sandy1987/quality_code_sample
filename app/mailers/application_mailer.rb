class ApplicationMailer < ActionMailer::Base
  skip_before_action :verify_authenticity_token

  default from: "#{APP_CONFIG[:mail_settings][:from_name]} <#{APP_CONFIG[:mail_settings][:no_reply_email]}>",
    reply_to: APP_CONFIG[:mail_settings][:no_reply_email]
  layout 'mailer', :except => [:contact]

  def contact prms
    Rails.logger.error "email not found to contact user. Prms is #{prms.to_s}" and return if !prms[:email]
    @name = prms[:name]
    @email = prms[:email]
    @message = prms[:message]
    @ipaddress = prms[:ipaddress]
    mail to: APP_CONFIG[:general_mail_contact], subject: t("mailer.contact.contact_subject")
  end

  # prms has question_text, question_url, user_email, user_name( full name ) 
  def failed_transcoding prms
    # check prms must have question_url and user_email
    Rails.logger.error "question_url not found to send transcoding status email. Prms is #{prms.to_s}" and return if !prms[:question_url] && !prms[:user_email]
    @name = prms[:user_name]
    @text = prms[:question_text]
    @url = prms[:question_url]
    @exceed_duration = prms[:duration_exceed] == 'yes'
    @extra_msg = @exceed_duration ? t(:failed_trancoding_duration, num: APP_CONFIG[:videos][:answer_upload_max_duration]) : t(:default_failed_video_text)
    mail to: prms[:user_email], subject: t("mailer.transcoding.failed_subject")
  end

  def follow prms
    Rails.logger.error "email not found to follow user. Prms is #{prms.to_s}" and return if !prms[:email]
    @celeb_name = prms[:celeb_name].titleize
    @follower = prms[:follower]
    mail to: prms[:email], subject: t("mailer.follow.follow_subject", follower_name: @follower[:name].titleize )
  end

  def successfull_transcoding prms
    Rails.logger.error "question_url not found to send successfull transcoding status email. Prms is #{prms.to_s}" and return if !prms[:question_url] && !prms[:user_email]
    @name = prms[:user_name]
    @text = prms[:question_text]
    @thumb_url = prms[:thumb_url]
    @url = prms[:question_url]
    mail to: prms[:user_email], subject: t("mailer.transcoding.success_subject", qtext: @text.truncate(60))
  end

  def text_answer_post prms
    Rails.logger.error "question_url not found to send text answer email. Prms is #{prms.to_s}" and return if !prms[:question_url] && !prms[:user_email]
    @answer = prms[:answer].truncate(100, omission: t(:show_more)) #sumit
    @answerer = prms[:answerer]
    @name = prms[:user_name]
    @text = prms[:question_text]
    @url = prms[:question_url]
    mail to: prms[:user_email], subject: t("mailer.answer.text_subject", answerer: @answerer, qtext: @text.truncate(60))
  end

  def video_answer_post prms
    Rails.logger.error "question_url not found to send video answer email. Prms is #{prms.to_s}" and return if !prms[:question_url] && !prms[:user_email]
    @answerer = prms[:answerer]
    @name = prms[:user_name]
    @text = prms[:question_text]
    @thumb_url = prms[:thumb_url]
    @url = prms[:question_url]
    mail to: prms[:user_email], subject: t("mailer.answer.video_subject", answerer: @answerer, qtext: @text.truncate(60))
  end

  def vote prms
    Rails.logger.error "question_url not found to send vote email. Prms is #{prms.to_s}" and return if !prms[:qurl] && !prms[:email]
    @asker_name = prms[:asker_name].titleize
    @qtext = prms[:qtext]
    @qurl = prms[:qurl]
    @voter_name = prms[:voter_name].titleize
    mail to: prms[:email], subject: t("mailer.vote.vote_subject", voter_name: @voter_name.titleize, qtext: @qtext )
  end
end
