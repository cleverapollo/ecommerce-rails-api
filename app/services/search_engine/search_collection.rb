class SearchEngine::SearchCollection

  attr_accessor :shop, :user, :collection

  def initialize(shop, user, collection)
    self.shop = shop
    self.user = user
    self.collection = collection
  end

  def recommendations

    result = []

    collection.thematic_collection_sections.each do |section|
      if section.rules
        begin

          # Rules can by malformed
          rules = JSON.parse section.rules

        rescue => e
          # Skip broken rules
          next
        end

        # Container for recommended products
        processed_recommendations = []

        # Rules can be an array or single rule
        if rules.is_a? Array

          # Process all rules in array
          rules.each do |rule|
            processed_recommendations << process_rule(rule)
          end
        else
          processed_recommendations << process_rule(rules)
        end

        # Remove nils
        processed_recommendations.flatten!(1).compact!

        # If recommended products, add it to
        if processed_recommendations.any?
          result << {
              name: section.name,
              products: processed_recommendations
          }
        end

      end
    end

    return result

  end


  private

  def process_rule(rule)

    if rule.key?('type')
      if rule['type'] == 'popular' && rule.key?('category')

        params = OpenStruct.new(
            shop: shop,
            user: user,
            limit: rule.key?('limit') ? rule['limit'] : 8,
            recommend_only_widgetable: true,
            extended: true,
            category_ids: rule['category']
        )

        # Find popular products
        recs = Recommender::Impl::Popular.new(params).recommendations

        return recs if recs.any?

      end
    end

    nil
  end

end