class YmlReport
  Error = Struct.new(:type, :element) do
    def message
      I18n.t!(type.to_sym, locale: :ru, scope: [:rees46_ml, :error])
    end
  end

  attr_accessor :shop_id

  def invalid_offer!(offer)
    error :invalid_offer, offer
  end

  def invalid_categories!(categories)
    error :invalid_categories, categories
  end

  def invalid_locations!(locations)
    error :invalid_locations, locations
  end

  def shop_not_exists!
    error :shop_not_exists
  end

  def invalid_categories!
    error :invalid_categories
  end

  def invalid_locations!
    error :invalid_locations
  end

  def offers_not_exists!
    error :offers_not_exists
  end

  def offers_less_than_five!
    error :offers_less_than_five
  end

  def error(type, element = nil)
    errors << Error.new(type.to_sym, element)
  end

  def errors
    @errors ||= Set.new([])    
  end
end

