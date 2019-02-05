class UserAuth

  def self.add_profile_detail auth, user
    case auth.provider
    when I18n.t('registration.facebook')
      image = "#{auth.info.image}"
    when I18n.t('registration.google')
      image = auth.info.image.gsub('?sz=50','?sz=150')
    else
      image = auth.info.image
    end
    user.avatar_image = image if user.avatar_image.blank?
    user.username = get_username auth, user if user.username.blank?
    user.name = auth.info.name
    user.gender = auth.extra.raw_info.gender
    user.country = get_country_name auth if user.country.blank?
  end

  def self.auth_details auth
    user = email_already_exist auth
    user = user ? merge_socail_info_with_user( auth, user ) : sign_up_with_social_auth_detail( auth )
    return user
  end

  def self.auth_details_present? auth
    return true unless (user = UserAuth.email_already_exist auth)
    return !is_account_already_merged?( auth, user, false )
  end

  def self.check_auth auth, user
    is_account_already_merged?( auth, user, false ) ? nil : merged_notice(auth) if user
  end

  def self.create_username auth
    if auth.info.first_name
      auth.info.first_name[0..20].downcase + rand(10**4).to_s
    elsif auth.info.name
      auth.info.name.split(" ").first[0..20].downcase + rand(10**4).to_s
    else
      "user-#{SecureRandom.hex(10)}"
    end
  end

  def self.email_already_exist auth
    User.where( email: auth.info.email ).first
  end

  def self.get_country_name auth
    case auth.provider
    when "facebook"
      auth.extra.raw_info.location.name.split(',').last.strip if auth.extra.raw_info.location.present?
    end
  end

  def self.get_username auth, user
    username = auth.extra.raw_info.username || create_username(auth)
    get_username auth, user if User.where(username: username).first.present?
    return username
  end

  def self.get_url auth
    case auth.provider
    when 'facebook'
      url = auth.info.urls.values.first
    else
      auth.info.urls.values.first rescue nil
    end
  end

  def self.is_account_already_merged? auth, user, merged
    case auth.provider
    when I18n.t('registration.facebook')
      merged = user.facebook_merged
    when I18n.t('registration.google')
      merged = user.google_merged
    end
    merged
  end

  # def self.is_account_confirmed? user
  #   user.confirmed_at.present?
  # end

  def self.merge_socail_info_with_user auth, user
    update_user auth, user
    user
  end

  def self.merged_notice auth
    msg = I18n.t('registration.merged_notice', email: auth.info.email)
  end

  def self.sign_up_with_social_auth_detail auth
    User.where( email: auth.info.email ).first_or_initialize.tap do |user|
      update_user auth, user
    end
    # user = User.where( email: auth.info.email ).first
    # user.build_notification.save
    # return user
  end

  def self.update_user auth, user
    update_user_profile auth, user
    user_oauth_token auth, user
  end

  def self.update_user_profile auth, user
    gender = user.gender
    add_profile_detail auth, user
    user.url[auth.provider] = get_url auth
    user.skip_confirmation!
    user.save!(validate:false)
    User.update_questions_on_gender_change gender, user
  end

  def self.user_oauth_token auth, user
    case auth.provider
    when I18n.t('registration.facebook')
      user.facebook_access_token = auth.credentials.token
      user.facebook_merged = true
      user.facebook_user_id = auth.uid
    when I18n.t('registration.google')
      user.google_access_token = auth.credentials.token
      user.google_merged = true
      user.google_user_id = auth.uid
    end
  end

end
