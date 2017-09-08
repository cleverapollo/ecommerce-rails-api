class RecommenderBlock < ActiveRecord::Base
  belongs_to :shop

  default_scope { where(active: true) }

  # Точка входа в рекоммендеры
  # @param [Recommendations::Params] params
  # @return [Array]
  def recommends(params)
    params.limit = limit
    RecRule::Base.process(params, rules)
  end
end
