Rails.application.routes.draw do
  #mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  devise_for :users, skip: [:registrations],
    controllers: { 
      sessions: 'sessions', 
      passwords: 'passwords', 
      confirmations: 'confirmations',
      unlocks: 'unlocks'
    }, 
    path: '', 
    path_names: { 
      sign_in:  '/users/login',
      sign_out: '/users/logout'
    }

  root to: 'homes#index'
  
  # Routes for user controller
  resource :users, only: :index do 
    get   'auto_suggest', on: :collection
    get   'search', on: :collection
    post  'search_celebrity', on: :collection
  end

  get     '/users' , to: 'users#celebrity_list', as: 'celebrity_list_users'
  post     '/follow' , to: 'users#follow', as: 'follow'
  
  # For facebook callback
  devise_scope :user do
    get 'auth/:provider/callback', to: 'sessions#omniauth_callback'
    get 'auth/failure', to: redirect('/')

    ## Registration controller
    get     '/users/signup', to: 'registrations#new', as: :new_user_registration
    post    '/users/signup', to: 'registrations#create',  as: :user_registration
    get     '/:username/profile', to: 'registrations#edit',  as: :edit_user_registration
    put     '/:username/profile', to: 'registrations#update', as: :update_user_registration

    get     '/:username/disabled', to: 'users#disabled'
    get     '/reset_password' , to: 'passwords#reset_password', as: 'reset_password'

    ## These routes may be required in the future
    # get     '/cancel', to: 'registrations#cancel', as: :cancel_user_registration
    # patch   '/:username/profile', to: 'registrations#update'
    # delete  '/:username/destroy', to: 'registrations#destroy'
  end

  get     'static/terms_and_conditions', to: 'collateral#tnc'
  get     'static/contact', to: 'collateral#contact'
  post    'static/contact', to: 'collateral#create_contact_message'
  get     'static/privacy_policy', to: 'collateral#privacy_policy'
  get     'static/about', to: 'collateral#about'
  get     'static/faqs', to: 'collateral#faqs'
  get     'static/press_release', to: 'collateral#prs'
  get     'static/unsupported_browser', to: 'collateral#browser_notice'
  get     'static/lcheck', to: 'collateral#login_check'

  post    'sendmail', to: 'maildispatchers#queue_amail_in_sendgrid' 
  
  get     'analytics/datasource', to: 'analytics#getdata' # to get data via ajax
  get     'analytics', to: 'analytics#index' # to show cumulitative pages
  get     'analytics/questions', to: 'analytics#qlist' # show list of questions
  get     'analytics/questions/:qid', to: 'analytics#show', as: :analytics_question # show questions detail

  # Answer routes
  get     'questions/:qid/answers/new', to: 'answers#new'
  post    'questions/:qid/answers', to: 'answers#create'
  get     'questions/:qid/answers/:aid/flag', to: 'answers#newflag'
  post    'questions/:qid/answers/:aid/flag', to: 'answers#addflag'
  get     'questions/:qid/answers/:aid/embed_code', to: 'answers#embed_code'
  post    'questions/:qid/answers/:aid/utility', to: 'answers#do_utility' # for liking, unliking
  delete  'questions/:qid/answers/:aid', to: 'answers#destroy' 
  post    'questions/:qid/answers/:aid/view', to: 'answers#log_views' 

  # Comment routes
  # patch   'questions/:qid/answers/:aid/comments/:cid', to: 'comments#update' - for future
  delete  'questions/:qid/answers/:aid/comments/:cid', to: 'comments#destroy' 
  get     'questions/:qid/answers/:aid/comments', to: 'comments#index' 
  post    'questions/:qid/answers/:aid/comments', to: 'comments#create'
    
  # Question routes
  post    'questions/:qid/utility', to: 'questions#do_utility'
  get     'questions/:qid/flag', to: 'questions#newflag'
  post    'questions/:qid/flag', to: 'questions#addflag'
  get     'questions/:qid/embed_code', to: 'questions#embed_code'
  delete  'questions/:qid', to: 'questions#destroy'

  get     '/:username/questions/new', to: 'questions#new'
  post    '/:username/questions', to: 'questions#create'
  
  # Cards routes
  get     'questions/:qid/answers/:aid', to: 'cards#show_answer' # to show an answer explicitly - it does show metadata, but not used for sharing (redundent with cards/:qid/:social_aid)
  get     'cards/:qid/:social_aid', to: 'cards#show' # this is EXACTLY same as 'cards/:qid' , but it shows fb/twitter metadata, because a particular answerer is highlighted
  get     'cards/:qid', to: 'cards#show' # it shows social metadata, if no answer is posted yet, else no social metadata shown

  
  # For embed
  get     'ecard/:qid/answers/:aid/video', to: 'cards#video'
  get     'ecard/:qid/answers/:aid', to: 'cards#eshow'
  get     'ecard/:qid', to: 'cards#eshow'

  get     'cards', to: 'cards#index'
  get     '/:username/questions', to: 'cards#questions_or_answers'
  get     '/:username/answers', to: 'cards#questions_or_answers'

  # Suggestion routes
  post    '/users/suggest', to: 'suggestions#create'
  # get     '/users/upload', to: 'users#upload'
  # post    '/users/upload_file', to: 'users#upload_file'

  # Transcoding routes
  post    '/transcoding', to: 'transcodings#addJob'
  post    '/transcoding/savestatus', to: 'transcodings#saveStatus'
  get     '/transcoding/cleanup', to: 'transcodings#cleanup'

  get     'styleguides', to: 'styleguides#index'
  mount   Resque::Server, :at => '/resque'
  # ============FOLLOWING TWO ROUTES MUST BE LAST ROUTE IN THIS ORDER===============

  # Temporarily added for Jane TODO - remove
  get     '/:username/clink' , to: 'users#clink'
  get     '/:username/makec' , to: 'users#makec'

  match   '/404', to: 'collateral#file_not_found', via: :all
  match   '/422', to: 'collateral#unprocessable', via: :all
  match   '/500', to: 'collateral#internal_server_error', via: :all
  match   '/401', to: 'collateral#unauthorized', via: :all

  get     '/:username/nsettings', to: 'notifications#index'
  put     '/:username/nsettings', to: 'notifications#update', as: 'nsettings_update'
  get     '/:username/isettings', to: 'notifications#interests'
  put     '/:username/isettings', to: 'notifications#iupdate', as: 'isettings_update'

  get     '/:username' , to: 'users#view_profile', as: 'view_profile_users'

  #get     '*path' => redirect('/')
end
