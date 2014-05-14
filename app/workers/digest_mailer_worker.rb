class DigestMailerWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  attr_accessor :shop, :send_from, :subject, :template, :users, :items, :recommendations_limit

  def perform(params)
    extract_params(params)
    send_mails
  end

  def send_mails
    @users.each do |user_raw|
      user_id = user_raw.fetch('id').to_s
      user_email = user_raw.fetch('email')
      user_name = user_raw['name']
      user_unsubscribe_url = user_raw['unsubscribe_url']

      recommended_items = recommended_items_for user_id

      recommended_items_html = recommended_items.map{|i| i.fetch('template') }.join()

      template_for_user = template.gsub('{{name}}', user_name) if user_name.present?
      template_for_user = template_for_user.gsub('{{recommendations}}', recommended_items_html)
      template_for_user = template_for_user.gsub('{{unsubscribe_url}}', user_unsubscribe_url) if user_unsubscribe_url.present?

      Mailer.digest(
        email: user_email,
        subject: subject,
        send_from: send_from,
        body: template_for_user
      ).deliver
    end
  end

  def recommended_items_for(user_id)
    u_s_r = UserShopRelation.find_by(shop_id: shop.id, uniqid: user_id)

    if u_s_r.nil?
      items.sample(recommendations_limit)
    else
      # Mahout
      items.sample(recommendations_limit)
    end
  end

  def extract_params(params)
    @shop = Shop.find_by!(uniqid: params.fetch('shop_id'), secret: params.fetch('shop_secret'))

    @send_from = params.fetch('send_from')

    @subject = params.fetch('subject')

    @template = params.fetch('template')

    @users = params.fetch('users')
    raise ArgumentError.new('Users must be an array') if @users.none?

    @items = params.fetch('items')
    raise ArgumentError.new('Items must be an array') if @items.none?

    @recommendations_limit = params.fetch('recommendations_limit').to_i
  end
end
