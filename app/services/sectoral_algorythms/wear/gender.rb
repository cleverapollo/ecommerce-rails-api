module SectoralAlgorythms
  module Wear
    class Gender
      def self.calculate_for(user, params = {})
        shop = params.fetch(:shop)
        current_item = params[:current_item]

        if current_item.present? && current_item.custom_attributes['gender'].present?
          return current_item.custom_attributes['gender']
        end

        results = { 'f' => 0, 'm' => 0 }
        user.actions.includes(:item).map{|a| a.item.custom_attributes['gender'] }.select{|g| g.present? }
                                                      .each{|g| results[g] += 1 }
        result = results.max_by{|_,v| v }.first
        result
      end
    end
  end
end
