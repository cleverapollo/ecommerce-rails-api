##
# Оценка (не используется)
#
module Actions
  class Rate < Action
    CODE = 5

    def update_rating_and_last_action(rating)
      self.last_action = CODE
      self.rating = RATING
    end

    def update_concrete_action_attrs
    end

    def needs_to_update_rating?
      true
    end

    def update_rating_and_last_action(rating)
      self.last_action = CODE
      self.rating = rating
      self.last_user_rating = rating
    end
  end
end
