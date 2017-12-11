class SearchEngine::InstantSearch < SearchEngine::Base
  DEFAULT_RESULT_LIMIT = 6
  RESULT_LIMIT_WITH_PARTIAL_WORDS = 40

  def recommendations
    check_params!
    products, categories, collections = recommended_products, recommended_categories, recommended_collections
    {
      products: products,
      categories: categories,
      virtual_categories: [],
      keywords: [],
      queries: products.any? || categories.any? || collections.any? ? recommended_queries : [],
      collections: collections
    }
  end

  def build_body(keyword = nil, size = DEFAULT_RESULT_LIMIT)
    keyword ||= params.search_query
    Jbuilder.encode do |json|
      json.set! "product" do
        # json.regex search_query_regex
        json.prefix keyword
        json.completion do
          json.size  size
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
  end


  def search_query_regex
    params.search_query.split(' ').map{ |word| ".*#{word}" }.join
  end

  def recommended_products

    # Пока не придумал, как тестировать на Codeship, поэтому не пропускаем обработку на тесте
    return [] if Rails.env.test?

    # Find in Elastic
    product_ids = get_recommended_products_ids

    # double find with synonym for Kechinov
    unless product_ids.any?
      synonym = params.shop.no_result_queries.with_synonyms.find_by(query: params.search_query)
      if synonym.present?
        params.search_query = synonym.synonym

        # Find in Elastic
        product_ids = get_recommended_products_ids
      end
    end

    Item.where(id: product_ids).sort_by { |item| product_ids.index(item.id) }
  end


  def recommended_categories

    # Пока не используем ES
    # Важно: сейчас старые категории магазина не удаляются при обновлении YML, это будет нагружать объем данных в этом коде
    # Поэтому нужно придумать, как не выгружать старые категории, в которых нет активных товаров.
    categories = params.shop.item_categories.widgetable.pluck(:external_id, :name, :parent_external_id, :url).select { |category| category[1].present? && category[1].downcase.include?(params.search_query) }.take(params.limit)
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
    words = params.search_query.downcase.split(' ')
    suggested_keywords = params.shop.suggested_queries.search_by_keywords(words).order_by_score.limit(10).select(:keyword, :synonym)
    suggested_keywords.map{ |suggested_keyword| suggested_keyword.synonym || suggested_keyword.keyword }.uniq
  end

  private

  def get_recommended_products_ids
    keywords = params.search_query.split.sort_by(&:length).last(3)

    # return product ids if only one keyword is present
    if keywords.count == 1
      result = elastic_client.suggest index: "shop-#{shop.id}", body: build_body
      return result_have_products?(result) ? result['product'][0]['options'].map{ |x| x['_id'] } : []
    end

    # Find in Elastic with each keyword
    results = keywords.inject([]) do |results, keyword|
      results << elastic_client.suggest(index: "shop-#{shop.id}", body: build_body(keyword, RESULT_LIMIT_WITH_PARTIAL_WORDS))
      results
    end

    # Get common product ids by comparing results
    ids_collection = results.map{ |result| result['product'][0]['options'].map{ |x| x['_id'] } }
    common_ids = ids_collection[0] & ids_collection[1]
    product_ids = ids_collection[2].present? ? (common_ids & ids_collection[2]) : common_ids
    product_ids.first(DEFAULT_RESULT_LIMIT)
  end

  def result_have_products? result
    result && result.key?('product') && result['product'][0]['options'] && result['product'][0]['options'].count
  end

end
