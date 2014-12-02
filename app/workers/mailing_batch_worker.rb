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
          mailing_batch = DigestMailingBatch.find(params['batch_id'])
          shop.audiences.includes(:user).enabled.where(id: mailing_batch.current_processed_id.value.to_i..mailing_batch.end_id).each do |audience|
            mailing_batch.current_processed_id = audience.id
            audience.try_to_attach_to_user!
            recommendations = calculator.recommendations_for(audience.user)
            send_mail(audience.email, mailing.subject, mailing_setting.sender, body_for_sent(recommendations, mailing.item_template, mailing.template, audience.custom_attributes))
            mailing.sent_mails_count.increment
          end
          mailing_batch.update_attributes(completed: true)
        else
          recommendations = calculator.recommendations_for(nil)
          send_mail(test_mail, mailing.subject, mailing_setting.sender, body_for_sent(recommendations, mailing.item_template, mailing.template))
        end
      end
    end
  rescue => e
    mailing = DigestMailing.find(params['mailing_id'])
    mailing.fail_mailing! if mailing.processing?
    Rollbar.report_exception(e)
  end

  def send_mail(to, subject, from, body)
    Mailer.digest(
      email: to,
      subject: subject,
      send_from: from,
      body: body
    ).deliver
  end

  def body_for_sent(recommendations, item_template, body_template, user_attributes = {})
    items = replace_items_to_template(recommendations, item_template)
    body = body_template.dup
    items.each { |item_str| body.sub!(/\{\{ item \}\}/, item_str) }
    user_replacements = []
    user_attributes.each_pair { |key, value| user_replacements << [Regexp.new("\{\{ #{key} \}\}"), value] if key.present? && value.present? }
    user_replacements.each {|replacement| body = body.gsub(replacement[0], replacement[1])}
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
      ],
      [
        /\{\{ price \}\}/,
        :price
      ],
      [
        /\{\{ image_url \}\}/,
        :image_url
      ]
    ]
    recommendations.each do |item|
      tmp = template
      item_replacements.each {|replacement| tmp = tmp.gsub(replacement[0], item.send(replacement[1]).to_s)}
      items << tmp
    end
    items
  end
end
