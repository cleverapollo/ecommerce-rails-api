class RecommenderBlock < ActiveRecord::Base
  belongs_to :shop

  default_scope { where(active: true) }

end
