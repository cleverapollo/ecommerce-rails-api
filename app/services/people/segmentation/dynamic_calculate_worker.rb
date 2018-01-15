class People::Segmentation::DynamicCalculateWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  # Запускает перерасчет динамических сегментов для всех подключенных магазнов
  # Интервал обоновления: 2 дня
  def self.perform_all_shops
    Segment.where(shop: Shop.connected.active.unrestricted, segment_type: Segment::TYPE_DYNAMIC).where("updated_at < now() - INTERVAL '2 DAY'").each do |segment|
      People::Segmentation::DynamicCalculateWorker.perform_async(segment.id)
    end
  end

  # @param [Number] segment_id
  def perform(segment_id)
    return if segment_id.blank?

    # Ищем сегмент и проверяем его тип
    segment = Segment.find_by id: segment_id

    # Запускаем обычный подсчет для статического сегмента
    if segment.present? && segment.segment_type == Segment::TYPE_STATIC
      People::Segmentation::SegmentWorker.new.perform(segment)
      return
    end

    # Дальше может идти только динамический сегмент который в текущий момент не обновляется
    return if segment.nil? || segment.segment_type != Segment::TYPE_DYNAMIC || segment.updating?

    # @type [Shop] shop
    shop = segment.shop

    # Указываем, что началось обновление сегмента
    segment.update(updating: true)
    begin

      # Удаляем связи клиентов с этим сегментом
      segment.remove_segment_from_clients

      # Строим список для выборки юзеров
      # CLIENT --->
      users_relation = shop.shop_emails.with_clients

      # Location
      users_relation = users_relation.where(clients: { location: segment.filters[:demography][:locations] }) if segment.filters[:demography].present? && segment.filters[:demography][:locations].present?

      # Purchase
      if segment.filters[:marketing].present? && segment.filters[:marketing][:category_purchased].present? && segment.filters[:marketing][:category_purchased].to_i == 1
        users_relation = users_relation.where(clients: { bought_something: true }).joins('JOIN orders ON orders.client_id = clients.id').where('orders.status != ?', Order::STATUS_CANCELLED)

        # Покупали в указанный период
        users_relation = users_relation.where('orders.date >= ?', Time.current - segment.filters[:marketing][:category_purchase_period].to_i.days)

        # Цена покупки
        price = segment.filters[:marketing][:category_purchase_price]
        users_relation = users_relation.where('orders.value >= ? AND orders.value <= ?', price[:from], price[:to])
      end

      # Email marketing
      if segment.filters[:marketing].present?

        # Просматривали рассылку
        if segment.filters[:marketing][:letter_open].to_i == 1
          users_relation = users_relation.where('shop_emails.digest_opened = true')

          # Добавляем период выборки
          if segment.filters[:marketing][:letter_open_period].present?
            # Добавляем join с отправленными письмами и указанным переодом
            # todo убрать привязку по клиенту после 30.01.2018 (в это время уже у всех новых писем будет привязка с email табилцей)
            users_relation = users_relation.joins('INNER JOIN digest_mails ON (digest_mails.client_id = clients.id OR digest_mails.shop_email_id = shop_emails.id)').where('opened = true AND digest_mails.created_at >= ?', segment.filters[:marketing][:letter_open_period].to_i.days.ago)
          end
        end

        # Фильтр по последнему дайджесту
        if segment.filters[:marketing][:digest].present?
          last_digest = shop.digest_mailings.where(state: 'finished').order(finished_at: :desc).first
          if last_digest.present?
            # Добавляем join если он еще не был добавлен ранее
            users_relation = users_relation.joins('INNER JOIN digest_mails ON digest_mails.client_id = clients.id') unless users_relation.to_sql.include?('INNER JOIN digest_mails')
            # Фильтруем по последнему дайджесту
            users_relation = users_relation.where(digest_mails: { digest_mailing_id: last_digest.id, opened: segment.filters[:marketing][:digest].to_i == 1 })
          end
        end

        # Для подписанных
        if segment.filters[:marketing][:subscription].to_i > 0
          v = segment.filters[:marketing][:subscription].to_i
          # Для подписки на дайджесты
          users_relation = users_relation.where('shop_emails.digests_enabled = ?', v == 1) if v == 1 || v == 2
          # Для подписки на триггеры
          users_relation = users_relation.where('shop_emails.triggers_enabled = ?', v == 3) if v == 3 || v == 4
        end

        # Фильтруем по дате регистрации
        if segment.filters[:marketing][:new_users_period].to_i > 0
          users_relation = users_relation.where('clients.created_at >= ?', segment.filters[:marketing][:new_users_period].to_i.days.ago)
        end
      end
      # ---------->

      # Фильтруем список дополнительно по просмотрам
      if segment.filters[:marketing].present?
        filter = segment.filters[:marketing]

        # Если есть фильтры по просмотрам или покупкам
        if filter[:category_viewed].present? && filter[:category_viewed].to_i == 1 || filter[:category_purchased].present? && filter[:category_purchased].to_i == 1
          sessions = []

          # Просмотр в категории
          if filter[:category_viewed].present? && filter[:category_viewed].to_i == 1
            actions = ActionCl.where(shop_id: shop.id, object_type: 'Item')
            # Если указаны категории
            actions = actions.where(object_id: shop.items.recommendable.in_categories(filter[:category_view], { any: true }).pluck(:uniqid)) if filter[:category_view].present?

            # Если указаны бренды
            actions = actions.where(brand: filter[:category_view_brand].map(&:downcase)) if filter[:category_view_brand].present?

            # Добавляем дату просмотра
            actions = actions.where(event: 'view').where('date >= ?', filter[:category_view_period].to_i.days.ago.to_date)

            # Добавляем стоимость товара
            actions = actions.where('price >= ? AND price <= ?', filter[:category_view_price][:from].to_f, filter[:category_view_price][:to].to_f)

            # Достаем список сессий
            sessions += actions.pluck('DISTINCT session_id')
          end

          # Покупка в категории
          if filter[:category_purchased].present? && filter[:category_purchased].to_i == 1
            actions = ActionCl.where(shop_id: shop.id, object_type: 'Item')
            # Если указаны категории
            actions = actions.where(object_id: shop.items.recommendable.in_categories(filter[:category_purchase], { any: true }).pluck(:uniqid)) if filter[:category_purchase].present?

            # Если указаны бренды
            actions = actions.where(brand: filter[:category_purchase_brand].map(&:downcase)) if filter[:category_purchase_brand].present?

            # Добавляем дату просмотра
            actions = actions.where(event: 'purchase').where('date >= ?', filter[:category_purchase_period].to_i.days.ago.to_date)

            # Достаем список сессий
            if sessions.present?
              # Если массив уже был добавлен в выборке view делаем пересечение массивов
              sessions = sessions & actions.pluck('DISTINCT session_id')
            else
              sessions += actions.pluck('DISTINCT session_id')
            end
          end

          # Добавляем фильтр
          users_relation = users_relation.where(clients: { session_id: sessions.uniq })
        end
      end

      # Достаем список email c id
      shop_emails = users_relation.pluck('DISTINCT shop_emails.id, shop_emails.email')

      # INDUSTRIAL FILTERS --->
      # Строим массив запроса
      query = Hash.recursive
      query[:bool][:filter] = []
      query[:bool][:filter] << {
          terms: { id: shop_emails.map{|s| s[1]}.uniq }
      }

      # Demography
      query[:bool][:filter] << {term: {gender: segment.filters[:demography][:gender]}} if segment.filters[:demography].present? && segment.filters[:demography][:gender].present?

      # Fashion
      if segment.filters[:fashion].present?
        wear = WearTypeDictionary.pluck('DISTINCT type_name')
        segment.filters[:fashion].each do |k,v|
          query[:bool][:filter] << nested_search_must('fashion_sizes', k, v) if wear.include?(k)
        end
      end

      # Auto
      if segment.filters[:auto].present?
        %w(brand model).each do |k|
          query[:bool][:filter] << nested_search_must('compatibility', k, segment.filters[:auto][k.to_sym]) if segment.filters[:auto][k.to_sym].present?
        end
      end

      # Child
      if segment.filters[:child].present? && segment.filters[:child][:available].to_i == 1
        query[:bool][:filter] << nested_search_range('children', 'age', segment.filters[:child][:age][:from].to_f..segment.filters[:child][:age][:to].to_f)
        query[:bool][:filter] << nested_search_must('children', 'gender', segment.filters[:child][:gender]) if segment.filters[:child][:gender].present?
      end

      # ------->

      # Если правила были добавлены, кроме самих email
      if query[:bool][:filter].count > 1 && shop_emails.present?
        # Ищем фильтрованные профиля в Elastic
        filtered_emails = People::Profile.repository.search(_source: ['id'], query: query).to_a.map{|r| r.attributes['id']}

        # Оставляем только отфильтрованные
        shop_emails = shop_emails.select {|e| filtered_emails.include?(e[1]) }
      end

      # Достаем email юзеров
      if shop_emails.present?
        shop_emails = shop.shop_emails.where(id: shop_emails.map{|s| s[0]}.uniq)
        values = []

        # Добавляем услоие исключения
        if segment.filters[:marketing].present? && segment.filters[:marketing][:exclude_from_segments].present?
          segments = shop.segments.visible.where(id: segment.filters[:marketing][:exclude_from_segments].map(&:to_i)).pluck(:id)
          shop_emails = shop_emails.where('segment_ids IS NULL OR NOT (segment_ids && ARRAY[?]::int[])', segments) if segments.present?
        end

        # Добавляем сегмент к клиентам
        shop_emails.update_all("segment_ids = array_append(segment_ids, #{segment_id})")
      end

      # Добавляем в выборку сегменты
      if segment.filters[:marketing].present? && segment.filters[:marketing][:include_from_segments].present?
        segments = shop.segments.visible.where(id: segment.filters[:marketing][:include_from_segments].map(&:to_i)).pluck(:id)

        # Добавляем фильтр в котором email в уже сегменте не попадают в выборку
        shop_emails = shop.shop_emails.where('NOT (segment_ids && ARRAY[?]::int[])', segment.id).with_segment(segments)

        # Добавляем услоие исключения
        if segment.filters[:marketing].present? && segment.filters[:marketing][:exclude_from_segments].present?
          segments = shop.segments.visible.where(id: segment.filters[:marketing][:exclude_from_segments].map(&:to_i)).pluck(:id)
          shop_emails = shop_emails.where('segment_ids IS NULL OR NOT (segment_ids && ARRAY[?]::int[])', segments) if segments.present?
        end

        shop_emails.update_all("segment_ids = array_append(segment_ids, #{segment_id})")
      end

      # Обновляем статистику сегмента
      People::Segmentation::SegmentWorker.new.perform(segment)
    ensure
      # Указываем, что завершилось обновление сегмента
      segment.update(updating: false)
    end
  ensure
    ActiveRecord::Base.clear_active_connections!
    ActiveRecord::Base.connection.close
  end

  private

  # Добавляет в выборку условие для nested поля
  def nested_search_hash(path, query)
    {
        nested: {
            path: path,
            query: query
        }
    }
  end

  # Добавляет в выборку условие фильтра для nested поля
  def nested_search_must(path, key, values)
    nested_search_hash(path, {
        bool: {
            must: { "term#{values.is_a?(Array) ? 's' : ''}": {"#{path}.#{key}": values} }
        }
    })
  end

  # Добавляет в выборку условие фильтра для nested поля c диапазоном
  def nested_search_range(path, key, range)
    nested_search_hash(path, {
        range: {
            "#{path}.#{key}": { gte: range.first, lte: range.last }
        }
    })
  end
end
