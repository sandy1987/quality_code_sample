class Question
  include AlgoliaSearch
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActionView::Helpers::DateHelper

  ## Database authenticatable
  field :text, type: String
  field :asked_to,  type: Array, default: []
  field :answerers,  type: Array, default: [] # this contains the user id of all the users who has successfully given the answer
  field :requestor_count,  type: Integer, default: 0
  field :requestors,  type: Array, default: []
  field :status, type: String, default: "active"
  field :popularity_point,  type: Integer, default: 0 # it is the max value of any active answer like+comment
  field :sentiment, type: Integer
  field :hash_tags, type: Array, default: []

  field :asker_gender,    type: String #change asker_gender for all question, if user makes any change in profile edit form
  field :ip,              type: String
  field :postal_code,     type: String
  field :city,            type: String
  field :state_code,      type: String
  field :state_name,      type: String
  field :country_name,    type: String
  field :country_code,    type: String
  field :platform,        type: String
  field :is_mobile,       type: Boolean
  field :user_agent,      type: String
  field :browser,         type: String

  field :qcategories,     type: Array, default: []

  field :last_vote_at,    type: DateTime
  
  # index :text
  # index :asked_to
  # index :status
  # index :hash_tags

  default_scope -> { where(status: "active") }
  belongs_to :user, foreign_key: :asked_by_user #http://stackoverflow.com/questions/14656081/aliasing-a-referenced-relationship-field-in-mongoid

  validates_presence_of :text
  validates_presence_of :asked_by_user
  validates_presence_of :asked_to
  validates :text, length: { minimum: 24, maximum: 120 }
  
  has_many :flags
  embeds_many :answers
  accepts_nested_attributes_for :answers

  after_create :add_sentiment

  algoliasearch force_utf8_encoding: true  do
    attribute :text, :asked_to, :asked_by, :created_at, :qcategories, :card_url, :answerers, :has_answer, :requestor_count, :status, :popularity_point, :sentiment, :asker_gender, :last_vote_at, :state_code, :country_code, :postal_code, :city
    attribute :created_at_i do
      created_at.to_i
    end
    tags do
      hash_tags
    end
    attributesToIndex ['text', 'hash_tags']
    customRanking ['desc(popularity_point)', 'desc(requestor_count)', 'desc(sentiment)'] #https://github.com/algolia/algoliasearch-rails#ranking--relevance
    attributesToRetrieve [:text, :card_url]
    attributesForFaceting ['asked_to', 'asked_by']
  end

  def asked_by
    self.asked_by_user.to_s
  end

  def has_answer
    self.answerers.any?
  end

  def card_url
    "#{ApplicationController.helpers.site_url}/cards/#{self.id}"
  end

  def add_sentiment
    Resque.enqueue RunSentimentResqueJob, { 
      qid: self.id.to_s,
      type: 'question', 
      text: self.text
    }
  end

  def add_request uid
    uid = uid.to_s # being extra careful
    begin
      # first check this user is not an asker of this question
      errors.add(:utility, I18n.t(:asker_cant_request)) and return if asked_by_user.to_s == uid
      # Check this user is already in the list of requestor
      errors.add(:utility, I18n.t(:already_requestor)) and return if requestors.include? uid
      inc requestor_count: 1
      push requestors: uid # do atomic
      self.last_vote_at = Time.now
      self.save!
    rescue => e
      errors.add(:utility, I18n.t(:generic_error))
      Rails.logger.error "Error in adding a requestor. Error is #{e.message}"
    end
  end

  def add_answerer uid
    push answerers: uid.to_s # do atomic
  end

  def remove_answerer uid
    pull answerers: uid.to_s # do atomic
  end

  def self.addnew prms, user

    prms[:text].squish! # this is a rails method
    q = Question.new

    if ApplicationController.helpers.has_bad_word? prms[:text]
      q.errors.add(:base, I18n.t('ask_me_question.question_has_bad_word_html'))
      return q
    end
    
    # Check time window and stop further validation if this fails
    q.check_time_window prms unless user.has_role?(:celebrity)

    return q if q.errors.any?

    # Question can only be asked to celebrity?
    if APP_CONFIG[:ask_question_only_to_celebrity] && !user.has_role?(:celebrity)
      # Grab all asked_to users to check they are celebrity or not
      User.where(_id: {'$in' => prms[:asked_to]}).each { |e|  
        q.errors.add(:base, I18n.t('ask_me_question.only_celebrity_for_question')) and break unless e.has_role?(:celebrity)
      }
    end

    # extract all hash tags
    tags = prms[:text].scan(/#\w+/).flatten
  
    # Question must ends with ? mark. For this we need to remove all hash tags first
    removed_tags_string = tags.present? ? prms[:text].split.delete_if{|x| tags.include?(x)}.join(' ') : prms[:text]

    if removed_tags_string[-1] != "?"
      q.errors.add(:base, I18n.t('ask_me_question.question_last_character'))
    end
    
    # TODO-  we will use algolia to detect it in future..so this block of code will get removed
    # Cannot ask this question, if it has already been asked to any of these celebrities by anyone
    # if we have tags, then use with removed tags - not exactly right...will fix with aloglia in future
    if ( dup = Question.where( { asked_to: {'$in': prms[:asked_to]}, text: /^#{Regexp.escape(prms[:text])}$/i } ).first rescue nil)
      q.errors.add(:base, I18n.t('ask_me_question.alread_exists_question_html', qid: dup.id)) unless dup.blank?
    end

    # Question must be  minimum: 24, maximum: 120 long
    unless (24..120) === prms[:text].strip.length
      q.errors.add(:base, I18n.t('ask_me_question.qlength', min: 24, max: 120))
    end

    # Question cannot be asked more than 3 celebrities
    if prms[:asked_to].length > 3
      q.errors.add(:base, I18n.t('ask_me_question.error'))
    end

    return q if q.errors.any?

    prms[:hash_tags] = tags.map {|e| e[1..-1].downcase}.uniq if tags.present?

    begin
      Question.create prms
    rescue => e 
      q.errors.add(:base, I18n.t(:generic_error)) and return q
      Rails.logger.error "Error in adding a new question. Userid is #{user.id}. Error is #{e.message}"
    end
  end

  def check_time_window prms
    prms[:asked_to].each do |id|
      celeb = User.find(id)
      quests = Question.where(asked_by_user: { '$in': [prms[:asked_by_user].to_s] }, asked_to: { '$in': [id] }, created_at: APP_CONFIG[:time_window][:time_duration].to_i.hours.ago..Time.zone.now)
      if quests.count >= APP_CONFIG[:time_window][:same_celebrity].to_i
        quest = I18n.t(:question).pluralize(APP_CONFIG[:time_window][:same_celebrity]).downcase
        self.errors.add(:base, I18n.t('ask_me_question.same_celeb_question_time_window', no_of_quest: APP_CONFIG[:time_window][:same_celebrity], quest: quest, celeb_name: celeb.name.titleize, time_duration: APP_CONFIG[:time_window][:time_duration], last_quest_time: time_ago_in_words(quests.last.created_at) ))
      end
    end
    quests = Question.where(asked_by_user: { '$in': [prms[:asked_by_user].to_s] }, created_at: APP_CONFIG[:time_window][:time_duration].to_i.hours.ago..Time.zone.now)
    if quests.count >= APP_CONFIG[:time_window][:questions].to_i
      quest = I18n.t(:question).pluralize(APP_CONFIG[:time_window][:questions]).downcase
      self.errors.add(:base, I18n.t('ask_me_question.questions_time_window', no_of_quest: APP_CONFIG[:time_window][:questions], quest: quest, time_duration: APP_CONFIG[:time_window][:time_duration], last_quest_time: time_ago_in_words(quests.last.created_at) ))
    end
  end

  # remove vote
  def cancel_request uid
    uid = uid.to_s # being extra careful
    begin
      # Check this user must be in the list of requestor to cancel
      errors.add(:utility, I18n.t(:not_requestor)) and return unless requestors.include? uid
      inc requestor_count: -1
      pull requestors: uid # do atomic
    rescue => e 
      errors.add(:utility, I18n.t(:generic_error))
      Rails.logger.error "Error in cancelling answer request. Error is #{e.message}"
    end  
  end

  def flag_it uid, txt
    uid = uid.to_s
    begin
      Flag.create ({ user_id: uid, text: txt, type: 'question', question_id: self.id.to_s})
    rescue => e 
      errors.add(:utility, I18n.t(:generic_error))
      Rails.logger.error "Error in flagging the question request. Error is #{e.message}"
    end
  end

  def delete_by_user uid
    uid = uid.to_s
    if self.asked_to.include? uid.to_s # Check user is one of the aswerer
      if self.asked_to.many?
        self.asked_to = self.asked_to - [uid]
      else
        self.status = :yesdelete
      end
      self.answerers = self.answerers - [uid.to_s] # remove this from answerers array
    elsif self.asked_by_user.to_s != uid # Check user must be owner of this question
      errors.add(:utility, I18n.t(:not_authorized)) and return
    elsif answer_exists? # if an answer exists then you can not delete it
      errors.add(:utility, I18n.t(:no_del_answer)) and return
    elsif requestors.length >= APP_CONFIG[:answer_delete_requestor_restriction] # Requestor count is 5 or more than, cannot delete it
      errors.add(:utility, I18n.t(:no_del_requestor, cnt: APP_CONFIG[:answer_delete_requestor_restriction])) and return
    else
      self.status = :yesdelete
    end
    unless self.errors.any?
      begin
        if self.status == 'yesdelete'
          self.destroy!
        else
          self.save!
        end
      rescue => e
        errors.add(:utility, I18n.t(:generic_error))
        Rails.logger.error "Error in deleting the question. Userid is #{uid}. Error is #{e.message}"
      end
    else
      errors.add(:utility, I18n.t(:generic_error))
      Rails.logger.error "Unknown error in deleting the question. Userid is #{uid}. Error is #{self.errors}"
    end
  end

  def self.is_answerer? uid, qid
    self.find(qid.to_s).asked_to.include? uid.to_s rescue false
  end

  # Check if an ACTIVE answer already exists by this user?
  def self.answer_exists? uid, qid
    self.find(qid.to_s).answers.map { |e| e["user_id"].to_s if ( %w(active disabled).include? e["status"] ) }.include? uid.to_s rescue true
  end

  # check if an active answer exists
  def answer_exists?
    answers.each do |e| 
      return true if ( %w(active disabled).include? e["status"] ) 
    end.any?
  end

end
