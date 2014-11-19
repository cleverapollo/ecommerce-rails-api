class MailingAudienceWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  attr_reader :shop

  def perform(params)
    fetch_and_authenticate_shop(params.fetch('shop_id'), params.fetch('shop_secret'))
    process_audience(params.fetch('audience'))
  end

  def fetch_and_authenticate_shop(uniqid, secret)
    @shop = Shop.find_by!(uniqid: uniqid, secret: secret)
  end

  def process_audience(audiences)
    audiences.each do |audience_param|
      audience = Audience.find_or_initialize_by(external_id: audience_param.fetch('id'), shop_id: shop.id)
      audience.email = audience_param.fetch('email')
      audience.enabled = audience_param.fetch('enabled')
      audience.custom_attributes = audience_param.except('id', 'email', 'enabled')
      audience.save
    end
  end
end
