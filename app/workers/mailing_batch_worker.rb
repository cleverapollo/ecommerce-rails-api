class MailingBatchWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  attr_accessor :mailing_batch
  attr_accessor :mailing
  attr_accessor :shop
  attr_accessor :recommendations_retriever

  def perform(mailing_batch_id)
    @mailing_batch = MailingBatch.find(mailing_batch_id)
    begin
      @mailing_batch.process!

      prepare_attrs

      process_users

      @mailing_batch.finish!
    rescue StandardError => e
      @mailing_batch.fail!
      raise e
    end
    @mailing_batch.save
    ActionMailer::Base.deliveries = []
  end

  def prepare_attrs
    @mailing = @mailing_batch.mailing
    @shop = @mailing_batch.mailing.shop
    item_ids = Item.where(shop_id: @shop.id, uniqid: @mailing.items).pluck(:id)
    @recommendations_retriever = RecommendationsRetriever.new(shop, 15, item_ids)
  end

  def process_users
    mailing_batch.users.each do |user|
      mailing_batch.statistics[:total] += 1
      begin
        id = user.fetch('id')
        email = user.fetch('email')

        recommendations = recommendations_for(id)

        mailing.business_rules.map do |business_rule|
          item = Item.find(business_rule['internal_id'])
          item.url = UrlHelper.add_param(item.url, utm_source: 'rees46')
          item.url = UrlHelper.add_param(item.url, utm_meta: 'email_digest')
          item.url = UrlHelper.add_param(item.url, utm_campaign: 'business_rule')
          item
        end.each do |business_rule|
          recommendations.unshift(business_rule)
        end

        recommendations = recommendations.map do |item|
          item.url = 'http://hipclub.ru/index/autosignin?code=1800403'
          item.url = UrlHelper.add_param(item.url, key: user['token'])
          item_redirect_url = "sales/view/id/#{item.uniqid.split('travel').last}"
          item.url = UrlHelper.add_param(item.url, redirect_path: item_redirect_url)
          item.url = UrlHelper.add_param(item.url, utm_term: 'foo')
          item.url = UrlHelper.add_param(item.url, utm_content: '24.06.2014')
          item.url = UrlHelper.add_param(item.url, utm_medium: 'text')
          item.url = UrlHelper.add_param(item.url, utm_source: 'mail_hipclub')
          item
        end

        Mailer.digest(
          email: email,
          subject: mailing.subject,
          send_from: mailing.send_from,
          body: compose_letter(user, recommendations)
        ).deliver
      rescue StandardError => e
        mailing_batch.failed << user
        mailing_batch.statistics[:failed] += 1
        raise e
      end
    end
  end

  def compose_letter(user, recommendations)
    template_for_user = mailing.template

    greeting = if user['name'].present?
      "Здравствуйте, #{user['name']}"
    else
      "Здравствуйте"
    end

    template_for_user = template_for_user.gsub('{{greeting}}', greeting)

    unsubscribe_url = nil
    if user['unsubscribe_url'].present?
      unsubscribe_url = user['unsubscribe_url']
      unsubscribe_url = UrlHelper.add_param(unsubscribe_url, utm_source: 'rees46')
      unsubscribe_url = UrlHelper.add_param(unsubscribe_url, utm_meta: 'email_digest')
      unsubscribe_url = UrlHelper.add_param(unsubscribe_url, utm_campaign: 'unsubscribe')
    end

    template_for_user = template_for_user.gsub('{{unsubscribe_url}}', unsubscribe_url) if unsubscribe_url.present?

    recommendations.to_a.each_with_index do |item, i|
      template_for_user = template_for_user.gsub("{{item[#{i}].name}}", item.name.to_s)
      template_for_user = template_for_user.gsub("{{item[#{i}].url}}", item.url.to_s)
      template_for_user = template_for_user.gsub("{{item[#{i}].image_url}}", item.image_url.to_s)
      template_for_user = template_for_user.gsub("{{item[#{i}].price}}", StringHelper.format_money(item.price))
    end

    template_for_user
  end

  def recommendations_for(user_id)
    user = UserShopRelation.find_by(shop_id: shop.id, uniqid: user_id).try(:user)
    user ||= User.new

    @recommendations_retriever.for(user)
  end
end
