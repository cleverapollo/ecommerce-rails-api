class DigestMailerWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  attr_accessor :shop, :send_from, :subject, :template, :users, :items, :recommendations_limit, :results

  def perform(params)
    @results = {
      total: 0,
      recommendations: 0,
      empty_recommendations: 0,
      no_recommendations: 0
    }
    extract_params(params)
    send_mails
    puts @results.inspect
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
      results[:no_recommendations] += 1
      return [{ 'template' => '<h1>Мы лохи и не нашли рекомендаций</h1>' }]
    else
      mahout_ids = MahoutService.new.user_based(u_s_r.user_id,
                                                shop.id,
                                                nil,
                                                include: items.map{|i| i['internal_id'].to_i },
                                                exclude: [],
                                                limit: recommendations_limit)
      res = items.select{|i| mahout_ids.include?(i['internal_id']) }

      if res.any?
        results[:recommendations] += 1
        return res
      else
        results[:empty_recommendations] += 1
        return [{ 'template' => '<h1>Мы лохи и не нашли рекомендаций</h1>' }]
      end
    end
    results[:total] += 1
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

    @items.map do |i|
      i['internal_id'] = Item.find_by!(uniqid: i.fetch('id'), shop_id: @shop.id).id
    end

    @recommendations_limit = params.fetch('recommendations_limit').to_i
  end
end
