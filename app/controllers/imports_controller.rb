class ImportsController < ApplicationController
  def orders
    OrdersImportWorker.perform_async(params)
    render text: 'OK'
  end

  def items
    ItemsImportWorker.perform_async(params)
    render text: 'OK'
  end
end
