class RecommenderBlock < ActiveRecord::Base
  belongs_to :shop

  default_scope { where(active: true) }

  # Точка входа в рекоммендеры
  # @param [Hash] params
  # @return [Array]
  def recommends(params, seance = nil)
    return [] if self.paused?
    rec_rule_params = RecRule::Params.new(self, params)
    result = RecRule::Base.process(rec_rule_params, rules)
    Actions::Tracker.track_recommender_block_request(rec_rule_params.session.id, self.shop_id, seance, self.id, result)
    result
  end
end
