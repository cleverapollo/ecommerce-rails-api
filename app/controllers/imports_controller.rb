class ImportsController < ApplicationController
  # Поиск и проверка магазина
  include ShopAuthenticator

  def orders
    OrdersImportWorker.perform_async(params)
    render text: 'OK'
  end

  def sync_orders
    OrdersSyncWorker.perform(params)
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
    YmlWorker.perform_async(@shop.id)
    render text: 'OK'
  end

  def audience
    AudienceImportWorker.perform_async(params)
    render text: 'OK'
  end

  def disable
    if params[:item_ids].present?
      params[:item_ids].split(',').each do |item_id|
        @shop.items.find_by(uniqid: item_id).try(:disable!)
      end
    end

    render text: 'OK'
  end
end
