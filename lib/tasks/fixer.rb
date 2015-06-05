class Fixer
  def process
    fixing_shop = Shop.find(356)

    # получить товары, которые начинаются с буквы
    fixing_shop.items.where('uniqid ~* ?', '\D+\d+').find_each do |item|
      # Получить новый ид товара, который ему соответствует
      right_id = item.uniqid.gsub(/\D+/, '')
      new_item = Item.where(shop: fixing_shop.id, uniquid: right_id)

      # Заменяем историю
      Action.where(item: item).find_each do |action|
        break if Action.where(item: new_item, user: action.user)
        action.update(item: new_item)
      end

      [Interaction, MahoutAction, OrderItem].each do |refresh_class|
        puts 'Update '+refresh_class.inspect
        refresh_class.where(item: item.id).find_each do |entity|
          puts 'Update Entity '+entity.inspect
          entity.update(item: new_item)
        end
      end
    end
  end
end