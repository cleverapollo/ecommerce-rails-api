class ImportsController < ApplicationController
  def orders
    OrdersImportWorker.perform_async(params)
    render text: 'OK'
  end
end
