module RecAlgo
  module Impl
    class PopularInCategory < RecAlgo::Base

      def recommendations
        check_params!

        body = params.search_query

        # Работает по OR
        body[:query][:bool][:filter] << { terms: { category_ids: params.raw[:categories] } }

        result = ElasticSearchConnector.get_connection.search index: "shop-#{shop.id}", type: 'product', body: body
        return [] unless result['hits']['hits'].any?
        result['hits']['hits'].map { |x| x['_source']['uniqid'] }
      end

      # Проверка, валидны ли параметры для конкретного рекомендера
      def check_params!
        super
        raise Recommendations::Error.new('Empty categories list') if params.raw[:categories].blank?
      end

    end
  end
end
