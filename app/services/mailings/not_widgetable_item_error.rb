module Mailings
  class NotWidgetableItemError < StandardError
    attr_reader :item

    def initialize(item)
      @item = item
      super("Item #{item.id} is not widgetable")
    end
  end
end
