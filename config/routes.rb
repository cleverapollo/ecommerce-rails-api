Rees46Api::Application.routes.draw do
  root to: 'home#index'

  get 'recommend', to: 'recommendations#get'

  get 'init_script', to: 'init#init_script'
  get 'generate_ssid', to: 'init#generate_ssid'

  post 'push', to: 'events#push'
  get 'push', to: 'events#push'

  # В будущих отраслевых алгоритмах сохраняет текущие выбранные фильтры (контекст)
  post 'push_attributes', to: 'events#push_attributes'
  get 'push_attributes', to: 'events#push_attributes'

  resource :import, only: :none do
    post :orders
    post :items
    post :insales
    post :yml
    post :disable
    post :audience
    get :disable
  end

  resource :mailer, only: :none do
    post :digest # Сделали API расчета рассылок лля OnlineTours
  end

  resources :digest_mailings, only: [] do
    post :launch,   on: :member # Запуск дайджеста
  end

  # Окно сбора e-mail
  resources :subscriptions, only: [:create] do
    collection do
      get :unsubscribe # Отписаться
      get :bounce # ?
    end
  end

  # Картинка трекинга писем
  get 'track/:type/:code.png', to: 'subscriptions#track', as: 'track_mail'

  # iBeacons
  get 'geo/notify', to: 'beacons#notify'
  get 'geo/track',  to: 'beacons#track'
end
