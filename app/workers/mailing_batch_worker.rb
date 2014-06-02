class MailingBatchWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  attr_accessor :mailing_batch
  attr_accessor :mailing
  attr_accessor :shop
  attr_accessor :items_internal_ids
  attr_accessor :mahout_service

  def perform(mailing_batch_id)
    @mailing_batch = MailingBatch.find(mailing_batch_id)
    begin
      @mailing_batch.process!

      prepare_attrs

      process_users

      @mahout_service.close
      @mailing_batch.finish!
    rescue StandardError => e
      @mailing_batch.fail!
      raise e
    end
    @mailing_batch.save
  end

  def prepare_attrs
    @mailing = @mailing_batch.mailing
    @shop = @mailing_batch.mailing.shop
    @mahout_service = MahoutService.new

    begin
      Timeout::timeout(5) {
        @mahout_service.open
      }
    rescue Timeout::Error => e
      retry
    end

    @items_internal_ids = @mailing_batch.mailing.items.map{|i| i['internal_id'] }.compact
  end

  def process_users
    mailing_batch.users.each do |user|
      mailing_batch.statistics[:total] += 1
      begin
        id = user.fetch('id')
        email = user.fetch('email')
        additional_params = user['additional_params']

        recommendations = recommendations_for(id)

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
    recommendations_template = recommendations.map{|i| i.fetch('template') }.join()

    template_for_user = mailing.template
    template_for_user = template_for_user.gsub('{{name}}', user['name']) if user['name'].present?
    template_for_user = template_for_user.gsub('{{recommendations}}', recommendations_template)
    template_for_user
  end

  def recommendations_for(user_id)
    u_s_r = UserShopRelation.find_by(shop_id: shop.id, uniqid: user_id)

    result = []

    if u_s_r.present?
      mahout_ids = []

      begin
        Timeout::timeout(5) {
          mahout_ids = @mahout_service.user_based(u_s_r.user_id, shop.id, nil,
            include: items_internal_ids,
            exclude: Recommender::Base.exclude_in_recommendations(user_id, shop.id),
            limit: mailing.recommendations_limit.to_i
          )
        }
      rescue Timeout::Error => e
        retry
      end

      if mahout_ids.any?
        mailing_batch.statistics[:with_recommendations] += 1
        result = mailing_batch.mailing.items.select{|i| mahout_ids.include?(i['internal_id']) }
      else
        mailing_batch.statistics[:no_recommendations] += 1
        result = default_recommendations
      end
    else
      mailing_batch.statistics[:no_recommendations] += 1
      result = default_recommendations
    end
    result
  end

  def default_recommendations
    []
  end
end






















