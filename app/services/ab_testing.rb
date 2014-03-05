class AbTesting
  class << self
    def give_recommendations?(shop, user)
      !shop.ab_testing? or (shop.ab_testing? and user.ab_testing_group == 2)
    end
  end
end
