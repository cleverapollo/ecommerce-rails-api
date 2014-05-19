class MailersController < ApplicationController
  before_action :fetch_and_authenticate_shop

  def digest
    DigestMailerWorker.perform_async(params)
  end

  protected

    def fetch_and_authenticate_shop
      @shop = Shop.find_by(uniqid: params[:shop_id], secret: params[:shop_secret])
      if @shop.blank?
        respond_with_client_error('Incorrect shop credentials') and return false
      end
    end
end
