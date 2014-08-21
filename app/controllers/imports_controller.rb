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
    YmlParserWorker.perform_async(@shop.id)
    render text: 'OK'
  end
end
