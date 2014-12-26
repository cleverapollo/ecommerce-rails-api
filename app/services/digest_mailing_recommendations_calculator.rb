##
# Класс, расчитывающий рекомендации для дайджестной рассылки.
#
class DigestMailingRecommendationsCalculator
  class UnexpectedRecommendationsCountError < StandardError; end

  attr_reader :mahout_service

  class << self
    # Открыть калькулятор. В метод передается блок, которому будет передан объект калькулятора.
    #
    # @param shop [Shop] магазин.
    # @param limit [Integer] нужное количество рекомендаций.
    def open(shop, limit)
      calculator = new(shop, limit)
      calculator.mahout_service.open
      yield calculator
      calculator.mahout_service.close
    end
  end

  def initialize(shop, limit)
    @shop  = shop
    @limit = limit
    @items_cache = {}
    @mahout_service = MahoutService.new
    @items_in_shop = @shop.items.available.widgetable.pluck(:id)
  end

  # Получить рекомендации для юзера.
  #
  # @param user [User] пользователь, для которого считаем рекомендации. Может быть nil.
  # @return [Array] массив товаров.
  def recommendations_for(user)
    @current_user = user

    # Мы должны быть уверены, что туннель открыт.
    ensure_tunnel_is_opened!

    # Сначала получаем рекомендации "Вам это будет интересно".
    item_ids = interesting_ids

    # Если их недостаточно, то добавляем "Популярных".
    if item_ids.count < @limit
      p = OpenStruct.new(
        shop: @shop,
        user: @current_user,
        limit: @limit - item_ids.count,
        recommend_only_widgetable: true,
        recommender_type: 'popular',
        exclude: item_ids
      )
      p.locations = locations_for_current_user if shop_works_with_locations?
      item_ids += Recommender::Impl::Popular.new(p).recommended_ids
    end

    # Возвращаем массив товаров
    items_of(item_ids)
  end

  private

  def ensure_tunnel_is_opened!
    unless (mahout_service.tunnel && mahout_service.tunnel.active?)
      mahout_service.open
    end
  end

  # Работает ли магазин с локациями, или у него все в одном городе?
  #
  # @return [Boolean] работает ли магазин с локациями.
  def shop_works_with_locations?
    if @shop_works_with_locations.nil?
      @shop_works_with_locations = @shop.items.where.not(locations: '{}').any?
    end
    @shop_works_with_locations
  end

  # Получить доступные локации для текущего пользователя.
  #
  # @return [Array] массив доступных локаций.
  def locations_for_current_user
    if @current_user.present?
      @current_user.actions.where(shop_id: @shop.id).map(&:item).map(&:locations).select do |l|
        l.present? && l != []
      end.first || []
    else
      []
    end
  end

  def items_of(ids)
    result = []
    from_base = []
    ids.each do |id|
      if @items_cache[id].blank?
        from_base << id
      else
        result << @items_cache[id]
      end
    end
    result += Item.where(id: from_base).each { |item| @items_cache[item.id] = item } if from_base.any?
    raise UnexpectedRecommendationsCountError.new('Получено рекомендаций меньше заданного значения') if result.size < @limit
    result
  end

  # Получить ID рекомендуемых товаров по алгоритму "Вам это будет интересно".
  #
  # @return [Array] массив ID товаров.
  def interesting_ids
    return [] if @current_user.nil?

    items_to_include = if shop_works_with_locations?
      @shop.items.recommendable.widgetable.in_locations(locations_for_current_user).pluck(:id)
    else
      @items_in_shop ||= @shop.items.recommendable.widgetable.pluck(:id)
    end

    Timeout::timeout(2) {
      mahout_service.user_based(
        @current_user.id,
        @shop.id,
        nil,
        include: items_to_include,
        exclude: @shop.item_ids_bought_or_carted_by(@current_user),
        limit: @limit
      )
    }
  rescue Timeout::Error => e
    retry
  end
end
