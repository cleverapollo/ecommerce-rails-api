Rees46Api::Application.routes.draw do
  root to: 'home#index'

  get 'recommend', to: 'recommendations#get'

  get 'init_script', to: 'init#init_script'

  post 'push', to: 'events#push'
  get 'push', to: 'events#push'

  resource :import, only: :none do
    post :orders
  end

  resource :mailer, only: :none do
    post :digest
  end
end
