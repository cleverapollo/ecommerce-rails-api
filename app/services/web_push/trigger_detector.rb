module WebPush
  ##
  # Класс, ищущий триггеры
  #
  class TriggerDetector
    def initialize(shop)
      @shop = shop
      @triggers_classes = @shop.web_push_triggers.enabled.map(&:trigger_type)
                                                        .map(&:camelize)
                                                        .map{|tt| "WebPush::Triggers::#{tt}" }
                                                        .map(&:constantize)
    end

    def triggers_classes
      @triggers_classes
    end

    # Найти триггер для пользователя в магазине
    # @param client [Client] пользователь магазина
    # @return [WebPush::Triggers::Base] найденный триггер
    def detect(client)
      @triggers_classes.map do |trigger_class|
        t = trigger_class.new(client)
        t if t.triggered?
      end.compact.sort{|x, y| x.priority <=> y.priority }.last
    end

    class << self
      def for(shop)
        yield new(shop)
      end
    end
  end
end
