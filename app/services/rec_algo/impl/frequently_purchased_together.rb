module RecAlgo
  module Impl
    class FrequentlyPurchasedTogether < RecAlgo::Base
      # EX also bought or see also for single or group of products
      def recommendations
        check_params!

        raise NotImplementedError.new('Not implemented yet')

        result = ElasticSearchConnector.get_connection.search index: "shop-#{shop.id}", type: 'product', body: params.search_query
        return [] unless result['hits']['hits'].any?
        result['hits']['hits'].map { |x| x['_source']['uniqid'] }
      end

    end
  end
end
