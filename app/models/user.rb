class User
  include AlgoliaSearch
  include Mongoid::Document
  rolify
  include Mongoid::Timestamps
  include Mongoid::Paperclip

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :async, :timeoutable and :omniauthable
  devise :database_authenticatable, :async , :confirmable, :omniauthable, :registerable, :recoverable, :rememberable, :trackable, :validatable, :lockable
  attr_accessor :login ## For login via email or username
  validate :predefined_words
  validate :username_content_type
  validates :username, uniqueness: { case_sensitive: false }
  validates_length_of :name, minimum: 4, maximum: 40
  validates_length_of :username, minimum: 4, maximum: 16

  ## Database authenticatable
  field :email,  type: String, default: ""
  field :encrypted_password, type: String, default: ""

  ## Recoverable
  field :reset_password_token,   type: String
  field :reset_password_sent_at, type: Time

  ## Rememberable
  field :remember_created_at, type: Time

  ## Trackable
  field :sign_in_count,  type: Integer, default: 0
  field :current_sign_in_at, type: Time
  field :last_sign_in_at,  type: Time
  field :current_sign_in_ip, type: String
  field :last_sign_in_ip,  type: String

  ## User profile
  field :name,  type: String
  field :username,  type: String
  field :country,  type: String, default: "US"
  field :gender,  type: String, default: "unknown"

  field :blurb,  type: String 
  field :url,  type: Hash, default: {}
    
  field :followers,  type: Array, default: [] # list of user_id whom this user is following
  field :following,  type: Array, default: [] # list of user_id who follow this user

  field :categories,  type: Array, default: [] # list of categories, this celebrity falls in
  field :interested_categories,  type: Array, default: [] # list of categories, this regular user is interested in
  
  ## Facebook key
  field :facebook_access_token,  type: String
  field :facebook_user_id,  type: String

  ## Twitter keys
  # field :twitter_access_token,  type: String
  # field :twitter_user_id,  type: String

  ## Google keys
  field :google_access_token,  type: String
  field :google_user_id,  type: String

  ## Confirmable
  field :confirmation_token,   type: String
  field :confirmed_at,  type: Time
  field :confirmation_sent_at, type: Time
  field :unconfirmed_email,  type: String # Only if using reconfirmable

  ## Lockable
  field :failed_attempts, type: Integer, default: 0 # Only if lock strategy is :failed_attempts
  field :unlock_token,  type: String # Only if unlock strategy is :email or :both
  field :locked_at,  type: Time

  ## Merged social account
  field :facebook_merged,   type: Boolean, default: false
  field :google_merged,  type: Boolean, default: false

  field :status,   type: String, default: "active"
  
  # index :username
  # index :name
  # index :status
  # index :email

  validates :blurb, length: { maximum: 150 }

  has_many :questions
  has_many :contacts
  has_many :suggestions
  has_one :notification

  ## Image fields
  has_mongoid_attached_file :avatar_image, APP_CONFIG[:images][:avatar_image].merge({ default_url: "#{ APP_CONFIG[:s3_url_prefix]}/#{APP_CONFIG[:s3_static_content_bucket]}/default.png" })
  has_mongoid_attached_file :profile_background, APP_CONFIG[:images][:banner].merge({ default_url: "#{ APP_CONFIG[:s3_url_prefix]}/#{APP_CONFIG[:s3_static_content_bucket]}/default_banner.jpg" })

  ## Image content type
  validates_attachment_content_type :avatar_image, APP_CONFIG[:images][:avatar_image][:accepted_file_types]
  validates_attachment_content_type :profile_background, APP_CONFIG[:images][:banner][:accepted_file_types]

  ## Image size
  validates_attachment_size :avatar_image, less_than: APP_CONFIG[:images][:avatar_image][:max_upload_size].kilobytes, message: I18n.t('registration.avatar_size', size: " #{APP_CONFIG[:images][:avatar_image][:max_upload_size]/1024}")
  validates_attachment_size :profile_background, less_than: APP_CONFIG[:images][:banner][:max_upload_size].kilobytes, message: I18n.t('registration.banner_size', size: " #{APP_CONFIG[:images][:banner][:max_upload_size]/1024}")

  scope :celebrities, lambda { where( role_ids: Role.celebrity.first.id ) }
  
  # default_scope -> { where(status: 'active') } - because we still want that user visible in card, but not able to login

  after_create  :add_notification

  algoliasearch force_utf8_encoding: true do
    attribute :name, :username, :profile_image, :created_at, :country, :gender, :status, :followers_count, :categories, :interested_categories
    attribute :created_at_i do
      created_at.to_i
    end
    attributesToIndex ['name', 'username']
    customRanking ['desc(followers_count)', 'desc(created_at)'] #https://github.com/algolia/algoliasearch-rails#ranking--relevance
  end

  def followers_count
    self.followers.length
  end

  def profile_image
    self.avatar_image :preview
  end

  def active_for_authentication?
    super && (self.status == "active")
  end

  def add_notification
    begin
      self.build_notification.save
    rescue
      Rails.logger.error "Could not add notification default embedded document"
    end
  end

  def follow user
    uid = user.id.to_s # user id
    cid = self.id.to_s # celebrity id
    errors.add(:utility, I18n.t(:already_followed)) and return if followers.include?(uid)
    begin
      push followers: uid # do atomic
      user.push following: cid
    rescue => e
      errors.add(:utility, I18n.t(:generic_error))
      Rails.logger.error "Could not follow celebrity. User id is #{uid}. Exception message is #{e.message}"
    end
  end

  def unfollow user
    uid = user.id.to_s # user id
    cid = self.id.to_s # celebrity id
    errors.add(:utility, I18n.t(:never_followed)) and return unless followers.include?(uid)
    begin
      pull followers: uid # do atomic
      user.pull following: cid
    rescue => e
      errors.add(:utility, I18n.t(:generic_error))
      Rails.logger.error "Could not unfollow celebrity. User id is #{uid}. Exception message is #{e.message}"
    end
  end

  def questions_count
    Question.where(asked_by_user: self.id).count
  end

  def login
    @login || self.username || self.email
  end

  def login=(login)
    @login = login
  end

  def predefined_words
    errors.add(:username, I18n.t('devise.error.reserve_word')) if APP_CONFIG[:reserve_words].split().include? self.username
  end

  def self.find_for_database_authentication warden_conditions
    conditions = warden_conditions.dup
    if login = conditions.delete(:login).strip
      where(conditions).where( '$or': [ { email: login }, { username: login } ] ).first
    else
      where(conditions).first
    end
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions.to_h).where('$or' => [ {:username => login.downcase }, {:email => login.downcase } ]).first
    else
      where(conditions.to_h).first
    end
  end

  # Find user by email - create or update provider and uid
  def self.from_omniauth auth
    UserAuth.auth_details auth
  end

  def self.is_celebrity? user
    user.has_role? :celebrity
  end

  def self.is_regular? user
    user.has_role? :regular
  end

  def self.strip_white_spaces prms
    prms.map{|k,v| (k=="url" ? prms[k].map{|i,url| prms[k][i].strip! } : k=="categories" ? '' : prms[k].strip!) unless prms[:avatar_image] }
  end

  def self.update_questions_on_gender_change auth_gender, user
    Question.where(asked_by_user:user.id).map{|q| q.update(asker_gender:user.gender)} unless user.gender == auth_gender
  end

  def to_param
    username
  end

  def username_content_type
    validate = Regexp.new( APP_CONFIG[:validate_username] );
    errors.add(:username, I18n.t('devise.error.invalid_username')) unless validate.match(self.username)
  end

end
