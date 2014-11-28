Rees46Api::Application.routes.draw do
  root to: 'home#index'

  get 'recommend', to: 'recommendations#get'

  get 'init_script', to: 'init#init_script'
  get 'generate_ssid', to: 'init#generate_ssid'

  post 'push', to: 'events#push'
  get 'push', to: 'events#push'

  resource :import, only: :none do
    post :orders
    post :items
    post :insales
    post :yml
  end

  resource :mailer, only: :none do
    post :digest
  end

  resources :mailings, only: :create do
    member do
      post :perform
    end
  end

  resources :subscriptions, only: [:create] do
    collection do
      get :unsubscribe
    end
  end
end
