# Копим данные о поведении пользователей над отраслевыми товарами и строим на
# их основе пользовательские профили.

# Назначение полей:
# user_id – идентификатор покупателя (пользователя)
# shop_id - идентификатор магазина, в котором происходит событие
# industry - отрасль, к которой относится событие: Recommender::Base::MODIFICATIONS
# property - свойство профиля: gender, size_shoe, size_coat, hyppoalergenic, etc.
# value - значение свойства: m|f (gender), 38 (size), etc.
# views - количество просмотров такого товара
# carts - количество добавлений в корзину такого товара
# purchases - количество покупок такого товара
class ProfileEvent < ActiveRecord::Base
  belongs_to :user
  belongs_to :shop

  class << self

    def relink_user(options = {})
      master_user = options.fetch(:to)
      slave_user = options.fetch(:from)
      where(user_id: slave_user.id).each do |slave_row|
        slave_row.merge_to(master_user)
      end
    end

    # @param [User] master
    # @param [Integer] slave_id
    def relink_user_remnants(master, slave_id)
      where(user_id: slave_id).each do |slave_row|
        slave_row.merge_to(master)
      end
    end


    # Записывает пользователю для каждого товара отраслевые характеристики в историю действий
    # для последующего изменения свойств профиля.
    # @param user [User]
    # @param shop [Shop]
    # @param action [Action]
    # @param items [Array<Item>] Array of items
    # @param niche_attributes [Hash] Niche attributes from tracking to override products values (sizes, etc) on cart or purchase
    # @return Boolean
    # @throws Exception
    def track_items(user, shop, action, items, options = {})
      niche_attributes = options[:niche_attributes]
      @session_id = options[:session_id]
      @current_session_code = options[:current_session_code]

      # Check
      return unless %w(view cart purchase).include?(action)
      raise Exception.new('Items collection is empty') unless items.any?
      raise Exception.new('User is not provided') if user.class != User

      # Определяем имя количественного поля по типу события (views, carts, purchases)
      counter_field_name = action.pluralize.to_sym

      # Хеш обновлений свойств пользователя
      properties_to_update = Hash.recursive
      for_update = false

      # Для каждого товара записываем событие, если товар отраслевой
      items.each do |item|

        # Секция детей сложная и включает в себя другие секции (одежда, косметика), поэтому первоочередно проверяем ее
        if item.is_child?

          # ** Товары для детей

          # Пол ребенка
          if item.child_gender.present?
            track_event(user, shop, 'child', 'gender', item.child_gender, counter_field_name)
            for_update = true
          end

          # Детский возраст (минимум, максимум)
          if item.child_age_min.present? || item.child_age_max.present?
            track_event(user, shop, 'child', 'age', "#{item.child_age_min}_#{item.child_age_max}_#{item.child_gender}", counter_field_name)
            #properties_to_update[:children] = UserProfile::PropertyCalculator.new.calculate_children @session_id
            for_update = true
          end

        else

          # ** Товары не для детей

          # Косметика
          if item.is_cosmetic?

            # Пол косметики
            if item.cosmetic_gender.present?
              track_event(user, shop, 'cosmetic', 'gender', item.cosmetic_gender, counter_field_name)
              # properties_to_update[:gender] = UserProfile::PropertyCalculator.new.calculate_gender @session_id
              for_update = true
            end

            # Волосы
            if item.cosmetic_hair_type.present? || item.cosmetic_hair_condition.present?

              # Тип волос
              if item.cosmetic_hair_type.present? && item.cosmetic_hair_type.try(:any?)
                item.cosmetic_hair_type.each do |value|
                  track_event(user, shop, 'cosmetic', 'hair_type', value, counter_field_name)
                  for_update = true
                end
              end

              # Состояние волос
              if item.cosmetic_hair_condition.present? && item.cosmetic_hair_condition.try(:any?)
                item.cosmetic_hair_condition.each do |value|
                  track_event(user, shop, 'cosmetic', 'hair_condition', value, counter_field_name)
                  for_update = true
                end
              end

              # Рассчитываем волосы для обновления пользователя
              # properties_to_update[:cosmetic_hair] = UserProfile::PropertyCalculator.new.calculate_hair user

            end

            # Кожа - работает обязательно с частями тела. Без частей тела остальное не имеет значения. Но по-умолчанию сделать часть тела - все тело.
            if !item.cosmetic_skin_part.nil? && item.cosmetic_skin_part.any? && ( (!item.cosmetic_skin_type.nil? && item.cosmetic_skin_type.any?) || (!item.cosmetic_skin_condition.nil? && item.cosmetic_skin_condition.any?) )

              # Тип кожи
              if !item.cosmetic_skin_part.nil? && item.cosmetic_skin_part.any? && !item.cosmetic_skin_type.nil? && item.cosmetic_skin_type.any?
                item.cosmetic_skin_part.each do |part|
                  item.cosmetic_skin_type.each do |type|
                    track_event(user, shop, 'cosmetic', "skin_type_#{part}", type, counter_field_name)
                    for_update = true
                  end
                end
              end

              # Состояние кожи
              if !item.cosmetic_skin_part.nil? && item.cosmetic_skin_part.any? && !item.cosmetic_skin_condition.nil? && item.cosmetic_skin_condition.any?
                item.cosmetic_skin_part.each do |part|
                  item.cosmetic_skin_condition.each do |condition|
                    track_event(user, shop, 'cosmetic', "skin_condition_#{part}", condition, counter_field_name)
                    for_update = true
                  end
                end
              end

              # Рассчитываем кожу для обновления пользователя
              # properties_to_update[:cosmetic_skin] = UserProfile::PropertyCalculator.new.calculate_skin user

            end

            # Гипоаллергенность
            if item.cosmetic_hypoallergenic?
              track_event(user, shop, 'cosmetic', 'hypoallergenic', '1', counter_field_name)
              # properties_to_update[:allergy] = UserProfile::PropertyCalculator.new.calculate_allergy user
              for_update = true
            end

            # Ногти
            if item.cosmetic_nail_type.present?
              value = item.cosmetic_nail_type
              value = "#{value}_#{item.cosmetic_nail_color}" if item.cosmetic_nail_color.present?
              track_event(user, shop, 'cosmetic', 'nail_type', value, counter_field_name)
            end

            # Парфюмерия
            track_event(user, shop, 'cosmetic', 'perfume_aroma', item.cosmetic_perfume_aroma, counter_field_name) if item.cosmetic_perfume_aroma.present?
            track_event(user, shop, 'cosmetic', 'perfume_family', item.cosmetic_perfume_family, counter_field_name) if item.cosmetic_perfume_family.present?
            if item.cosmetic_perfume_aroma.present? || item.cosmetic_perfume_family.present?
              # properties_to_update[:cosmetic_perfume] = UserProfile::PropertyCalculator.new.calculate_perfume user
              for_update = true
            end

            # Товар для профессионалов
            if item.cosmetic_professional?
              track_event(user, shop, 'cosmetic', 'professional', '1', counter_field_name)
              for_update = true
            end

          end


          # FMCG
          if item.is_fmcg?

            # Гипоаллергенность
            if item.fmcg_hypoallergenic?
              track_event(user, shop, 'fmcg', 'hypoallergenic', '1', counter_field_name)
              # properties_to_update[:allergy] = UserProfile::PropertyCalculator.new.calculate_allergy user
              for_update = true
            end

          end

          # Одежда
          if item.is_fashion?

            # Пол одежды для взрослых
            if item.fashion_gender.present?
              track_event(user, shop, 'fashion', 'gender', item.fashion_gender, counter_field_name)
              # properties_to_update[:gender] = UserProfile::PropertyCalculator.new.calculate_gender @session_id
              for_update = true
            end
            # Размеры одежды
            if item.fashion_wear_type.present? && item.fashion_sizes.present? && item.fashion_sizes.any?
              # Если есть override размера одежды из корзины или покупки, используем его, иначе берем все размеры
              if niche_attributes && niche_attributes.key?(item.id) && niche_attributes[item.id].present? && niche_attributes[item.id][:fashion_size]
                size = niche_attributes[item.id][:fashion_size]
                track_event(user, shop, 'fashion', "size_#{item.fashion_wear_type}", size, counter_field_name)
              else
                item.fashion_sizes.each do |size|
                  track_event(user, shop, 'fashion', "size_#{item.fashion_wear_type}", size, counter_field_name)
                end
              end
              # properties_to_update[:fashion_sizes] = UserProfile::PropertyCalculator.new.calculate_fashion_sizes @session_id
              for_update = true
            end

          end

        end

        # Авто
        if item.is_auto?

          # Марка и модель авто
          if item.auto_compatibility.present?

            # Марка
            if item.auto_compatibility['brands'].present?
              item.auto_compatibility['brands'].each do |brand|
                track_event(user, shop, 'auto', 'compatibility_brand', brand, counter_field_name)
              end
            end

            # Модель
            if item.auto_compatibility['models'].present?
              item.auto_compatibility['models'].each do |model|
                if model.present?
                  track_event(user, shop, 'auto', 'compatibility_brand', model, counter_field_name)
                end
              end
            end
            # properties_to_update[:compatibility] = UserProfile::PropertyCalculator.new.calculate_compatibility user
            for_update = true
          end

          # VIN
          if item.auto_vds.present?
            item.auto_vds.each do |vds|
              # Марка
              track_event(user, shop, 'auto', 'vds', vds, counter_field_name)
            end
            # properties_to_update[:vds] = UserProfile::PropertyCalculator.new.calculate_vds @session_id
            for_update = true
          end

        end

        # Животные
        if item.is_pets?
          unless item.pets_type.nil?
            property_value = "type:#{item.pets_type}"
            property_value = "#{property_value};breed:#{item.pets_breed}" unless item.pets_breed.nil?
            property_value = "#{property_value};age:#{item.pets_age}" unless item.pets_age.nil?
            property_value = "#{property_value};size:#{item.pets_size}" unless item.pets_size.nil?
            track_event(user, shop, 'pets', 'type', property_value, counter_field_name)
          end
        end


        # Ювелирные украшения
        if item.is_jewelry?

          # Предпочтения к металлу
          if item.jewelry_metal
            track_event(user, shop, 'jewelry', 'metal', item.jewelry_metal.downcase, counter_field_name)
          end

          # Предпочтения к драгоценным камням
          if item.jewelry_gem
            track_event(user, shop, 'jewelry', 'gem', item.jewelry_gem.downcase, counter_field_name)
          end

          # Предпочтения к цвету украшения
          if item.jewelry_color
            track_event(user, shop, 'jewelry', 'color', item.jewelry_color.downcase, counter_field_name)
          end

          # Предпочтения к полу
          if item.jewelry_gender && %w(f m).include?(item.jewelry_gender)
            track_event(user, shop, 'jewelry', 'gender', item.jewelry_gender, counter_field_name)
          end


          # Размер кольца
          if item.ring_sizes.present? && item.ring_sizes.any?
            item.ring_sizes.each do |size|
              if size.to_s.strip.present?
                track_event(user, shop, 'jewelry', 'ring_size', size.to_s.strip, counter_field_name)
              end
            end
          end

          # Размер браслета
          if item.bracelet_sizes.present? && item.bracelet_sizes.any?
            item.bracelet_sizes.each do |size|
              if size.to_s.strip.present?
                track_event(user, shop, 'jewelry', 'bracelet_size', size.to_s.strip, counter_field_name)
              end
            end
          end

          # Размер цепочки
          if item.chain_sizes.present? && item.chain_sizes.any?
            item.chain_sizes.each do |size|
              if size.to_s.strip.present?
                track_event(user, shop, 'jewelry', 'chain_size', size.to_s.strip, counter_field_name)
              end
            end
          end

        end

        if item.is_realty?
          unless item.realty_type.nil?

            property_value = if item.realty_space_final.present?
                               item.realty_space_final
                             else
                               if item.realty_space_max.present? && item.realty_space_min.present?
                                 (item.realty_space_max + item.realty_space_min).to_f / 2
                               else
                                 item.realty_space_max || item.realty_space_min
                               end
                             end
            track_event(user, shop, 'real_estate', "#{item.realty_type}_#{item.realty_action}", property_value, counter_field_name)
          end
        end
      end



      # Если есть животные товары, то пересчитать животный профиль
      if items.select { |x| x.is_pets? }.any?
        # properties_to_update[:pets] = UserProfile::PropertyCalculator.new.calculate_pets user
        for_update = true
      end

      if items.select { |x| x.cosmetic_nail_type? }.any?
        # properties_to_update[:cosmetic_nail] = UserProfile::PropertyCalculator.new.calculate_nail user
        for_update = true
      end

      # Если есть ювелирные товары, пересчитываем ювелирный профиль
      if items.select { |x| x.is_jewelry? }.any?
        # properties_to_update[:jewelry] = UserProfile::PropertyCalculator.new.calculate_jewelry user
        for_update = true
      end

      if items.select { |x| x.is_realty? }.any?
        # properties_to_update[:realty] = UserProfile::PropertyCalculator.new.calculate_realty user
        for_update = true
      end

      # Если есть поля для обновления пользователя – обновляем
      if for_update
        # user.update properties_to_update

        # ищем клиента в магазине по сессии (+ поддержка старой версии)
        client = Client.find_by(shop: shop, session_id: @session_id) || Client.find_by(shop: shop, user: user)
        # Отправляем в работу таск с ключом (email или код сессии)
        PropertyCalculatorWorker.perform_async(client.email.present? ? client.email : client.session.code) if client.present? && (client.email.present? || client.session.present?)
      end

      true
    end

    # Увеличивает счетчик у события или создает новое
    # @param user [User]
    # @param shop [Shop]
    # @param industry [String]
    # @param property [String]
    # @param value [String]
    # @param counter_field_name [Symbol]
    def track_event(user, shop, industry, property, value, counter_field_name)
      # profile_event = ProfileEvent.find_or_create_by user_id: user.id, shop_id: shop.id, industry: industry, property: property, value: value
      # profile_event.update counter_field_name => profile_event.public_send(counter_field_name).to_i + 1
      if @session_id.present? && @current_session_code.present?
        event = counter_field_name.to_s.classify.downcase
        push_clickhouse(shop, user, industry, property, value.to_s, event)
      end
    end

    # Записывает пользователю для каждого EventsController.push_attributes отраслевые характеристики
    # в историю действий, для последующего изменения свойств профиля.
    # @param user [User]
    # @param shop [Shop]
    # @param event [String]
    # @param attributes [Hash] - push_attributes
    # @return Boolean
    def track_push_attributes(user, shop, event, attributes)
      # Check
      return unless %w[push_attributes_children].include?(event)
      raise Exception.new('Attributes collection is empty') if attributes.blank?
      raise Exception.new('User is not provided') if user.class != User


      if event == 'push_attributes_children'
        # attributes[:kids] [Array<Hash>] Array of hashes { gender: 'm|f', birthday: "YYYY-mm-DD"}

        if attributes[:kids].present? && attributes[:kids].is_a?(Array)
          kids_by_push_attribute = []

          attributes[:kids].each do |children|
            next unless children.is_a?(Hash) && (children[:gender].present? || children[:birthday].present?)
            value = ''
            value = "gender:#{children[:gender]}" if UserProfile::Gender.valid_gender?(children[:gender])
            value = "#{value};birthday:#{children[:birthday]}" if UserProfile::DateParser.valid_child_date?(children[:birthday])

            next if value.blank?
            kids_by_push_attribute << ProfileEvent.find_or_create_by(user_id: user.id,
              shop_id: shop.id,
              industry: 'child',
              property: event,
              value: value)
          end
        end
      end
    end

    private

    def push_clickhouse(shop, user, industry, property, value, event)
      begin
        ClickhouseQueue.profile_events({
          session_id: @session_id,
          current_session_code: @current_session_code,
          shop_id: shop.id,
          event: event,
          industry: industry,
          property: property,
          value: value
        })
      rescue StandardError => e
        Rollbar.error 'Clickhouse profile_event insert error', e
      end
    end

  end


  # Перенос объекта к указанному юзеру
  # @param [User] user
  def merge_to(user)
    master_row = ProfileEvent.where(user_id: user.id, shop_id: self.shop_id, industry: self.industry, property: self.property, value: self.value).where.not(id: self.id).order(:id).limit(1)[0]
    if master_row.present?
      hash_for_update = {}
      hash_for_update[:views] = (self.views + master_row.views) if self.views.present? && master_row.views.present?
      hash_for_update[:views] = self.views if self.views.present? && !master_row.views.present?
      hash_for_update[:views] = master_row.views if !self.views.present? && master_row.views.present?
      hash_for_update[:carts] = (self.carts + master_row.carts) if self.carts.present? && master_row.carts.present?
      hash_for_update[:carts] = self.carts if self.carts.present? && !master_row.carts.present?
      hash_for_update[:carts] = master_row.carts if !self.carts.present? && master_row.carts.present?
      hash_for_update[:purchases] = (self.purchases + master_row.purchases) if self.purchases.present? && master_row.purchases.present?
      hash_for_update[:purchases] = self.purchases if self.purchases.present? && !master_row.purchases.present?
      hash_for_update[:purchases] = master_row.purchases if !self.purchases.present? && master_row.purchases.present?

      # created_at и updated_at тоже сливать - самый ранний created_at и самый поздний updated_at. Так сможем определять актуальность информации и динамически высчитывать возраст.
      if master_row.created_at.nil? && self.created_at.nil?
        hash_for_update[:created_at] = DateTime.current
      elsif !master_row.created_at.nil? && self.created_at.nil?
        hash_for_update[:created_at] = master_row.created_at
      elsif master_row.created_at.nil? && !self.created_at.nil?
        hash_for_update[:created_at] = self.created_at
      else
        hash_for_update[:created_at] = ( master_row.created_at > self.created_at ? self.created_at : master_row.created_at )
      end
      if master_row.updated_at.nil? && self.updated_at.nil?
        hash_for_update[:updated_at] = DateTime.current
      elsif !master_row.updated_at.nil? && self.updated_at.nil?
        hash_for_update[:updated_at] = master_row.updated_at
      elsif master_row.updated_at.nil? && !self.updated_at.nil?
        hash_for_update[:updated_at] = self.updated_at
      else
        hash_for_update[:updated_at] = ( master_row.updated_at > self.updated_at ? master_row.updated_at : self.updated_at )
      end

      master_row.update hash_for_update unless hash_for_update.empty?
      self.delete
    else
      self.update user_id: user.id
    end

  end

end
