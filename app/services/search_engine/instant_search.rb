class SearchEngine::InstantSearch < SearchEngine::Base

  def recommendations
    check_params!
    {
        products: recommended_products,
        categories: recommended_categories,
        virtual_categories: [],
        keywords: [],
        queries: recommended_queries
    }
  end



  def recommended_products

    # Пока не придумал, как тестировать на Codeship, поэтому не пропускаем обработку на тесте
    return [] if Rails.env.test?

    body = Jbuilder.encode do |json|
      json.set! "product" do
        json.prefix params.search_query
        json.completion do
          json.size  8
          json.field "suggest_product"
          json.contexts do
            json.set! 'widgetable', true
          end
          json.fuzzy do
            json.fuzziness 1
          end
        end
      end
    end
    result = ElasticSearchConnector.get_connection.suggest index: "shop-#{shop.id}", body: body

    if result && result.key?('product') && result['product'][0]['options'] && result['product'][0]['options'].count
      ids = result['product'][0]['options'].map { |x| x['_id'] }
      # Получаем объекты в порядке сортировки
      products = {}
      Item.where(id: ids).each { |item| products[item.id] = item }
      products.values
    else
      []
    end

  end


  # Закомментировал, потому что это больше относится к результатам персонализированного поиска, чем к typeahead
  # Но в typeahead нужно будет добавить персонализацию результатов
  # def recommended_products
  #
  #   # Пока не придумал, как тестировать на Codeship, поэтому не пропускаем обработку на тесте
  #   return [] if Rails.env.test?
  #
  #   # Build Elastic request
  #   body = Jbuilder.encode do |json|
  #     json.query do
  #       json.match do
  #         json.name  params.search_query
  #       end
  #     end
  #     json.size      params.limit
  #   end
  #
  #   # Find in Elastic
  #   result = elastic_client.search index: "shop-#{shop.id}", type: 'product', body: body
  #   return [] unless result['hits']['hits'].any?
  #
  #   # Semantic scores
  #   score_semantic = {}
  #   result['hits']['hits'].each { |x| score_semantic[x['_id'].to_i] = x['_score'] }
  #
  #   # Find this ids in Mahout
  #   score_cf = {}
  #   if shop.use_brb?
  #     if params.user
  #       ms = MahoutService.new(shop.brb_address)
  #       ms.open
  #       mahout_result = ms.item_based_weight(params.user.id, params.shop.id, weight: score_semantic.keys, limit: score_semantic.count)
  #       ms.close
  #       scores = mahout_result.map { |item| [item[:item], item[:rating].to_f] }.to_h
  #       score_semantic.keys.each { |id| score_cf[id] = (scores[id] || 0.0) }
  #     end
  #   else
  #     score_semantic.keys.each { |x| score_cf[x] = 1.0 }
  #   end
  #
  #   # Sales rate scores
  #   score_sr = {}
  #   result['hits']['hits'].each { |x| score_sr[x['_id'].to_i] = x['_source']['sales_rate'].to_f }
  #
  #   # Normalize all scores
  #   values_semantic = score_semantic.values
  #   values_semantic.normalize!
  #
  #   values_cf = score_cf.values
  #   values_cf.normalize!
  #
  #   values_sr = score_sr.values
  #   values_sr.normalize!
  #
  #   # Calculate combined scores: sales rate, semantic and CF
  #   final_rate = values_semantic.each_with_index.map { |v, k| values_semantic[k] + values_cf[k] + values_sr[k] }
  #   scored_ids = score_semantic.keys.each_with_index { |id,k| [id, final_rate[k]] }
  #
  #   # Find items
  #   items = {}
  #   Item.where(id: result['hits']['hits'].map { |x| x['_id'] }).each { |x| items[x.id] = x }
  #
  #   # Sort items in final result
  #   sorted = []
  #   result['hits']['hits'].each { |x| sorted.push( items[x['_id'].to_i] ) }
  #
  #   # Return
  #   sorted.compact
  #
  # end



  def recommended_categories

    # Пока не используем ES
    # Важно: сейчас старые категории магазина не удаляются при обновлении YML, это будет нагружать объем данных в этом коде
    # Поэтому нужно придумать, как не выгружать старые категории, в которых нет активных товаров.
    categories = params.shop.item_categories.widgetable.pluck(:id, :name, :parent_external_id, :url).select { |category| category[1].present? && category[1].downcase.include?(params.search_query) }.take(params.limit)
    return categories.map do |c|
      {
          id: c[0],
          name: ( c[2] ? "#{ItemCategory.find_by(external_id: c[2], shop_id: shop.id).name} - #{c[1]}" : c[1] ),
          url: c[3]
      }
    end

  end



  # Важно - поисковые запросы, запрошенные один раз, игнорируются
  def recommended_queries
    queries = params.shop.search_queries.where('date >= ?', 7.days.ago.to_date).pluck(:query)
    aggregated = queries.inject(Hash.new(0)) { |h,e| h[e] += 1; h }.select { |k,v| v > 1 }.inject({}) { |r, e| r[e.first] = e.last; r }
    words = params.search_query.split(' ')
    filtered = aggregated.select { |key, value| words.all? { |x| key.include?(x) }  }
    return filtered.each { |key, value| [key, value] }.sort { |a,b| a[1] <=> b[1] }.map { |x| x[0] }.reverse
  end


end