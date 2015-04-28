##
# Рекомендер, который просто что-то возвращает - без махаута
#
module Recommender
  class Raw < Base
    def recommended_ids
      raise NotImplementedError.new('This should be implemented in concrete recommender class')
    end
  end
end
