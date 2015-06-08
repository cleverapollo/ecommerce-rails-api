class CategoriesTree
  def initialize(shop)
    @shop = shop
    @categories_array = []
    @categories_tree = { }
  end

  def <<(category)
    @categories_array << category
  end

  def [](key)
    build! unless built?
    (@categories_tree[key] || []).flatten
  end

  private

  def build!
    shop_items_categories_cache = {}
    @shop.item_categories.find_each do |item_category|
      shop_items_categories_cache[item_category.external_id] = item_category
    end

    category_db_ids = {}
    @categories_array.each do |category_yml|
      category = shop_items_categories_cache[category_yml[:id].to_s] || @shop.item_categories.new(external_id: category_yml[:id].to_s)
      category.parent_external_id = category_yml[:parent_id].to_s
      category.name = category_yml[:name]
      begin
        if category.changed?
          category.save!
          category_db_ids[category_yml[:id]]=category.id
        end
      rescue ActiveRecord::RecordNotUnique
      end
    end

    # Прогоняем повторно, чтобы убедиться что все категории сохранены в базе
    # и сохранить parent_id
    @categories_array.each do |category_yml|
      if category_yml[:parent_id]
        ItemCategory.find(category_db_ids[category_yml[:id]]).update(parent_id: category_db_ids[category_yml[:parent_id]])
      end
    end

    # Каждому ключу (ID категории) соответствует полный массив категорий: она сама + все родительские
    loop do
      break unless @categories_array.select{|c| c[:processed] != true }.any?

      @categories_array.each do |c_y|
        next if c_y[:processed] == true
        if c_y[:parent_id].blank?
          # Корневая категория
          @categories_tree[c_y[:id]] = [c_y[:id]]
          c_y[:processed] = true
        else
          if @categories_tree[c_y[:parent_id]].present?
            # Родительская категория уже в дереве?
            @categories_tree[c_y[:id]] = [c_y[:id]] + @categories_tree[c_y[:parent_id]]
            c_y[:processed] = true
          else
            # А может родительской категории не существует?
            if @categories_array.none?{|c| c[:id] == c_y[:parent_id]}
              @categories_tree[c_y[:id]] = [c_y[:id]]
              c_y[:processed] = true
            end
          end
        end
      end
    end

    @categories_tree.each do |k, v|
      v.sort!
    end
  end

  def built?
    @categories_tree.any?
  end
end
