Rees46Api::Application.routes.draw do

  root to: 'home#index'

  # Инициализация
  get 'init_script', to: 'init#init_script'


  # Генерация кода сессии - используется мобильными приложениями
  get 'generate_ssid', to: 'init#generate_ssid'

  # Проверка валидности shop_id и shop_secret
  get 'check', to: 'init#check'

  # Получение shop_secret
  get 'shop/secret', to: 'init#secret'

  # Запрос рекомендаций
  get 'recommend', to: 'recommendations#get'
  post 'recommendations/batch'

  # Поиск
  get 'search', to: 'search#get'
  get 'search/collection', to: 'search#collection'

  # Товары
  get 'products/get'
  patch 'products/set_not_widgetable'

  # Отправка событий
  post 'push', to: 'events#push'
  get 'push', to: 'events#push'
  post 'recone', to: 'events#recone'

  # В будущих отраслевых алгоритмах сохраняет текущие выбранные фильтры (контекст)
  post 'push_attributes', to: 'events#push_attributes'
  get 'push_attributes', to: 'events#push_attributes'

  get 'triggers/trigger_content'
  get 'triggers/additional_content'

  # Запрос отзывов
  get 'reputation/shop', to: 'reputations#shop_reputation'
  get 'reputation/product', to: 'reputations#item_reputation'
  get 'reputation/widget', to: 'reputations#reputation_widget'

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
    # Удалить старые и загрузить новыие картинки товаров
    post :images
    # Загрузка городов
    post :locations
    # Загрузка категорий
    post :categories

    post :job_worker

    # Импорт товаров через HTTP API
    post :products
    put :products
    delete :products

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
      # Подписаться
      get :subscribe
      post :subscribe_for_product_price
      post :subscribe_for_product_available
      post :showed
    end
  end

  # Окно подписок на нотификации
  # create - прием данных о подписке
  resources :web_push_subscriptions, only: [:create] do
    collection do
      post :showed
      # Отметка о получении сообщения
      post :received
      post :clicked
      # Отказался от подписки
      post :decline
      # Отправить тестовое сообщение
      get :send_test

      post :safari_webpush
      # post 'safari_webpush/*type', to: 'web_push_subscriptions#safari_webpush'

      delete :safari_webpush, to: 'web_push_subscriptions#delete_safari_webpush'
    end
  end

  # Картинка трекинга писем
  get 'track/:type/:code.png', to: 'subscriptions#track', as: 'track_mail'

end
