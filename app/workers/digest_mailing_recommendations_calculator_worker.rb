require 'csv'

class DigestMailingRecommendationsCalculatorWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'mailing'

  attr_accessor :shop, :users, :recommendations_count, :recommendations, :csv

  def perform(params)
    self.shop = Shop.find_by(uniqid: params.fetch('shop_id'), secret: params.fetch('shop_secret'))

    self.users = []

    if params.fetch('mode') == 'audiences'
      shop.audiences.active.includes(:user).find_each do |a|
        a.try_to_attach_to_user!
        users << { external_id: a.external_id, user: a.user }
      end
    elsif params.fetch('mode') == 'user_shop_relations'
      shop.user_shop_relations.includes(:user).find_each do |u_s_r|
        users << { external_id: u_s_r.uniqid, user: u_s_r.user }
      end
    end

    self.recommendations_count = params['recommendations_count'] || 10
    self.recommendations = []

    DigestMailingRecommendationsCalculator.open(shop, recommendations_count) do |calculator|
      users.each do |user|
        recommended_ids = calculator.recommendations_for(user[:user]).map(&:uniqid).join(';')

        recommendations << [user[:external_id], recommended_ids]
      end
    end

    self.csv = CSV.generate do |csv|
      csv << ['user_id', 'recommendations']

      recommendations.each do |r|
        csv << r
      end
    end

    Mailer.recommendations({ email: params.fetch('email'), recommendations: csv}).deliver
  end
end
