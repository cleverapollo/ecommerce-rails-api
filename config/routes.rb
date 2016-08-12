Rees46Api::Application.routes.draw do

  root to: 'home#index'

  # Инициализация
  get 'init_script', to: 'init#init_script'


  # Генерация кода сессии - используется мобильными приложениями
  get 'generate_ssid', to: 'init#generate_ssid'

  # Проверка валидности shop_id и shop_secret
  get 'check', to: 'init#check'

  # Запрос рекомендаций
  get 'recommend', to: 'recommendations#get'
  post 'recommendations/batch'

  # Отправка событий
  post 'push', to: 'events#push'
  get 'push', to: 'events#push'

  # В будущих отраслевых алгоритмах сохраняет текущие выбранные фильтры (контекст)
  post 'push_attributes', to: 'events#push_attributes'
  get 'push_attributes', to: 'events#push_attributes'

  get 'triggers/trigger_content'
  get 'triggers/additional_content'

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

  resources :trigger_mailings, only: [] do
    collection do
      post :send_test
    end
  end


  # Дайджестные веб пуши
  resources :web_push_digests, only: [] do
    member do
      post :launch
    end
  end

  resources :web_push_triggers, only: [] do
    member do
      post :send_test
    end
  end


  # Окно сбора e-mail
  # create - прием данных о подписке (или отказе)
  resources :subscriptions, only: [:create] do
    collection do
      # Отписаться
      get :unsubscribe
      post :subscribe_for_product_price
      post :subscribe_for_product_available
    end
  end

  # Окно подписок на нотификации
  # create - прием данных о подписке
  resources :web_push_subscriptions, only: [:create] do
    collection do
      # Отписаться
      post :unsubscribe
      # Отказался от подписки
      post :decline
      # Отправить тестовое сообщение
      get :send_test
    end
  end

  # Картинка трекинга писем
  get 'track/:type/:code.png', to: 'subscriptions#track', as: 'track_mail'

  # iBeacons
  get 'geo/notify', to: 'beacons#notify'
  get 'geo/track',  to: 'beacons#track'


end
