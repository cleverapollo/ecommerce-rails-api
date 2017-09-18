module RecAlgo
  class Params

    attr_accessor :rule, :limit, :raw
    # @return [Shop]
    attr_accessor :shop
    # @return [User]
    attr_accessor :user

    # @param [RecRule::Params] params
    # @param [Hash] rule
    def initialize(params, rule)
      self.limit = params.limit
      self.rule = rule
      self.shop = params.shop
      self.raw = params.raw
      self.user = params.user
    end

    # Подготавливает основные параметры для запроса рекоммендера
    def search_query
      body = {
          sort: {
              sales_rate: { order: 'desc' }
          },
          query: {
              bool: {
                  filter: [],
                  must_not: [],
              }
          },
          size: limit,
      }

      if raw[:locations].present?
        # Добавляем global, чтобы находить товары, у которых не указан locations
        body[:query][:bool][:filter] << { terms: { location_ids: params.locations.map { |x| x.to_s } + ['global'] } }
      end

      # Добавляем фильтры
      if rule.filters.present?
        rule.filters.each do |k,v|
          body[:query][:bool][:filter] << { (v.is_a?(Array) ? 'terms' : 'term') => {k => v} }
        end
      end

      # Строим массив по ключам, которые не должны попадать в выборку
      if rule.exclude.present?
        rule.exclude.each do |k,v|
          body[:query][:bool][:must_not] << { (v.is_a?(Array) ? 'terms' : 'term') => {k => v} }
        end
      end

      body
    end
  end
end
