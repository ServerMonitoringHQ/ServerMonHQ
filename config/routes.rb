Servermonitoringhq::Application.routes.draw do

  resources :ports
  resources :measures
  resource :account, :only => [:show, :create] do
    collection do
    end
  end
  
  match '/blog/rss' => 'blogs#index', :format => :rss
  
  resources :blog,
    :controller => 'blogs',
    :only => [ :index, :show ]
    
  resources :incidents, :only => [:index, :show]
  match '/measures/:measure_id/mu/:id' => 'measures#remove_user', :as => :remove_users
  match '/measures/:measure_id/ms/:id' => 'measures#remove_server', :as => :remove_servers
  match '/measures/:measure_id/adduser' => 'measures#add_user', :as => :add_user
  match '/measures/:measure_id/addserver' => 'measures#add_server', :as => :add_server
  match '/logout' => 'sessions#destroy', :as => :logout
  match '/login' => 'sessions#new', :as => :login
  match '/bypass' => 'sessions#bypass', :as => :bypass
  match '/register' => 'users#create', :as => :register
  match '/signup' => 'users#new', :as => :signup
  match '/forgot' => 'users#forgot', :as => :forgot
  match '/invitation/:id' => 'users#invitation', :as => :invitation
  match 'reset/:reset_code' => 'users#reset', :as => :reset
  match '/tour' => 'marketing#tour', :as => :tour
  match '/buy' => 'marketing#buy', :as => :buy
  match '/agent' => 'marketing#agent', :as => :agent
  match '/contact' => 'marketing#contact', :as => :contact
  match '/dashboard' => 'dashboard#index', :as => :dashboard
  match '/paypal_ipn' => 'paypal#paypal_ipn', :as => :paypal_ipn
  match '/monitor_cron' => 'monitorcron#monitor_cron', :as => :monitor_cron
  match '/notification_cron' => 'notificationcron#notification_cron', :as => :notification_cron
  match '/receive_monitor' => 'monitorcron#receive_monitor', :as => :receive_monitor, :method => :post
  match '/receive_page' => 'monitorcron#receive_page', :as => :receive_page, :method => :post
  match '/receive_memory' => 'monitorcron#receive_memory', :as => :receive_memory, :method => :post
  match '/receive_top' => 'monitorcron#receive_top', :as => :receive_top, :method => :post
  match '/receive_ports' => 'monitorcron#receive_ports', :as => :receive_ports, :method => :post
  match '/pulse/:id' => 'servers#pulse', :as => :pulse
  match '/urlandports/:id' => 'servers#urlandports', :as => :urlandports

  resources :users do
    collection do
  post :add_user
  get :invite
  post :send_invite
  get :add
  end
  
  
  end

  resource :session
  resource :alerts
  resources :servers do
    collection do
      get :may_add
      get :newagent
    end
    member do
      post :renamed
      get :configure
      get :agentedit
      get :statistics
      get :remove
      get :download
      get :rename
      put :removed
    end
    resources :logs
    resources :pages
    resources :ports
  end

  match '/' => 'Marketing#index'
  match '/:controller(/:action(/:id))'
end
