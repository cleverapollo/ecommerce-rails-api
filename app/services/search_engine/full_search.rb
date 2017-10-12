class SearchEngine::FullSearch < SearchEngine::Base

  def recommendations
    check_params!
    {
        products: recommended_products,
        categories: recommended_categories,
        virtual_categories: [],
        keywords: [],
        queries: []
    }
  end

  def build_body
    # Build Elastic request
    filter_conditions = []
    filter_conditions << ['term', 'widgetable', true]
    if params.locations
      # Добавляем global, чтобы находить товары, у которых не указан locations
      filter_conditions << ['terms', 'location_ids', params.locations + ['global'] ]
    end

    # Gender filter for apparel
    must_not_condition = []
    if user.try(:gender).present? && (shop.has_products_fashion? || shop.has_products_kids? || shop.has_products_cosmetic?)
      must_not_condition << ['term', 'fashion_gender', UserProfile::Gender.opposite_gender(user.gender) ]
    end

    Jbuilder.encode do |json|
      json.query do
        # json.match do
        #   json.name  params.search_query
        # end
        json.bool do
          json.must do
            json.array! [ ['match', 'name', params.search_query] ] do |x|
              json.set! x[0] do
                json.set! x[1], x[2]
              end
            end
          end
          json.must_not do
            json.array! must_not_condition do |x|
              json.set! x[0] do
                json.set! x[1], x[2]
              end
            end
          end
          json.filter do
            json.array! filter_conditions do |x|
              json.set! x[0] do
                json.set! x[1], x[2]
              end
            end
          end
        end
      end
      json.size      params.limit
    end

  end


  def recommended_products

    # Пока не придумал, как тестировать на Codeship, поэтому не пропускаем обработку на тесте
    return [] if Rails.env.test?

    # Find in Elastic
    result = elastic_client.search index: "shop-#{shop.id}", type: 'product', body: build_body

    # double find with synonym for Kechinov
    if result['hits']['hits'].blank?
      synonym = NoResultQuery.where.not(synonym: nil).find_by(shop_id: params.shop.id, query: params.search_query)
      if synonym.present?
        params.search_query = synonym.synonym

        # Find in Elastic
        result = elastic_client.search index: "shop-#{shop.id}", type: 'product', body: build_body
      end
    end

    return [] unless result['hits']['hits'].any?

    # Semantic scores
    score_semantic = {}
    result['hits']['hits'].each { |x| score_semantic[x['_id'].to_i] = x['_score'] }

    # Find this ids in Mahout
    score_cf = {}
    if shop.use_brb?
      if params.user
        ms = MahoutService.new(shop.brb_address)
        ms.open
        mahout_result = ms.item_based_weight(params.user.id, params.shop.id, weight: score_semantic.keys, limit: score_semantic.count)
        ms.close
        scores = mahout_result.map { |item| [item[:item], item[:rating].to_f] }.to_h
        score_semantic.keys.each { |id| score_cf[id] = (scores[id] || 0.0) }
      end
    else
      score_semantic.keys.each { |x| score_cf[x] = 1.0 }
    end

    # Sales rate scores
    score_sr = {}
    result['hits']['hits'].each { |x| score_sr[x['_id'].to_i] = x['_source']['sales_rate'].to_f }

    # Normalize all scores
    values_semantic = score_semantic.values
    values_semantic.normalize!

    values_cf = score_cf.values
    values_cf.normalize!

    values_sr = score_sr.values
    values_sr.normalize!

    # Calculate combined scores: sales rate, semantic and CF
    final_rate = values_semantic.each_with_index.map { |_, k| values_semantic[k] + values_cf[k] + values_sr[k] }
    scored_ids = score_semantic.keys.each_with_index { |id,k| [id, final_rate[k]] }

    # Find items
    items = {}
    Item.where(id: result['hits']['hits'].map { |x| x['_id'] }).each { |x| items[x.id] = x }

    # Sort items in final result
    sorted = []
    result['hits']['hits'].each { |x| sorted.push( items[x['_id'].to_i] ) }

    # Return
    sorted.compact

  end



  # @return Array
  def recommended_categories

    # Build Elastic request
    body = Jbuilder.encode do |json|
      json.query do
        json.match do
          json.name  params.search_query
        end
      end
      json.size      params.limit
    end

    # Find in Elastic
    result = elastic_client.search index: "shop-#{shop.id}", type: 'category', body: body
    return [] unless result['hits']['hits'].any?

    ids = result['hits']['hits'].map{|x| x['_id']}
    categories = shop.item_categories.where(id: ids )

    # Сортируем категории в соответствии с ID из поисковика
    result = Hash[ids.map { |id| [id.to_i, nil] }]
    categories.each do |category|
      result[category.id] = category
    end

    result.values.map { |x| {id: x.external_id, name: x.name, url: x.url} }

  end

end
