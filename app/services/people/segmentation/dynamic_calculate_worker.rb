class People::Segmentation::DynamicCalculateWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  def perform(segment_id)
    return if segment_id.blank?

    # Ищем сегмент и проверяем его тип
    segment = Segment.find segment_id
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
      if segment.filters[:purchase].present? && segment.filters[:purchase][:bought_something].to_i == 1
        users_relation = users_relation.where(bought_something: true).joins(:orders)

        # Покупали в указанный период
        if segment.filters[:purchase][:last].present?
          dates = segment.filters[:purchase][:last].split(' - ').map { |d| Date.parse(d) }
          users_relation = users_relation.where(orders: {date: dates[0]..(dates[1] + 1.day)})
        end

        # Цена покупки
        if segment.filters[:purchase][:price].present?
          price = segment.filters[:purchase][:price]
          users_relation = users_relation.where('orders.value >= ? AND orders.value <= ?', price[:from], price[:to])
        end

        # Если указаны бренды (жестко делать столько join, нужно придумать что-то другое)
        if segment.filters[:purchase][:brand].present?
          users_relation = users_relation.joins('INNER JOIN order_items ON orders.id = order_items.order_id').joins('INNER JOIN items ON order_items.item_id = items.id').where(items: { brand: segment.filters[:purchase][:brand]})
        end
      end

      # Email marketing
      if segment.filters[:marketing].present?
        # Хоть раз просматривали рассылку
        users_relation = users_relation.where(digest_opened: true) if segment.filters[:marketing][:letter_open].to_i == 1

        # Фильтр по последнему дайджесту
        if segment.filters[:marketing][:digest].present?
          last_digest = shop.digest_mailings.where(state: 'finished').order(finished_at: :desc).first
          if last_digest.present?
            users_relation = users_relation.joins('INNER JOIN digest_mails ON digest_mails.client_id = clients.id').where(digest_mails: { digest_mailing_id: last_digest.id, opened: segment.filters[:marketing][:digest].to_i == 1 })
          end
        end
      end
      # ---------->

      # Достаем весь список юзеров, доступных для рассылок
      users = users_relation.pluck('DISTINCT "clients".user_id')

      # Фильтруем список дополнительно по просмотрам
      if segment.filters[:marketing].present?
        filter = segment.filters[:marketing]

        # Если есть фильтры по просмотрам или покупкам
        if filter[:category_viewed].present? && filter[:category_viewed].to_i == 1 || filter[:category_purchased].present? && filter[:category_purchased].to_i == 1
          users_relation = Action.where(shop_id: shop.id, user_id: users).joins(:item)

          # Просмотр в категории
          if filter[:category_viewed].present? && filter[:category_viewed].to_i == 1
            # Если указаны категории
            users_relation = users_relation.where('category_ids IS NOT NULL AND category_ids && ARRAY[?]::varchar[]', filter[:category_view]) if filter[:category_view].present?

            # Если указаны бренды
            users_relation = users_relation.where(items: { brand: filter[:category_view_brand] }) if filter[:category_view_brand].present?

            # Добавляем дату просмотра
            users_relation = users_relation.where('view_date >= ?', Time.current - filter[:category_view_period].to_i.days)
          end

          # Покупка в категории
          if filter[:category_purchased].present? && filter[:category_purchased].to_i == 1
            # Если указаны категории
            users_relation = users_relation.where('category_ids IS NOT NULL AND category_ids && ARRAY[?]::varchar[]', filter[:category_purchase]) if filter[:category_purchase].present?

            # Если указаны бренды
            users_relation = users_relation.where(items: { brand: filter[:category_purchase_brand] }) if filter[:category_purchase_brand].present?

            # Добавляем дату просмотра
            users_relation = users_relation.where('purchase_date >= ?', Time.current - filter[:category_purchase_period].to_i.days)
          end

          # Достаем список юзеров
          users = users_relation.pluck('DISTINCT "actions".user_id')
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
      if users.present?
        # Добавляем сегмент к клиентам
        shop.clients.where(user_id: users).update_all("segment_ids = array_append(segment_ids, #{segment_id})")
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