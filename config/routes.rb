Rees46Api::Application.routes.draw do
  root to: 'home#index'

  get 'recommend', to: 'recommendations#get'

  get 'init_script', to: 'init#init_script'

  post 'push', to: 'events#push'
end
