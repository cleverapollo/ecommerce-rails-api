class DigestMailingsController < ApplicationController
  include ShopAuthenticator

  def launch
    MailingLaunchWorker.perform_async(params)
    render nothing: true, status: :ok
  end

  def audience
    MailingAudienceWorker.perform_async(params)
    render nothing: true, status: :ok
  end
end
