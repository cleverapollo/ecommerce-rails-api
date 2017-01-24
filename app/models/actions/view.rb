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

    # @param [ActionPush::Params] params
    def post_process(params)
      super(params)

      if item
        # Если товар входит в список продвижения, то трекаем его событие, если это был клик или покупка
        Promoting::Brand.find_by_item(item, false).each do |brand_campaign_id|
          BrandLogger.track_click brand_campaign_id, params.shop.id, recommended_by
        end
      end

    end


  end
end
