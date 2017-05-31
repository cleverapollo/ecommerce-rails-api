class ImportsController < ApplicationController
  # Поиск и проверка магазина
  include ShopAuthenticator

  def orders
    OrdersImportWorker.perform_async(params)
    render text: 'OK'
  end

  # Запускает sidekiq воркер в работу
  # Используется для передачи информации от мастера
  def job_worker

    # Проверяем код
    if params[:code].blank? || params[:code] != 'KJhsd872Hj&^%3lkjJs'
      render nothing: true, status: 401
      return
    end

    worker_class = params[:job_data][:class].constantize rescue nil
    if !worker_class.nil?
      # Запускаем класс в работу
      worker_class.perform_async *params[:job_data][:args]
      render nothing: true
    else
      render nothing: true, status: 404
    end
  end

  def sync_orders
    # if %w(e143c34a52e7463665fb89296faa75).include?(@shop.uniqid)
    #   # render text: 'Disabled', status: 400
    #   # return
    #   if Rails.env.production?
    #     notifier = Slack::Notifier.new Rails.application.secrets.slack_notify_key, username: "Realboxing", http_options: { open_timeout: 1 }
    #     notifier.ping("Sync orders")
    #   end
    # end
    OrdersSyncWorker.perform_async(params)
    render text: 'OK'
  end

  def items
    ItemsImportWorker.perform_async(@shop.id, params[:items])
    render text: 'OK'
  end

  def insales
    InsalesWorker.perform_async(@shop.id)
    render text: 'OK'
  end

  def yml
    @shop.async_yml_import(true)
    render text: 'OK'
  end

  def audience
    AudienceImportWorker.perform_async(params)
    render text: 'OK'
  end

  def user_info
    UserInfoImportWorker.perform_async(params)
    render text: 'OK'
  end

  def disable
    if params[:item_ids].present?
      params[:item_ids].to_s.split(',').each do |item_id|
        @shop.items.find_by(uniqid: item_id).try(:disable!)
      end
    end

    render text: 'OK'
  end

  # Загрузка категорий
  def categories
    if params[:categories].blank?
      respond_with_client_error('Categories can\'t be blank') and return false
    end
    unless params[:categories].is_a?(Array)
      respond_with_client_error('Categories must be array') and return false
    end

    CategoriesImportWorker.perform_async(@shop.id, params[:categories])
    render nothing: true, status: 204
  end

  # Загрузка городов
  def locations
    if params[:locations].blank?
      respond_with_client_error('Locations can\'t be blank') and return false
    end
    unless params[:locations].is_a?(Array)
      respond_with_client_error('Locations must be array') and return false
    end

    LocationsImportWorker.perform_async(@shop.id, params[:locations])
    render nothing: true, status: 204
  end


  # Заглушка для импорта товаров через HTTP
  # Тесты тоже есть.
  def products

    if params[:items].blank?
      respond_with_client_error('Items can\'t be blank') and return false
    end
    unless params[:items].is_a?(Array)
      respond_with_client_error('Items must be array') and return false
    end

    # Добавляем статус
    @shop.update(yml_state: 'queue')

    ItemsImportWorker.perform_async(@shop.id, params[:items], request.method_symbol)
    render nothing: true, status: 204
  end


  def images
    ImageDownloadLaunchWorker.perform_async(@shop.id, nil, true)
    render text: 'OK'
  end
end
