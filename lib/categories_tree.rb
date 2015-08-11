class CategoriesTree
  def initialize(shop)
    @shop = shop
    @categories_array = []
    @categories_tree = { }
    @categories_info = {}
  end

  def <<(category)
    @categories_array << category
  end

  def [](key)
    build! unless built?
    (@categories_tree[key] || []).flatten
  end

  def info(id)
    build! unless built?
    @categories_info[id]
  end

  private

  def build!
    shop_items_categories_cache = {}
    @shop.item_categories.find_each do |item_category|
      shop_items_categories_cache[item_category.external_id] = item_category
    end

    category_db_ids = {}
    changed_categories = {}
    @categories_array.each do |category_yml|
      category = shop_items_categories_cache[category_yml[:id].to_s] || @shop.item_categories.new(external_id: category_yml[:id].to_s)
      category.parent_external_id = category_yml[:parent_id].to_s
      category.name = category_yml[:name]
      begin
        category_db_ids[category_yml[:id]]=category.id
        changed_categories[category_yml[:id]] = true
        if category.changed?
          category.save!
        end
      rescue ActiveRecord::RecordNotUnique
      end
    end

    # Прогоняем повторно, чтобы убедиться что все категории сохранены в базе
    # и сохранить parent_id
    @categories_array.each do |category_yml|
      if category_yml[:parent_id] && category_db_ids[category_yml[:id]].present? && changed_categories[category_yml[:id]]
        ItemCategory.update(category_db_ids[category_yml[:id]], parent_id: category_db_ids[category_yml[:parent_id]])
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

    # Заполняем хеш для быстрого получения информации по id
    @categories_info = @categories_array.map {|category_info| [category_info[:id], category_info]}.to_h
  end



  def built?
    @categories_tree.any?
  end
end
