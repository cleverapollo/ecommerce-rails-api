class MailingsController < ApplicationController
  include ShopAuthenticator

  def create
    @mailing = Mailing.create! \
      shop: @shop,
      send_from: params.fetch(:send_from),
      subject: params.fetch(:subject),
      template: params.fetch(:template),
      items: params[:items] || [],
      business_rules: params[:business_rules] || [],
      recommendations_limit: params[:recommendations_limit] || 0

    render text: @mailing.token
  end

  def perform
    @mailing = Mailing.find_by!(token: params[:id])

    @mailing_batch = @mailing.mailing_batches.create!(users: params.fetch(:users))

    #MailingBatchWorker.perform_async(@mailing_batch.id)
    MailingBatchWorker.new.perform(@mailing_batch.id)
  #rescue ActiveRecord::RecordNotFound => e
    #respond_with_client_error('Mailing not found')
  end
end
