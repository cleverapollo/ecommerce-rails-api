class MailingBatchWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  def perform(shop_id, mailing_id, start_id, end_id)
    shop = Shop.find(shop_id)
    mailing = DigestMailing.find(mailing_id)
    mailing_setting = shop.digest_mailing_setting
    if mailing_setting.on?
      recommendations_count = mailing.template.scan(/\{\{ item \}\}/).size
      DigestMailingRecommendationsCalculator.create(shop, recommendations_count) do |calculator|
        shop.audiences.enabled.where(id: start_id..end_id).each do |audience|
          audience.try_to_attach_to_user!
          recommendations = calculator.recommendations_for(audience.user)
          items = replace_items_to_template(recommendations, mailing.item_template)
          body = mailing.template.dup
          items.each do |item_str|
            body.sub!(/\{\{ item \}\}/, item_str)
          end
          Mailer.digest(
            email: audience.email,
            subject: mailing.subject,
            send_from: mailing_setting.sender,
            body: body
          ).deliver
          ActiveRecord::Base.connection.execute("UPDATE digest_mailings SET was_sent = was_sent + 1 WHERE id = #{mailing.id}")
        end
      end
    end
  end

  def replace_items_to_template(recommendations, template)
    items = []
    item_replacements = [
      [
        /\{\{ name \}\}/,
        :name
      ],
      [
        /\{\{ url \}\}/,
        :url
      ]
    ]
    recommendations.each do |item|
      tmp = template
      item_replacements.each {|replacement| tmp = tmp.gsub(replacement[0], item.send(replacement[1]))}
      items << tmp
    end
    items
  end
end
