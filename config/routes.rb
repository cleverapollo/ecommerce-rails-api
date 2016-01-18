Rees46Api::Application.routes.draw do

  # For DMP
  get 'profile/check'

  root to: 'home#index'

  # Инициализация
  get 'init_script', to: 'init#init_script'


  # Генерация кода сессии - используется мобильными приложениями
  get 'generate_ssid', to: 'init#generate_ssid'

  # Запрос рекомендаций
  get 'recommend', to: 'recommendations#get'

  # Отправка событий
  post 'push', to: 'events#push'
  get 'push', to: 'events#push'

  # В будущих отраслевых алгоритмах сохраняет текущие выбранные фильтры (контекст)
  post 'push_attributes', to: 'events#push_attributes'
  get 'push_attributes', to: 'events#push_attributes'

  # Импорты
  resource :import, only: :none do
    # Заказы
    post :orders
    # Статусы заказов
    post :sync_orders
    # Товары (вероятно, нигде не используется)
    post :items
    # Инсейлс
    post :insales
    # YML файл
    post :yml
    # Отключение товаров
    post :disable
    get :disable
    # Аудитория рассылок
    post :audience
  end

  # Дайджестные рассылки
  resources :digest_mailings, only: [] do
    member do
      # Запуск рассылки
      post :launch
    end
  end

  # Окно сбора e-mail
  # create - прием данных о подписке (или отказе)
  resources :subscriptions, only: [:create] do
    collection do
      # Отписаться
      get :unsubscribe
    end
  end

  # Картинка трекинга писем
  get 'track/:type/:code.png', to: 'subscriptions#track', as: 'track_mail'

  # iBeacons
  get 'geo/notify', to: 'beacons#notify'
  get 'geo/track',  to: 'beacons#track'

  namespace :media do
    resources :media_actions, only: [:create]
    get '/init_script' => 'init_media#init_script'
    get '/recommend' => 'recommendations#create'
  end
end
