class UserMergerInShopWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  def perform(shop_id)
    shop = Shop.find(shop_id)

    Client.where(shop_id: shop.id).where('email IS NOT NULL AND (digests_enabled = true)').select(:email).group(:email).having('COUNT(*) > 1').each do |client_email|
      while 1 < Client.where(shop_id: shop.id, email: client_email.email).count  do
        client = Client.order(id: :desc).find_by(shop_id: shop.id, email: client_email.email)
        UserMerger.merge_by_mail(shop, client, client_email.email)
      end
    end
  end
end
