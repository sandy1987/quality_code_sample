class UsersController < ApplicationController
  include UsersHelper
  before_action :only_cards
  skip_before_action :verify_authenticity_token, only: [:follow, :search_celebrity]
  require 'will_paginate/array'

  def auto_suggest
    redirect_to celebrity_list_users_path and return unless params[:search_by]
    celebrity_user_list "auto_suggest"
    return ( render partial: "/users/celebrity_search_list" ) if @celebrity_users.blank?
    render json: { list: @celebrity_users }
  end

  def celebrity_list
    @celebrity_users = users.where(status: 'active').celebrities.paginate( page: params[:page_number], per_page: APP_CONFIG[:items_per_page]*2 ).shuffle
    @data = @celebrity_users
  end

  def search
    redirect_to celebrity_list_users_path and return unless params[:search_by]
    celebrity_user_list "paginate"
    @data = @celebrity_users
    return ( render partial: "/users/celebrity_search_list" ) if @only_cards
  end

  def search_celebrity
    celebrity_user_list "all"
  end

  # TODO - remove it and also remove it from before_action hook above. this is added temporarily for testing for Jane
  def makec
    @user.add_role :celebrity
    render nothing: true
  end

  # TODO - remove it and also remove it from before_action hook above . this has been added temporarily for load testing
  def clink
    set_user unless @user
    if @user
      render text: "#{site_url}/confirmation?confirmation_token=#{@user.confirmation_token}"
    else
      render nothing: true
    end
  end

  def disabled
    redirect_to "/#{params[:username]}" and return if @user.status == 'active'
    render layout: "blank" and return if params[:modal] == "true"
  end

  def follow
    render json: { message: t(:plzlogin), has_error: true, response_code: 1000 } and return unless current_user.present?
    @celeb = User.find(params[:following_id])
    render json: { message: t(:follow_denied), has_error: true } and return if @celeb.id.to_s == current_user.id.to_s
    case params[:type].to_sym
    when :follow
      @celeb.follow current_user
    when :unfollow
      @celeb.unfollow current_user
    else
      render json: { message: t(:not_valid_request), has_error: true } and return
    end
    if @celeb.errors.any?
      render json: { message: @celeb.errors.messages.values.join(". "), has_error: true }
    else
      send_mail_to_celebrity if notify_on_follow?
      render json: { message: "", fcount: @celeb.followers.count ,has_error: false }
    end
  end

  def send_mail_to_celebrity
    arg = { celeb_name: @celeb.name, email: @celeb.email, follower: { name: current_user.name, img: current_user.avatar_image(:preview), blurb: current_user.blurb, path: "#{site_url}/#{current_user.username}" } }
    ( enqueue_mail "follow", arg ) unless @celeb.errors.any?    
  end

  def view_profile
    @data = []
    @social_hash = {}
    redirect_to '/404' and return if @user.blank?

    redirect_to "/#{params[:username]}/disabled#{params[:modal] == 'true' ? '?modal=true' : ''}" and return unless @user.status == 'active'
    #return if APP_CONFIG[:ask_question_only_to_celebrity] && !@user.has_role?("celebrity")

    if params[:modal] == "true" # no infinite scroll and pagination in modal
      page_number = 1
      offset = 1
    else
      page_number = params[:page_number]
      offset = APP_CONFIG[:items_per_page]/2
    end

    if File.basename(@user.avatar_image(:large)) == 'default.png' # if user has an avatar image
      @social_hash['og:image']            = @user.avatar_image(:large)
      @social_hash['og:image_secure_url'] = @user.avatar_image(:large)
      @social_hash['og:image:width']      = "150"
      @social_hash['og:image:height']     = "150"
    end
    @social_hash['article:author']        = @user.url[:facebook] if @user.url[:facebook].present? 
    @social_hash['twitter:site']          = @user.url[:twitter].present? ? "@#{@user.url[:twitter].split('/').last}" : "@askorty"

    f = {
      page_number:  page_number,
      sort_by:      params[:sort_by] || :popularity,
      page_offset:  offset
    }
    if @user.has_role?("celebrity")
      f = get_card_filter.merge({asked_to: @user.id.to_s })
      qans = Card.new(f.merge({type: :answer, answerd_by: @user.id})).getData if params[:type] == 'answer' || !params[:type]
      qn = Card.new(f.merge({type: :question})).getData if params[:type] == 'question' || !params[:type]
      @data = (params[:type] == "answer" ? qans : params[:type] == "question" ? qn : ( (qans || []) + ( qn || [] ) ))
    else
      f = get_card_filter.merge({asked_by: @user.id})
      qans = Card.new(f.merge({type: :answer})).getData
      qn = Card.new(f.merge({type: :question})).getData
      @data = ( (qans || []) + ( qn || [] ) )
    end
    @data = @data.shuffle if params[:sort_by].blank?
  end

  def upload
    redirect_to '/users' and return unless (current_user.present? && current_user.has_role?(:admin))
  end

  def upload_file
    import params[:file]
    redirect_to users_upload_path
  end

  private

  def notify_on_follow?
    params[:type] == 'follow' && ( current_user.notification.receive_follow_notification rescue true )
  end

  def only_cards
    @only_cards = params[:only_cards] == "true"
  end

  def open_spreadsheet file
    case File.extname(file.original_filename)
    when '.csv' then Roo::Csv.new(file.path)
    when '.xls' then Roo::Excel.new(file.path)
    when '.xlsx' then Roo::Excelx.new(file.path)
    else
      flash[:error] = t(:unknown_file_format, name: file.original_filename)
    end
  end

  def set_user
    @user ||= User.find_by username: params[:username].downcase 
  end

  def set_page_metadata
    if params[:username].present?
      set_user
      return unless @user
      content_for :page_title, t(:detail_page_title, name: @user.name)
      content_for :page_description, t(:detail_page_description, name: @user.name)
      content_for :page_keywords, t(:detail_page_keywords, name: @user.name)
    else
      content_for :page_title, t(:celebrity_list_page_title)
      content_for :page_description, t(:celebrity_list_page_description)
      content_for :page_keywords, t(:celebrity_list_page_keywords)
    end
  end

  def update_url data
    ( data.blank? || data[ Regexp.new( APP_CONFIG[:validate_url] )]) ? data : (APP_CONFIG[:protocol] + data)
  end

end
