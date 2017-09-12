# Основной класс для правил отображения рекоммендеров
# Точка входа RecommenderBlock.recommends
module RecRule
  class Base

    # Массив реализаций правил
    TYPES = Dir.glob(Rails.root + 'app/services/rec_rule/impl/*').map{|a| a.split('/').last.split('.').first }

    class << self

      # Точка входа в запрос блока рекомендаций
      # @param [Recommendations::Params] params
      # @param [Array] rules Правила блока рекомендаций
      # @return [Array]
      def process(params, rules)
        recommends = []
        limit = params.limit

        # Проходим по списку правил
        rules.each do |rule|
          # Устанавливаем количество требуемых товаров
          params.limit = limit - recommends.size

          # Набрали нужное количество, выходим
          break if recommends.size == limit

          # Выполняем блок правила
          recommends += RecRule::Base.get(params, OpenStruct.new(rule)).execute
          recommends.uniq!
        end

        recommends
      end

      # @param [Recommendations::Params] params
      # @param [OpenStruct] rule
      # @return [RecRule::Base]
      def get(params, rule)
        raise Recommendations::Error.new('Unsupported rule type') unless TYPES.include?(rule.type)

        implementation_class(rule.type).new(params, rule)
      end

      # Получаем класс правила
      def implementation_class(type)
        "RecRule::Impl::#{type.camelize}".constantize
      end
    end

    # --- CLASS METHODS ---

    # @return [Recommendations::Params] params
    attr_accessor :params
    attr_accessor :rule

    # @param [Recommendations::Params] params
    # @param [Hash] rule
    def initialize(params, rule)
      self.params = params
      self.rule = rule
      check_params!
    end

    # Проверка, валидны ли параметры для конкретного рекомендера
    def check_params!
      raise Recommendations::Error.new('Blank user') if params.user.blank?
    end

    # Выполнение роли
    # Результат выполнения: список id рекомендованных товаров
    # @return [Array<Integer>]
    def execute
      raise NotImplementedError.new('This should be implemented in concrete recommender class')
    end
  end
end
