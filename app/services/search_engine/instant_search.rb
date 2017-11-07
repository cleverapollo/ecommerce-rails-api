class SearchEngine::InstantSearch < SearchEngine::Base

  def recommendations
    check_params!
    {
        products: recommended_products,
        categories: recommended_categories,
        virtual_categories: [],
        keywords: [],
        queries: recommended_queries,
        collections: recommended_collections
    }
  end

  def build_body
    Jbuilder.encode do |json|
      json.set! "product" do
        json.regex search_query_regex
        json.completion do
          json.size  8
          json.field "suggest_product"
          json.contexts do
            json.set! 'widgetable', true
          end
        end
      end
    end
  end


  def search_query_regex
    params.search_query.split(' ').map{ |word| ".*#{word}" }.join
  end

  def recommended_products

    # Пока не придумал, как тестировать на Codeship, поэтому не пропускаем обработку на тесте
    return [] if Rails.env.test?

    result = ElasticSearchConnector.get_connection.suggest index: "shop-#{shop.id}", body: build_body

    # double find with synonym for Kechinov
    unless result && result.key?('product') && result['product'][0]['options'] && result['product'][0]['options'].count
      synonym = NoResultQuery.where.not(synonym: nil).find_by(shop_id: params.shop.id, query: params.search_query)
      if synonym.present?
        params.search_query = synonym.synonym

        # Find in Elastic
        result = ElasticSearchConnector.get_connection.suggest index: "shop-#{shop.id}", body: build_body
      end
    end

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


  def recommended_collections
# Пока не придумал, как тестировать на Codeship, поэтому не пропускаем обработку на тесте
    return [] if Rails.env.test?

    body = Jbuilder.encode do |json|
      json.set! "thematic_collection" do
        json.prefix params.search_query
        json.completion do
          json.size  8
          json.field "suggest_collection"
          json.fuzzy do
            json.fuzziness 1
          end
        end
      end
    end
    result = ElasticSearchConnector.get_connection.suggest index: "shop-#{shop.id}", body: body

    if result && result.key?('thematic_collection') && result['thematic_collection'][0]['options'] && result['thematic_collection'][0]['options'].count
      result['thematic_collection'][0]['options'].map { |x| {id: x['_id'], name: x['_source']['name']} }
    else
      []
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
