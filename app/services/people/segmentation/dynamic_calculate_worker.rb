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

  def perform(segment_id)
    return if segment_id.blank?

    # Ищем сегмент и проверяем его тип
    segment = Segment.find_by id: segment_id
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
      users_relation = shop.clients.where('email IS NOT NULL AND digests_enabled = true OR web_push_enabled = true')

      # Location
      users_relation = users_relation.where(location: segment.filters[:demography][:locations]) if segment.filters[:demography].present? && segment.filters[:demography][:locations].present?

      # Purchase
      if segment.filters[:marketing].present? && segment.filters[:marketing][:category_purchased].present? && segment.filters[:marketing][:category_purchased].to_i == 1
        users_relation = users_relation.where(bought_something: true).joins(:orders).where('orders.status != ?', Order::STATUS_CANCELLED)

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
          users_relation = users_relation.where(digest_opened: true)

          # Добавляем период выборки
          if segment.filters[:marketing][:letter_open_period].present?
            # Добавляем join с отправленными письмами и указанным переодом
            users_relation = users_relation.joins('INNER JOIN digest_mails ON digest_mails.client_id = clients.id').where('opened = true AND digest_mails.created_at >= ?', segment.filters[:marketing][:letter_open_period].to_i.days.ago)
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

        # Фильтруем по дате регистрации
        if segment.filters[:marketing][:new_users_period].to_i > 0
          users_relation = users_relation.where('clients.created_at >= ?', segment.filters[:marketing][:new_users_period].to_i.days.ago)
        end
      end
      # ---------->

      # Достаем весь список юзеров, доступных для рассылок
      users = Slavery.on_slave { users_relation.pluck('DISTINCT "clients".user_id') }

      # Фильтруем список дополнительно по просмотрам
      if segment.filters[:marketing].present?
        filter = segment.filters[:marketing]

        # Если есть фильтры по просмотрам или покупкам
        if filter[:category_viewed].present? && filter[:category_viewed].to_i == 1 || filter[:category_purchased].present? && filter[:category_purchased].to_i == 1
          sessions = []

          # Просмотр в категории
          if filter[:category_viewed].present? && filter[:category_viewed].to_i == 1
            users_relation = ActionCl.where(shop_id: shop.id, object_type: 'Item')
            # Если указаны категории
            users_relation = users_relation.where(object_id: shop.items.recommendable.in_categories(filter[:category_view], { any: true }).pluck(:uniqid)) if filter[:category_view].present?

            # Если указаны бренды
            users_relation = users_relation.where(brand: filter[:category_view_brand].map(&:downcase)) if filter[:category_view_brand].present?

            # Добавляем дату просмотра
            users_relation = users_relation.where(event: 'view').where('date >= ?', filter[:category_view_period].to_i.days.ago.to_date)

            # Добавляем стоимость товара
            users_relation = users_relation.where('price >= ? AND price <= ?', filter[:category_view_price][:from].to_f, filter[:category_view_price][:to].to_f)

            # Достаем список сессий
            sessions += users_relation.pluck('DISTINCT session_id')
          end

          # Покупка в категории
          if filter[:category_purchased].present? && filter[:category_purchased].to_i == 1
            users_relation = ActionCl.where(shop_id: shop.id, object_type: 'Item')
            # Если указаны категории
            users_relation = users_relation.where(object_id: shop.items.recommendable.in_categories(filter[:category_purchase], { any: true }).pluck(:uniqid)) if filter[:category_purchase].present?

            # Если указаны бренды
            users_relation = users_relation.where(brand: filter[:category_purchase_brand].map(&:downcase)) if filter[:category_purchase_brand].present?

            # Добавляем дату просмотра
            users_relation = users_relation.where(event: 'purchase').where('date >= ?', filter[:category_purchase_period].to_i.days.ago.to_date)

            # Достаем список сессий
            if sessions.present?
              # Если массив уже был добавлен в выборке view делаем пересечение массивов
              sessions = sessions & users_relation.pluck('DISTINCT session_id')
            else
              sessions += users_relation.pluck('DISTINCT session_id')
            end
          end

          # Достаем список юзеров
          users = Slavery.on_slave { Session.where(id: sessions.uniq, user_id: users).pluck('DISTINCT user_id') }
        end
      end

      # Строим выборку
      # USER --->
      relation = User.where(id: users)

      # Демография
      relation = relation.where(gender: segment.filters[:demography][:gender]) if segment.filters[:demography].present? && segment.filters[:demography][:gender].present?

      # Fashion
      if segment.filters[:fashion].present?
        wear = WearTypeDictionary.pluck('DISTINCT type_name')
        segment.filters[:fashion].each do |k,v|
          relation = relation.where("array(select jsonb_array_elements_text(fashion_sizes->'#{k}')) && ARRAY[?]", v) if wear.include?(k)
        end
      end

      # Auto
      if segment.filters[:auto].present?
        %w(brand model).each do |k|
          relation = relation.where("array(select jsonb_array_elements_text(compatibility->'#{k}')) && ARRAY[?]", segment.filters[:auto][k.to_sym]) if segment.filters[:auto][k.to_sym].present?
        end
      end

      # Child
      if segment.filters[:child].present? && segment.filters[:child][:available].to_i == 1
        relation = relation.from('users, jsonb_array_elements(children) child').where('(child.value->>\'age_min\')::FLOAT >= ? AND (child.value->>\'age_max\')::FLOAT < ?', segment.filters[:child][:age][:from], segment.filters[:child][:age][:to])
        relation = relation.where('children @> ?', [{gender: segment.filters[:child][:gender]}].to_json) if segment.filters[:child][:gender].present?
      end
      # ------->

      # Достаем id юзеров
      users = relation.pluck(:id)
      if users.present? || segment.filters[:marketing][:include_from_segments].present?
        clients = shop.clients
        values = []

        # Добавляем в выборку список юзеров
        values << "user_id IN (#{users.join(',')})" if users.present?

        # Добавляем в выборку сегменты
        if segment.filters[:marketing].present? && segment.filters[:marketing][:include_from_segments].present?
          segments = shop.segments.visible.where(id: segment.filters[:marketing][:include_from_segments].map(&:to_i)).pluck(:id)
          values << "segment_ids && ARRAY[#{segments.join(',')}]::int[]" if segments.present?
        end

        # Добавляем условия выборки
        clients = clients.where(values.join(' OR ')) if values.present?

        # Добавляем услоие исключения
        if segment.filters[:marketing].present? && segment.filters[:marketing][:exclude_from_segments].present?
          segments = shop.segments.visible.where(id: segment.filters[:marketing][:exclude_from_segments].map(&:to_i)).pluck(:id)
          clients = clients.where('segment_ids IS NULL OR NOT (segment_ids && ARRAY[?]::int[])', segments) if segments.present?
        end

        # Добавляем сегмент к клиентам
        clients.update_all("segment_ids = array_append(segment_ids, #{segment_id})")
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
end
