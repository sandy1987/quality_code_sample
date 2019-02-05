class QuestionsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_question, except: [:new, :newflag, :create]

  def new
    @cat_list = Category.where(lang: 'en').order_by(name: 'asc')
    qp = request.query_parameters.map {|k, v| "#{k}=#{URI.encode(v)}"}.join("&")
    redirect_to "/users/login?#{qp}" unless current_user.present?
    @user = User.find_by username: params[:username].downcase
    if APP_CONFIG[:ask_question_only_to_celebrity] && !@user.has_role?(:celebrity)
      render json: { error: t('ask_me_question.only_celebrity_for_question') } and return
    end
  end

  def newflag
    qp = request.query_parameters.map {|k, v| "#{k}=#{URI.encode(v)}"}.join("&")
    redirect_to "/users/login?#{qp}" unless current_user.present?
  end

  def create
    render json: { error: t(:plzlogin), success: nil } and return unless current_user.present?
    render json: { error: t(:min_qcategory), field: {category: 0}, success: nil } and return if min_qcategory?
    render json: { error: t(:max_qcategory), field: {category: 2}, success: nil } and return if max_qcategory?
    question_params[:asker_gender] = current_user.gender
    question_params[:platform] = browser.platform  
    question_params[:is_mobile] = @is_mobile
    question_params[:user_agent] = request.user_agent
    question_params[:browser] = browser.name
    question_params[:ip] = (Rails.env == 'production' ? request.remote_ip : '73.222.0.206')

    r =  Question.addnew question_params.permit!, current_user
    unless r.errors.any?
      # this is not really event tracking, rather its adding job to find geo location
      track_event ({
        question_id: r.id.to_s,
        action: 'qgeo',
        ip: (Rails.env == 'production' ? request.remote_ip : '73.222.0.206'),
        type: 'qgeoinfo'
      })
      clist = User.find(r.asked_to).map(){|e| e.name}.to_sentence rescue ''
      ttext = t(:single_question_card_page_title, celebrity_name_list_comma_separated: clist, question_text: r.text).truncate(116)
      share_dom = render_to_string(partial: 'common/ask_to_share_q', locals: {cid: r.id, ttext: ttext}, format: :html)
      if current_user.notification.try(:answer_posting)
        msg = t('ask_me_question.success')
      else
        msg = t('ask_me_question.success_with_alert_html', url: "#{site_url}/#{current_user.username}/nsettings")
      end
      render json: { error: nil, success: "#{msg} #{share_dom}", dom: get_card_dom(r.id.to_s) }
      return
    end 
    render json: { error: r.errors.messages.values.join("<br /> ").html_safe, success: nil }
  end

  def addflag
    render json: { message: t(:plzlogin), has_error: true, response_code: 1000 } and return unless current_user.present?
    @question.flag_it current_user.id, params[:text]
    if @question.errors.any?
      render json: { message: @question.errors.messages.values.join(". "), has_error: true }
    else 
      render json: { message: t(:flag_success), has_error: false }
    end
  end

  def embed_code
    render "cards/_embed_code"
  end

  # This method supports 
  # :add_request - adding a requestor
  # :cancel_request - cancel answer request
  def do_utility
    render json: { message: t(:plzlogin), has_error: true, response_code: 1000 } and return unless current_user.present?
    case params[:type].to_sym
    when :add_request
      @question.add_request current_user.id
      track_event ({
        question_id: @question.id.to_s,
        question_text: @question.text,
        sentiment: @question.sentiment,
        asked_to: @question.asked_to,
        asked_by: @question.asked_by_user.to_s,
        action: 'vote'
      })
    when :cancel_request
      @question.cancel_request current_user.id
      track_event ({
        question_id: @question.id.to_s,
        action: 'delete_vote',
        type: 'delete'
      })
    else
      render json: { message: t(:not_valid_request), has_error: true } and return
    end
    requestor = @question.requestor_count
    requestor_count = pluralize(requestor, t(:other))
    # check if question model has any error?
    if @question.errors.any?
      render json: { message: @question.errors.messages.values.join(". "), has_error: true }
    else
      send_mail_to_asker if notify_on_vote_in?
      render json: { message: "", has_error: false, requestor: requestor, requestor_count:requestor_count }
    end
  end

  def destroy
    render json: { message: t(:plzlogin), has_error: true, response_code: 1000 } and return unless current_user.present?
    multi = @question.asked_to.many?
    qdup_id = @question.id.to_s unless multi
    @question.delete_by_user current_user.id 
    unless @question.errors.any?
      if multi
        track_event ({ question_id: @question.id.to_s, action: 'delete_answerer', type: 'delete' , entity_id: current_user.id.to_s })
      else
        track_event ({ question_id: qdup_id, action: 'delete_question', type: 'delete' })
      end
      render json: { message: t('quest_deleted_success'), has_error: false, type: :question } and return 
    end
    Rails.logger.error "Could not delete a question. Qid is #{params[:qid]} . User is #{current_user.id} Error is #{@question.errors.messages}"
    render json: { message: @question.errors.messages.values.join(". "), has_error: true } if @question.errors.any?
  end

  def send_mail_to_asker
    arg = { asker_name: @question.user.name, email: @question.user.email, qtext: @question.text, qurl: "#{site_url}/cards/#{@question.id}", voter_name: current_user.name }
    ( enqueue_mail "vote", arg ) unless @question.errors.any?    
  end

  private

  def max_qcategory?
    params[:question][:qcategories].count > 2
  end

  def min_qcategory?
    params[:question][:qcategories].blank? || params[:question][:qcategories].count == 0
  end

  def notify_on_vote_in?
    params[:type]=='add_request' && ( @question.user.notification.receive_vote_notification rescue true)
  end

  def set_question
    @question = Question.find params[:qid]
    render json: { message: t(:invalid_error, entity: "question"), has_error: true } and return false unless @question
  end

  def question_params
    params[:question]
  end

end
