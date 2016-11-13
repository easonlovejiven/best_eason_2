Rails.application.routes.draw do
  # captcha_route
  mount RuCaptcha::Engine => "/rucaptcha"
  root 'home/home#index'
  mount V3::ClientApi => '/v3'
  mount V4::ClientApi => '/v4'
  post '/api/qiniu_uptoken', to: 'qiniu#uptoken'
  post  '/shop_funding_wx_back', to: 'shop/application#shop_funding_wx_back'
  post  '/shop_product_wx_back', to: 'shop/application#shop_product_wx_back'
  get '/activate/:id/:activation_code', to: 'home/accounts#activate', as: :activate
  get '/api/banners/ad', to: 'home/suggestions#banners'

  resources :findings, :controller => 'home/findings' do
    collection do
      get :tasks
      get :stars
      get :clubs
      get :companies
    end
  end

  # resources :home, :controller => 'home/home' do
  #   collection do
  #     get :welcome
  #   end
  # end
  namespace :home do
    root to: 'home#index'
    resources :qrcode, only: [:index]
    resources :home do
      collection do
        get :welcome
        # 明星主页
        get :star_home
        # 认证用户管理后台
        get :mindex
        # 搜索结果
        get :search_result
        # 发布成功页面
        get :step3
        # 关联账号
        get :tasks
        get :welfares
        post :create_subject_comments
        post :create_dynamic_comments
        # 图片福利详情页面
        get :letter_show
        # 语音福利详情
        get :voice_show
      end
    end
    resources :suggestions
    resources :identities do
      collection do
        get :failure
        get :success
      end
    end
    resources :rankings do
      collection do
        get :stars
        get :fans_will
      end
    end

    resources :abouts do
      collection do
        get :about
        get :agreements
        get :rules
        get :obi
        get :audio
      end
    end

    resources :stars do
      member do
        put :follow
        put :unfollow
        get :followers
      end
    end

    resources :users do
      member do
        get :carts
        put :update_birthday
        put :update_cover
        put :update_avatar
        put :follow
        put :unfollow
        get :follows
        get :followers
        post :set_auto_share
      end
      collection do
        get :personal_center
        get :welfares
        get :edit
        get :owhat
        # 普通用户等级规则
        get :level
        get :addresses
        get :login
        get :register
        post :share_callback
        get :identity
        get :identities
        get :apply
        post :apply_identity
        # 草稿箱列表
        get :drafts
      end
    end

    resources :backend do
      collection do
        get :manage
        get :withdraw
        get :withdraw_show
        get :withdraw_new
        post :withdraw_create
        get :tasks
        get :order_show
        get :orders
        get :export
        get :exported_orders
        get :download
        get :welfares
        get :expens
        get :expen_show
      end
    end

    resources :notifications
    resources :wallets

    resources :addresses do
      member do
        put :default
      end
    end
    resources :punches
  end

  #任务类路由
  namespace :shop do
    resources :fundings do
      member do
        get :show_result
        get :get_ticket_type
        get :more_users
        get :preview
      end
    end
    resources :events do
      member do
        get :get_ticket_type
        get :cart_ticket_type
        get :more_users
        get :preview
      end
    end
    resources :products do
      member do
        get :get_ticket_type
        get :cart_ticket_type
        get :more_users
        get :preview
      end
    end
    resources :topics do
      member do
        post :create_dynamic
        put :dynamic_like
        get :preview
        post :create_dynamic_vote
      end
    end
    resources :vote_options, only: [] do
      member do
        post :vote_dynamic
      end
    end
    resources :dynamic_comments
    resources :subjects do
      member do
        put :like
        get :preview
      end
    end
    resources :medias do
      member do
        get :preview
      end
    end
    resources :comments
    resources :tasks do
      member do
        put :publish
        put :unpublish
      end
    end
    resources :carts do
      collection do
        get :checkout
        get :direct_checkout
        post :add
      end
    end

    resources :orders do
      member do
        delete :cancel
        get :success
        get :payment
        post :settlement
        post :alipay_direct_notify, :alipay_wap_notify, :check
        post :wx_pay_direct_notify, :wx_pay_wap_notify, :wx_order_status
        get :wx_qr_code
      end
      collection do
        post :alipay_notify
      end
    end

    resources :funding_orders do
      member do
        delete :cancel
        get :success
        get :payment
        post :settlement
        post :alipay_direct_notify, :alipay_wap_notify, :check
        post :wx_pay_direct_notify, :wx_pay_wap_notify, :wx_order_status
        get :wx_qr_code
      end
      collection do
        post :alipay_notify
      end
    end
  end

  namespace :qa do
    resources :posters do
      member do
        get :more_users
        get :preview
      end
      put :answer, on: :member
      put :complete, on: :member
    end
    resources :questions
  end

  namespace :welfare do
    resources :papers
    resources :letters do
      member do
        post :buy
        get :preview
      end
    end
    resources :voices do
      member do
        post :buy
      end
    end
    resources :events do
      member do
        get :more_users
        get :get_ticket_type
        get :preview
      end
      collection do
        post :buy
      end
    end
    resources :products do
      member do
        get :more_users
        get :get_ticket_type
        get :preview
      end
      collection do
        post :buy
        get :checkout
      end
    end
    resources :expens
  end

  namespace :manage do
    root to: 'application#index'

    namespace :manage do
      root to: 'application#index'
      resources :editors
      resources :users
      resources :accounts
      resources :roles
      resources :grants
    end
    resources :statistics

    namespace :welfare do
      root to: 'application#index'
      resources :papers do
        put :publish, on: :member
        put :unpublish, on: :member
      end
      resources :letters
      resources :events
      resources :products
    end

    namespace :notification do
      resources :sends do
        post :cancel, on: :member
      end
    end

    namespace :qa do
      resources :posters
    end

    namespace :shop do
      post 'search_star', to: 'application#search_star'
      get  'get_star', to: 'application#get_star'
      post  'get_orgs', to: 'application#get_orgs'
      post 'search_fans', to: 'application#search_fans'
      get  'get_fans', to: 'application#get_fans'
      post  'search_freight_templates', to: 'application#search_freight_templates'
      get  'get_freight_templates', to: 'application#get_freight_templates'
      root to: 'application#index'

      resources :events
      resources :tasks do
        member do
          put :sync
          put :publish
          put :unpublish
        end
      end
      resources :task_images do
        put :publish, on: :member
        put :unpublish, on: :member
      end

      resources :price_categories

      resources :products
      resources :fundings
      resources :topics
      resources :freight_templates
      resources :topic_dynamics
      resources :subjects
      resources :medias
      resources :order_items do
        collection do
          get :export
        end
      end
      resources :funding_orders do
        collection do
          get :export
        end
      end
    end

    namespace :core do
      root to: 'application#index'
      post 'search_user', to: 'application#search_user'
      post 'search_user_all', to: 'application#search_user_all'
      get 'get_user', to: 'application#get_user'
      get 'get_user_all', to: 'application#get_user_all'
      resources :users
      resources :identities do
        member do
          put :accept
          put :reject
        end
      end
      resources :hot_records
      resources :withdraw_orders do
        member do
          get :download
          get :manual_download
        end
      end
      resources :exported_orders do
        member do
          get :download
        end
      end
      resources :images do
        put :publish, on: :member
        put :unpublish, on: :member
      end
      resources :stars do
        put :publish, on: :member
        put :unpublish, on: :member
      end
      resources :accounts
      resources :recordings
      resources :ads do
        put :publish, on: :member
        put :unpublish, on: :member
      end
      resources :banners do
        put :publish, on: :member
        put :unpublish, on: :member
        get :show_current_order, on: :collection
      end
      resources :findings do
        put :publish, on: :member
        put :unpublish, on: :member
      end
      resources :expens do
        collection do
          get :export
        end
      end
    end
  end

  namespace :shop do
    root to: 'application#index'
    resources :events
    resources :products
    resources :fundings
    resources :freight_templates
  end

  # Engines
  require 'sidekiq/web'
  require 'sidekiq/cron/web'
  require "sidekiq/grouping/web"
  mount Sidekiq::Web => '/sidekiq'


  resources :accounts, :controller => 'home/accounts' do
    collection do
      post :send_phone_code
      post :send_email_code
      get :emaila
      get :emailerror
      get :emailsuccess
      get :emailerrorsuccess
      post :reset
      get :forget
      get :find
      get :edit_phone
      get :edit_password
      get :validate_account
    end
    member do
      put :update_phone
      get :new_password
      put :update_password
      put :activate
    end
  end

  resources :sessions, :controller => 'home/sessions'
  resources :sessions, :controller => 'home/users'
  resources :connections, :controller => 'home/connections' do
    collection do
      get :current
      get :callback
      post :callback
      get :weibo_share_callback
      post :weibo_share_callback
      get :popup
      get :list
      get :new_share
    end
    member do
      put :binding
    end
  end
end
