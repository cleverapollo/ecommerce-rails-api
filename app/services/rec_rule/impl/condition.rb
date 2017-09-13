class RecRule::Impl::Condition < RecRule::Base

  # Результат вычисления
  # @return [Boolean]
  attr_accessor :result

  # Разбивает условие по различным типам
  def execute
    case rule.condition

      when 'cart'
        execute_cart

      when 'user'
        execute_user

      when 'item_category'
        execute_item_category

      when 'item_brand'
        execute_item_brand

      when 'category'
        execute_category

      else
        raise Recommendations::Error.new('Unsupported condition type')
    end
    run
  end

  private

  def check_item!
    raise Recommendations::Error.new('Blank item') if params.item.nil?
  end

  # Запускает процес в зависимости от выполненных условий
  def run
    RecRule::Base.process(params, self.result ? rule.yes : rule.no)
  end

  # Условие, когда товар находится в корзине
  def execute_cart
    check_item!
    self.result = params.cart_item_ids.include?(params.item.id)
  end

  # Условие для проверки юзера
  def execute_user
    self.result = true

    # Проверяем пол
    self.result = params.user.gender == rule.gender if rule.gender.present?

    # Проверяем детей
    if self.result && rule.children.present?

      # Конвертируем в хэши
      rule.children = rule.children.with_indifferent_access

      if params.user.children.present?
        # Изначально добавляем весь массив, далее делаем выборку только по совпадениям
        children = params.user.children.map(&:with_indifferent_access)

        # Если в фильтре указан пол
        children = children.select { |c| c[:gender] == rule.children[:gender] } if rule.children[:gender].present?

        # Если указан возраст
        children = children.select { |c| c[:age_min].to_f >= rule.children[:age_min].to_f && c[:age_max].to_f <= rule.children[:age_max].to_f } if rule.children[:age_min].present?

        # Если что-то осталось
        self.result = children.any?
      else
        self.result = false
        return
      end
    end

    # Проверяем авто
    if self.result && rule.auto_brand.present?
      self.result = params.user.compatibility.present? && params.user.compatibility.select { |c| rule.auto_brand.include?(c['brand']) }.any?
    end
  end

  # Условие для проверки товара в категории
  def execute_item_category
    check_item!
    self.result = params.item.category_ids.present? && (rule.categories & params.item.category_ids).any?
  end

  # Условие для соотношения товара к бренду
  def execute_item_brand
    check_item!
    self.result = params.item.brand_downcase.present? && rule.brands.include?(params.item.brand_downcase)
  end

  # Условие для категории
  def execute_category
    check_item!
    self.result = params.item.category_ids.present? && params.item.category_ids.include?(rule.category_id)
  end

end
