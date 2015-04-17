class ShopItemsCache
  def initialize(shop)
    @shop = shop
    @cache = choose_strategy.new(@shop)
  end

  def pop(external_id)
    @cache.pop(external_id)
  end

  def each(&block)
    @cache.each(&block)
  end

  def choose_strategy
    @shop.items.recommendable.count > 200_000 ? SetStrategy : HashStrategy
  end

  class HashStrategy
    def initialize(shop)
      @shop = shop
      @storage = { }
      @shop.items.find_each do |item|
        @storage[item.uniqid] = item
      end
    end

    def pop(external_id)
      @storage.delete(external_id)
    end

    def each
      @storage.each do |_, item|
        yield item
      end
    end
  end

  class SetStrategy
    def initialize(shop)
      @shop = shop
      @storage = Set.new
      @shop.items.select(:id, :uniqid).find_each do |item|
        @storage.add(item[:uniqid])
      end
    end

    def pop(storage)
      @storage.delete(storage)
      @shop.items.find_by(uniqid: storage)
    end

    def each
      @storage.each do |external_id|
        yield @shop.items.find_by(uniqid: external_id)
      end
    end
  end
end
