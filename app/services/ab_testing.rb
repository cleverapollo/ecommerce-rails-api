class AbTesting
  class << self
    def give_recommendations?(shop, user)
      if shop.ab_testing?
        user.ab_testing_group == 2
      else
        true
      end
    end
  end
end
