class RecRule::Impl::Recommender < RecRule::Base

  def execute
    RecAlgo::Base.get_implementation_for(rule.recommender).new(params).recommendations
  end

end
