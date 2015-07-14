module SectoralAlgorythms
  class Base
    def initialize(user)
      @user = user
    end

    def trigger_action(action, items)
      items.each { |item| trigger_view(item) } if action == 'view'

      items.each { |item| trigger_purchase(item) } if action== 'purchase'
    end

    def value
      raise NotImplementedError.new('This should be implemented in concrete Algorythm class')
    end

    def trigger_view(item)
      raise NotImplementedError.new('This should be implemented in concrete Algorythm class')
    end

    def trigger_purchase(item)
      raise NotImplementedError.new('This should be implemented in concrete Algorythm class')
    end

    def recalculate
      raise NotImplementedError.new('This should be implemented in concrete Algorythm class')
    end

    def attributes_for_update
      raise NotImplementedError.new('This should be implemented in concrete Algorythm class')
    end
  end
end
