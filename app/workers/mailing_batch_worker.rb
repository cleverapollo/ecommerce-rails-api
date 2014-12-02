class MailingBatchWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  def perform(params, test_mail = nil)
    shop = Shop.find(params['shop_id'])
    mailing = DigestMailing.find(params['mailing_id'])
    mailing_setting = shop.digest_mailing_setting
    if mailing_setting.on?
      recommendations_count = mailing.template.scan(/\{\{ item \}\}/).size
      DigestMailingRecommendationsCalculator.create(shop, recommendations_count) do |calculator|
        if test_mail.nil?
          shop.audiences.enabled.where(id: params['start_id']..params['end_id']).each do |audience|
            audience.try_to_attach_to_user!
            recommendations = calculator.recommendations_for(audience.user)
            sent_mail(audience.email, mailing.subject, mailing_setting.sender, body_for_sent(recommendations, mailing.item_template, mailing.template))
            ActiveRecord::Base.connection.execute("UPDATE digest_mailings SET was_sent = was_sent + 1 WHERE id = #{mailing.id}")
          end
        else
          recommendations = calculator.recommendations_for(nil)
          sent_mail(test_mail, mailing.subject, mailing_setting.sender, body_for_sent(recommendations, mailing.item_template, mailing.template))
        end
      end
    end
  end

  def sent_mail(to, subject, from, body)
    Mailer.digest(
      email: to,
      subject: subject,
      send_from: from,
      body: body
    ).deliver
  end

  def body_for_sent(recommendations, item_template, body_template)
    items = replace_items_to_template(recommendations, item_template)
    body = body_template.dup
    items.each { |item_str| body.sub!(/\{\{ item \}\}/, item_str) }
    body
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
