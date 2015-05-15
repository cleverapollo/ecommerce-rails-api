module Recommender
  module SectoralAlgorythms

  # Переопределенный метод из базового класса. Накидываем сверху отраслевые алгоритмы
    def items_to_recommend
      if shop.sectoral_algorythms_available?
        result = super
        if shop.category.wear?
          gender = SectoralAlgorythms::Wear::Gender.calculate_for(user, shop: shop, current_item: item)
          result = result.by_ca(gender: gender)

          # TODO: отбрасывать товары, которые явно не подходят по размеру
        end
        result
      else
        super
      end
    end

  end
end