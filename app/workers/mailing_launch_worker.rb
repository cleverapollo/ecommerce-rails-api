class MailingLaunchWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  attr_reader :shop

  def perform(params)
    fetch_and_authenticate_shop(params.fetch('shop_id'), params.fetch('shop_secret'))
    process_mailing(params.fetch('id'))
  end

  def fetch_and_authenticate_shop(uniqid, secret)
    @shop = Shop.find_by!(uniqid: uniqid, secret: secret)
  end

  def process_mailing(mailing_id)
    shop.audiences.enabled.each_batch_with_start_end_id do |start_id, end_id|
      MailingBatchWorker.perform_async(shop.id, mailing_id, start_id, end_id)
    end
  end
end
