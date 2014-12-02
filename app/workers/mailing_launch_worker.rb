class MailingLaunchWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  attr_reader :shop

  def perform(params)
    fetch_and_authenticate_shop(params.fetch('shop_id'), params.fetch('shop_secret'))
    process_mailing(params.fetch('id'), params.fetch('test_email'))
  end

  def fetch_and_authenticate_shop(uniqid, secret)
    @shop = Shop.find_by!(uniqid: uniqid, secret: secret)
  end

  def process_mailing(mailing_id, test_mail)
    if test_mail.present?
      MailingBatchWorker.perform_async({ shop_id: shop.id, mailing_id: mailing_id }, test_mail)
    else
      mailing = DigestMailing.find(mailing_id)
      if mailing.digest_mailing_batches.any?
        mailing.digest_mailing_batches.incompleted.each do |batch|
          MailingBatchWorker.perform_async(shop_id: shop.id, mailing_id: mailing_id, start_id: batch.current_processed_id, end_id: batch.end_id)
        end
      else
        shop.audiences.enabled.each_batch_with_start_end_id do |start_id, end_id|
          MailingBatchWorker.perform_async(shop_id: shop.id, mailing_id: mailing_id, start_id: start_id, end_id: end_id)
        end
      end
    end
  end
end
