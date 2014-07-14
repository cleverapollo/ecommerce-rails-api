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

        recommendations = recommendations.map do |item|
          item.url = "http://hipclub.ru/index/autosignin?code=#{user['id']}&key=#{user['token']}"

          item_redirect_path = "sales%2Fview%2Fid%2F#{item.uniqid.split('travel').last}"
          item_redirect_path += "%3Futm_content%3D14.07.2014"
          item_redirect_path += "%26utm_source%3Drees46_test"
          item_redirect_path += "%26recommended_by%3D#{item.mail_recommended_by}"

          item.url += "&redirect_path=#{item_redirect_path}"

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
      unsubscribe_url = UrlHelper.add_param(unsubscribe_url, utm_content: '24.06.2014')
      unsubscribe_url = UrlHelper.add_param(unsubscribe_url, utm_source: 'rees46_test')
    end

    template_for_user = template_for_user.gsub('{{unsubscribe_url}}', unsubscribe_url) if unsubscribe_url.present?

    recommendations.to_a.each_with_index do |item, i|
      template_for_user = template_for_user.gsub("{{item[#{i}].name}}", item.name.to_s)
      template_for_user = template_for_user.gsub("{{code}}", user['id'])
      template_for_user = template_for_user.gsub("{{token}}", user['token'])
      template_for_user = template_for_user.gsub("{{item[#{i}].url}}", item.url.to_s)
      template_for_user = template_for_user.gsub("{{item[#{i}].image_url}}", item.image_url.to_s)
      template_for_user = template_for_user.gsub("{{item[#{i}].price}}", StringHelper.format_money(item.price))
      template_for_user = template_for_user.gsub("{{utm_params_encoded}}", "%3Futm_content%3D14.07.2014%26utm_source%3Drees46_test%26recommended_by%3Ddefault_offer")
    end

    template_for_user
  end

  def recommendations_for(user_id)
    user = UserShopRelation.find_by(shop_id: shop.id, uniqid: user_id).try(:user)
    user ||= User.new

    @recommendations_retriever.for(user)
  end
end
