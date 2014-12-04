class ImportsController < ApplicationController
  include ShopAuthenticator

  def orders
    OrdersImportWorker.perform_async(params)
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

  def disable
    params[:item_ids].each do |item_id|
      @shop.items.find_by(uniqid: item_id).update(is_available: false)
    end

    render text: 'OK'
  end
end
