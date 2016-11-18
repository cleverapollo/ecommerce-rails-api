class ImportsController < ApplicationController
  # Поиск и проверка магазина
  include ShopAuthenticator

  def orders
    OrdersImportWorker.perform_async(params)
    render text: 'OK'
  end

  def sync_orders
    if %w(e143c34a52e7463665fb89296faa75 c770dac644324b27131424e1ba3d16).include(@shop.uniqid)
      render 'Disabled', status: 400
      return
    end
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
    YmlImporter.perform_async(@shop.id)
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
      params[:item_ids].split(',').each do |item_id|
        @shop.items.find_by(uniqid: item_id).try(:disable!)
      end
    end

    render text: 'OK'
  end
end
