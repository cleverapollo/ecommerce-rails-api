class RecRule::Impl::Condition < RecRule::Base

  CONDITION_TYPES = %w(cart)

  def check_params!
    super
    raise Recommendations::Error.new('Blank item') if params.item.blank?
    raise Recommendations::Error.new('Unsupported condition type') unless CONDITION_TYPES.include?(rule.condition)
  end

  def execute
    case rule.condition
      when 'cart'
        execute_cart
    end
  end

  private

  # Условие, когда товар находится в корзине
  def execute_cart
    RecRule::Base.process(params, params.cart_item_ids.include?(params.item.id) ? rule.yes : rule.no)
  end

end
