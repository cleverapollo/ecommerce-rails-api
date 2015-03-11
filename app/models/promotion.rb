class Promotion < ActiveRecord::Base
  def show?(params = {})
    shop = params.fetch(:shop)
    if params[:categories].present?
      params[:categories].each do |category_id|
        if c = shop.item_categories.find_by(external_id: category_id)
          return true if show_for_category?(c)
        end
      end
    end

    if params[:item].present?
      params[:item].categories.each do |item_category|
        if c = shop.item_categories.find_by(external_id: item_category)
          return true if show_for_category?(c)
        end
      end
    end

    false
  end

  def show_for_category?(category)
    self.categories.each do |c|
      if category.name.mb_chars.downcase.to_s.include?(c.mb_chars.downcase.to_s)
        return true
      end
    end
    false
  end

  def scope(relation)
    relation.merge(Item.where("name ILIKE '%#{brand}%'"))
  end
end
