class ApplicationController < ActionController::Base
  require 'action_view'
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::TextHelper
  include ApplicationHelper

  has_mobile_fu false #do not want to set the format to :mobile or :tablet and only use the helper functions, pass false as an argument.
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :set_user_language, :detect_mobile, :do_uitlity, :follow_action, :set_page_metadata
  layout :set_layout

  def set_user_language
    I18n.locale = 'en' if user_signed_in?
  end

  def detect_mobile
    @is_mobile = is_mobile_device?
    gon.is_mobile = @is_mobile
  end

  def set_layout
    params[:only_cards] == "true" ? "card" : params[:modal] == "true" ? "ajax_load" : "application"
  end

  def do_uitlity
    gon.loading_text = t(:plzwait)
    @hide_ask_nav_button = ( (params[:controller] == 'users' && %w(celebrity_list view_profile).include?(params[:action]) ) || (params[:controller] == 'homes') ) 
  end

  def follow_action
    gon.follow = t(:follow)
    gon.unfollow = t(:unfollow)
    gon.follow_request = t(:follow_request)
    gon.follow_cancel = t(:follow_cancel)
    gon.error_title = t(:error_title)
    gon.follow_request_login_msg = URI.encode(t(:follow_request_login_msg))
    gon.plzlogin = t(:plzlogin)
  end

  def content_for name, content # no blocks allowed yet
    return nil unless name
    @_content_for ||= {}
    # if @_content_for[name].respond_to?(:<<)
    #   @_content_for[name] << content
    # else
      @_content_for[name] = content
    # end
  end

  def content_for?(name)
    @_content_for[name].present?
  end

  def view_context
    super.tap do |view|
      (@_content_for || {}).each do |name, content|
        view.content_for name, content
      end
    end
  end

  private
  
  def set_page_metadata
    begin
      content_for :page_title, t(:default_page_title)
      content_for :page_description, t(:default_page_description)
      content_for :page_keywords, t(:default_page_keywords)
    rescue
      nil
    end
  end

  def check_login
    render json: { message: t(:plzlogin), has_error: true, response_code: 1000 } and return unless current_user.present?
  end

  def get_card_filter
    {
      loggedin_user_id:  (current_user.id.to_s rescue nil),
      asked_to:          params[:user_id] || nil,
      sort_by:           params[:sort_by],
      sort_order:        params[:sort_order],
      asked_by:          params[:asked_by], 
      requested_by:      params[:requested_by], 
      commented_by:      params[:commented_by], 
      liked_by:          params[:liked_by],
      page_number:       params[:page_number] || 1,
      page_offset:       params[:page_offset] || 10,
      question_status:   params[:question_status] || 'active',
      answer_status:     params[:answer_status] || 'active',
      comment_status:    params[:comment_status] || 'active',
      question_id:       params[:question_id] || nil,
      answer_id:         params[:answer_id] || nil,
      tag:               params[:tag] || nil,
      keyword:           params[:keyword] || nil
    }
  end

  def get_card_dom qid, override_status = nil
    @show_options = false
    @show_header = false
    f = get_card_filter.merge(question_id: qid)
    @data = Card.new(f).getData
    @data.first[:video_alert_type] = override_status if override_status # used to don't show previous failed title when a new answer is posted right after failed video
    render_to_string(partial: 'cards/holder', locals: { data: @data, only_cards: true, title: '', show_options: false, show_header: false, dont_include_ajax_modal: true, include_other_js: false})
  end

end
