class ItemCollector

  attr_reader :shop, :item_category

  def initialize(shop_id, item_category_external_id)
    @shop = Shop.find(shop_id)
    @item_category = ItemCategory.find_by(shop_id: shop_id, external_id: item_category_external_id)
  end

  def collect
    result = { categories: [], items: [] }
    children_categories = ItemCategory.where(external_id: children_categories_collector(item_category.external_id).flatten, shop_id: shop.id)
    result[:categories] << item_category
    result[:categories] << children_categories
    result[:categories] = result[:categories].flatten

    result[:items] << shop.items.widgetable.where("? = ANY (category_ids)", item_category.external_id)

    children_categories.each do |category|
      result[:items] << shop.items.widgetable.where("? = ANY (category_ids)", category.external_id)
    end
    result[:items] = result[:items].flatten

    file = File.open("category-#{item_category.external_id}.txt", 'w')
    file.write(result.to_json)
    file.close

    file
  end

  private

  def children_categories_collector(parent_id)
    children_ids = ItemCategory.where(parent_external_id: parent_id, shop_id: shop.id).pluck(:external_id)
    children_ids.map { |children_id| children_categories_collector(children_id) } + children_ids
  end
end
