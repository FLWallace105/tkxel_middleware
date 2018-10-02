Rails.application.routes.draw do

  resources :fulfillments do
    collection do
      get 'sync'
    end
  end
  resources :brands
  resources :products do
    collection do
      post 'create_bulk_products'
    end
  end

  resources :orders do
    member do
      get 'sync_failed_order_to_cims'
    end
    collection do
      get 'sync_failed_orders_to_cims'
      get 'trends_chart'
      get 'cims_trends_chart'
    end
  end


  resources :reserve_inventories,except: [:show,:edit,:new] do
    collection do
      get 'reserve_inventory'
      post 'subscription_update'
    end
  end

  resources :inventory_on_hands do
    collection do
      get 'sync'
      post 'create_inventory_log'
    end
  end

  devise_for :users, :controllers => { :registrations => 'users/registrations'  }
  
  devise_scope :user do
    authenticated do
      root 'dashboard#dashboard', as: :authenticated_root
    end

    unauthenticated do
      root 'devise/sessions#new', as: :root
    end
  end
  post 'brand_session_setting' => 'dashboard#brand_session_setting'
  resources :users
  require 'sidekiq/web'
  require 'sidekiq/cron/web'

  authenticate :user do
    mount Sidekiq::Web => '/sidekiq'
  end

end
