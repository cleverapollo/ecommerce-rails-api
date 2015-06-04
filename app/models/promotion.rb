##
# Продвижение бренда
#
class Promotion < ActiveRecord::Base

  # Показывать продвижение для заданных параметров?
  def show?(params = {})
    shop = params.fetch(:shop)

    categories_to_search = []
    categories_to_search += params[:categories] || []
    categories_to_search += params[:item].categories if params[:item].present?
    categories_to_search.flatten.uniq.each do |category_id|
      if c = shop.item_categories.find_by(external_id: category_id)
        if show_for_category?(c)
          @category = category_id
          return true
        end
      end
    end

    false
  end

  def in_name?(item_name)
    !item_name.match(/\b#{brand}\b/i).nil?
  end

  # Наложить условие продвижения
  def scope(relation)
    r = Item.where(brand: brand)
    r = r.in_categories([@category]) if @category.present?
    relation.merge(r)
  end

  def get_from_selection(item_ids)
    scope(Item.where(id:item_ids)).limit(1).first.try(:id)
  end

  private

  def show_for_category?(category)
    self.categories.each do |c|
      if category.name.mb_chars.downcase.to_s.include?(c.mb_chars.downcase.to_s)
        return true
      end
    end
    false
  end
end
