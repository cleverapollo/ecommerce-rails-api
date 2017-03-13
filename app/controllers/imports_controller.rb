class ImportsController < ApplicationController
  # Поиск и проверка магазина
  include ShopAuthenticator

  def orders
    OrdersImportWorker.perform_async(params)
    render text: 'OK'
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
    ItemsImportWorker.perform_async(params)
    render text: 'OK'
  end

  def insales
    InsalesWorker.perform_async(@shop.id)
    render text: 'OK'
  end

  def yml
    YmlImporter.perform_async(@shop.id, true)
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


  # Заглушка для импорта товаров через HTTP
  # Тесты тоже есть.
  def products
    render nothing: true, status: 204
  end


  def images
    ImageDownloadLaunchWorker.perform_async(@shop.id, nil, true)
    render text: 'OK'
  end
end
