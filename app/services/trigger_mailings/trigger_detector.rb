module TriggerMailings
  ##
  # Класс, ищущий триггеры
  #
  class TriggerDetector
    def initialize(shop)
      @shop = shop
      @triggers_classes = @shop.trigger_mailings.enabled.map(&:trigger_type)
                                                        .map(&:camelize)
                                                        .map{|tt| "TriggerMailings::Triggers::#{tt}" }
                                                        .map(&:constantize)
    end

    # Найти триггер для пользователя в магазине
    # @param client [Client] пользователь магазина
    #
    # @return [TriggerMailings::Triggers::Base] найденный триггер
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
