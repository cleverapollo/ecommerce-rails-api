##
# Просмотр товара
#
module Actions
  class View < Action
    CODE = 1
    RATING = 3.2

    def update_rating_and_last_action(rating)
      self.last_action = CODE
      self.rating = RATING
    end

    def update_concrete_action_attrs
      self.view_count += 1
      self.view_date = Time.current
    end

    def needs_to_update_rating?
      self.last_action == CODE
    end
  end
end
