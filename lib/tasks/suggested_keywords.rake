namespace :suggested_keywords do
  desc 'Generate suggested keywords'
  task generate: :environment do
    Shop.find_each(batch_size: 100) do |shop|
      popular_queries = shop.search_queries.created_within_days(OrderItemCl::TOP_QUERY_LIST_DAYS)
                        .group(:query)
                        .order('count(*) DESC').select('query, count(*)')

      next if popular_queries.compact.blank?

      top_perform_queries = OrderItemCl.created_within_days(OrderItemCl::TOP_QUERY_LIST_DAYS)
                              .shop(shop.id).by_recommended_code(popular_queries.collect(&:query))
                              .group('recommended_code')
                              .order('sum_price desc').sum('price')

      keywords_with_score = popular_queries.inject({}) { |hash, popular_query|
                              hash[popular_query.query] = popular_query.count + top_perform_queries[popular_query.query].to_f
                              hash
                            }

      synonyms = shop.no_result_queries.with_synonyms.where(query: keywords_with_score.keys).pluck(:query, :synonym).to_h

      keywords_with_score.each do |keyword, score|
        suggested_query = shop.suggested_queries.find_or_create_by(keyword: keyword)
        suggested_query.score, suggested_query.synonym = score, synonyms[keyword]
        suggested_query.save if suggested_query.changed?
      end
    end
  end
end
