class RecommenderBlock < ActiveRecord::Base
  belongs_to :shop

  default_scope { where(active: true) }

  # Точка входа в рекоммендеры
  # @param [Hash] params
  # @return [Array]
  def recommends(params)
    return [] if self.paused?
    RecRule::Base.process(RecRule::Params.new(self, params), rules)
  end
end
