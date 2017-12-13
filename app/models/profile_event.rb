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
    def track_items(user, shop, action, items, niche_attributes = nil)

      # Check
      return unless %w(view cart purchase).include?(action)
      raise Exception.new('Items collection is empty') unless items.any?
      raise Exception.new('User is not provided') if user.class != User

      # Определяем имя количественного поля по типу события (views, carts, purchases)
      counter_field_name = action.pluralize.to_sym

      # Хеш обновлений свойств пользователя
      properties_to_update = Hash.recursive

      # Для каждого товара записываем событие, если товар отраслевой
      items.each do |item|

        # Секция детей сложная и включает в себя другие секции (одежда, косметика), поэтому первоочередно проверяем ее
        if item.is_child?

          # ** Товары для детей

          # Пол ребенка
          if item.child_gender.present?
            profile_event = ProfileEvent.find_or_create_by user_id: user.id, shop_id: shop.id, industry: 'child', property: 'gender', value: item.child_gender
            profile_event.update counter_field_name => profile_event.public_send(counter_field_name).to_i + 1
          end

          # Детский возраст (минимум, максимум)
          if item.child_age_min.present? || item.child_age_max.present?
            profile_event = ProfileEvent.find_or_create_by user_id: user.id, shop_id: shop.id, industry: 'child', property: 'age', value: "#{item.child_age_min}_#{item.child_age_max}_#{item.child_gender}"
            profile_event.update counter_field_name => profile_event.public_send(counter_field_name).to_i + 1
            properties_to_update[:children] = UserProfile::PropertyCalculator.new.calculate_children user
          end

        else

          # ** Товары не для детей

          # Косметика
          if item.is_cosmetic?

            # Пол косметики
            if item.cosmetic_gender.present?
              profile_event = ProfileEvent.find_or_create_by user_id: user.id, shop_id: shop.id, industry: 'cosmetic', property: 'gender', value: item.cosmetic_gender
              profile_event.update counter_field_name => profile_event.public_send(counter_field_name).to_i + 1
              properties_to_update[:gender] = UserProfile::PropertyCalculator.new.calculate_gender user
            end

            # Волосы
            if item.cosmetic_hair_type.present? || item.cosmetic_hair_condition.present?

              # Тип волос
              if item.cosmetic_hair_type.present? && item.cosmetic_hair_type.try(:any?)
                item.cosmetic_hair_type.each do |value|
                  profile_event = ProfileEvent.find_or_create_by user_id: user.id, shop_id: shop.id, industry: 'cosmetic', property: 'hair_type', value: value
                  profile_event.update counter_field_name => profile_event.public_send(counter_field_name).to_i + 1
                end
              end

              # Состояние волос
              if item.cosmetic_hair_condition.present? && item.cosmetic_hair_condition.try(:any?)
                item.cosmetic_hair_condition.each do |value|
                  profile_event = ProfileEvent.find_or_create_by user_id: user.id, shop_id: shop.id, industry: 'cosmetic', property: 'hair_condition', value: value
                  profile_event.update counter_field_name => profile_event.public_send(counter_field_name).to_i + 1
                end
              end

              # Рассчитываем волосы для обновления пользователя
              properties_to_update[:cosmetic_hair] = UserProfile::PropertyCalculator.new.calculate_hair user

            end

            # Кожа - работает обязательно с частями тела. Без частей тела остальное не имеет значения. Но по-умолчанию сделать часть тела - все тело.
            if !item.cosmetic_skin_part.nil? && item.cosmetic_skin_part.any? && ( (!item.cosmetic_skin_type.nil? && item.cosmetic_skin_type.any?) || (!item.cosmetic_skin_condition.nil? && item.cosmetic_skin_condition.any?) )

              # Тип кожи
              if !item.cosmetic_skin_part.nil? && item.cosmetic_skin_part.any? && !item.cosmetic_skin_type.nil? && item.cosmetic_skin_type.any?
                item.cosmetic_skin_part.each do |part|
                  item.cosmetic_skin_type.each do |type|
                    profile_event = ProfileEvent.find_or_create_by user_id: user.id, shop_id: shop.id, industry: 'cosmetic', property: "skin_type_#{part}", value: type
                    profile_event.update counter_field_name => profile_event.public_send(counter_field_name).to_i + 1
                  end
                end
              end

              # Состояние кожи
              if !item.cosmetic_skin_part.nil? && item.cosmetic_skin_part.any? && !item.cosmetic_skin_condition.nil? && item.cosmetic_skin_condition.any?
                item.cosmetic_skin_part.each do |part|
                  item.cosmetic_skin_condition.each do |condition|
                    profile_event = ProfileEvent.find_or_create_by user_id: user.id, shop_id: shop.id, industry: 'cosmetic', property: "skin_condition_#{part}", value: condition
                    profile_event.update counter_field_name => profile_event.public_send(counter_field_name).to_i + 1
                  end
                end
              end

              # Рассчитываем кожу для обновления пользователя
              properties_to_update[:cosmetic_skin] = UserProfile::PropertyCalculator.new.calculate_skin user

            end

            # Гипоаллергенность
            if item.cosmetic_hypoallergenic?
              ProfileEvent.track_event(user, shop, 'cosmetic', 'hypoallergenic', '1', counter_field_name)
              properties_to_update[:allergy] = UserProfile::PropertyCalculator.new.calculate_allergy user
            end

            # Ногти
            if item.cosmetic_nail_type.present?
              ProfileEvent.track_event(user, shop, 'cosmetic', 'nail_type', item.cosmetic_nail_type, counter_field_name)
              # properties_to_update[:cosmetic_nail] = UserProfile::PropertyCalculator.new.calculate_nail user
            end

            # Парфюмерия
            ProfileEvent.track_event(user, shop, 'cosmetic', 'perfume_aroma', item.cosmetic_perfume_aroma, counter_field_name) if item.cosmetic_perfume_aroma.present?
            ProfileEvent.track_event(user, shop, 'cosmetic', 'perfume_family', item.cosmetic_perfume_family, counter_field_name) if item.cosmetic_perfume_family.present?
            if item.cosmetic_perfume_aroma.present? || item.cosmetic_perfume_family.present?
              properties_to_update[:cosmetic_perfume] = UserProfile::PropertyCalculator.new.calculate_perfume user
            end

            # Товар для профессионалов
            if item.cosmetic_professional?
              ProfileEvent.track_event(user, shop, 'cosmetic', 'professional', '1', counter_field_name)
            end

          end


          # FMCG
          if item.is_fmcg?

            # Гипоаллергенность
            if item.fmcg_hypoallergenic?
              profile_event = ProfileEvent.find_or_create_by user_id: user.id, shop_id: shop.id, industry: 'fmcg', property: 'hypoallergenic', value: '1'
              profile_event.update counter_field_name => profile_event.public_send(counter_field_name).to_i + 1
              properties_to_update[:allergy] = UserProfile::PropertyCalculator.new.calculate_allergy user
            end

          end

          # Одежда
          if item.is_fashion?

            # Пол одежды для взрослых
            if item.fashion_gender.present?
              profile_event = ProfileEvent.find_or_create_by user_id: user.id, shop_id: shop.id, industry: 'fashion', property: 'gender', value: item.fashion_gender
              profile_event.update counter_field_name => profile_event.public_send(counter_field_name).to_i + 1
              properties_to_update[:gender] = UserProfile::PropertyCalculator.new.calculate_gender user
            end

            # Размеры одежды
            if item.fashion_wear_type.present? && item.fashion_sizes.present? && item.fashion_sizes.any?
              # Если есть override размера одежды из корзины или покупки, используем его, иначе берем все размеры
              if niche_attributes && niche_attributes.key?(item.id) && niche_attributes[item.id].present? && niche_attributes[item.id][:fashion_size]
                size = niche_attributes[item.id][:fashion_size]
                profile_event = ProfileEvent.find_or_create_by user_id: user.id, shop_id: shop.id, industry: 'fashion', property: "size_#{item.fashion_wear_type}", value: size
                profile_event.update counter_field_name => profile_event.public_send(counter_field_name).to_i + 1
              else
                item.fashion_sizes.each do |size|
                  profile_event = ProfileEvent.find_or_create_by user_id: user.id, shop_id: shop.id, industry: 'fashion', property: "size_#{item.fashion_wear_type}", value: size
                  profile_event.update counter_field_name => profile_event.public_send(counter_field_name).to_i + 1
                end
              end
              properties_to_update[:fashion_sizes] = UserProfile::PropertyCalculator.new.calculate_fashion_sizes user
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
                profile_event = ProfileEvent.find_or_create_by user_id: user.id, shop_id: shop.id, industry: 'auto', property: 'compatibility_brand', value: brand
                profile_event.update counter_field_name => profile_event.public_send(counter_field_name).to_i + 1
              end
            end

            # Модель
            if item.auto_compatibility['models'].present?
              item.auto_compatibility['models'].each do |model|
                if model.present?
                  profile_event = ProfileEvent.find_or_create_by user_id: user.id, shop_id: shop.id, industry: 'auto', property: 'compatibility_model', value: model
                  profile_event.update counter_field_name => profile_event.public_send(counter_field_name).to_i + 1
                end
              end
            end
            properties_to_update[:compatibility] = UserProfile::PropertyCalculator.new.calculate_compatibility user
          end

          # VIN
          if item.auto_vds.present?
            item.auto_vds.each do |vds|
              # Марка
              profile_event = ProfileEvent.find_or_create_by user_id: user.id, shop_id: shop.id, industry: 'auto', property: 'vds', value: vds
              profile_event.update counter_field_name => profile_event.public_send(counter_field_name).to_i + 1
            end
            properties_to_update[:vds] = UserProfile::PropertyCalculator.new.calculate_vds user
          end

        end

        # Животные
        if item.is_pets?
          unless item.pets_type.nil?
            property_value = "type:#{item.pets_type}"
            property_value = "#{property_value};breed:#{item.pets_breed}" unless item.pets_breed.nil?
            property_value = "#{property_value};age:#{item.pets_age}" unless item.pets_age.nil?
            property_value = "#{property_value};size:#{item.pets_size}" unless item.pets_size.nil?
            profile_event = ProfileEvent.find_or_create_by user_id: user.id, shop_id: shop.id, industry: 'pets', property: 'type', value: property_value
            profile_event.update counter_field_name => profile_event.public_send(counter_field_name).to_i + 1
          end
        end


        # Ювелирные украшения
        if item.is_jewelry?

          # Предпочтения к металлу
          if item.jewelry_metal
            profile_event = ProfileEvent.find_or_create_by user_id: user.id, shop_id: shop.id, industry: 'jewelry', property: 'metal', value: item.jewelry_metal.downcase
            profile_event.update counter_field_name => profile_event.public_send(counter_field_name).to_i + 1
          end

          # Предпочтения к драгоценным камням
          if item.jewelry_gem
            profile_event = ProfileEvent.find_or_create_by user_id: user.id, shop_id: shop.id, industry: 'jewelry', property: 'gem', value: item.jewelry_gem.downcase
            profile_event.update counter_field_name => profile_event.public_send(counter_field_name).to_i + 1
          end

          # Предпочтения к цвету украшения
          if item.jewelry_color
            profile_event = ProfileEvent.find_or_create_by user_id: user.id, shop_id: shop.id, industry: 'jewelry', property: 'color', value: item.jewelry_color.downcase
            profile_event.update counter_field_name => profile_event.public_send(counter_field_name).to_i + 1
          end

          # Предпочтения к полу
          if item.jewelry_gender && %w(f m).include?(item.jewelry_gender)
            profile_event = ProfileEvent.find_or_create_by user_id: user.id, shop_id: shop.id, industry: 'jewelry', property: 'gender', value: item.jewelry_gender
            profile_event.update counter_field_name => profile_event.public_send(counter_field_name).to_i + 1
          end


          # Размер кольца
          if item.ring_sizes.present? && item.ring_sizes.any?
            item.ring_sizes.each do |size|
              if size.to_s.strip.present?
                profile_event = ProfileEvent.find_or_create_by user_id: user.id, shop_id: shop.id, industry: 'jewelry', property: 'ring_size', value: size.to_s.strip
                profile_event.update counter_field_name => profile_event.public_send(counter_field_name).to_i + 1
              end
            end
          end

          # Размер браслета
          if item.bracelet_sizes.present? && item.bracelet_sizes.any?
            item.bracelet_sizes.each do |size|
              if size.to_s.strip.present?
                profile_event = ProfileEvent.find_or_create_by user_id: user.id, shop_id: shop.id, industry: 'jewelry', property: 'bracelet_size', value: size.to_s.strip
                profile_event.update counter_field_name => profile_event.public_send(counter_field_name).to_i + 1
              end
            end
          end

          # Размер цепочки
          if item.chain_sizes.present? && item.chain_sizes.any?
            item.chain_sizes.each do |size|
              if size.to_s.strip.present?
                profile_event = ProfileEvent.find_or_create_by user_id: user.id, shop_id: shop.id, industry: 'jewelry', property: 'chain_size', value: size.to_s.strip
                profile_event.update counter_field_name => profile_event.public_send(counter_field_name).to_i + 1
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
            ProfileEvent.track_event(user, shop, 'real_estate', "#{item.realty_type}_#{item.realty_action}", property_value, counter_field_name)
          end
        end
      end



      # Если есть животные товары, то пересчитать животный профиль
      if items.select { |x| x.is_pets? }.any?
        properties_to_update[:pets] = UserProfile::PropertyCalculator.new.calculate_pets user
      end

      # Если есть ювелирные товары, пересчитываем ювелирный профиль
      if items.select { |x| x.is_jewelry? }.any?
        properties_to_update[:jewelry] = UserProfile::PropertyCalculator.new.calculate_jewelry user
      end

      if items.select { |x| x.is_realty? }.any?
        properties_to_update[:realty] = UserProfile::PropertyCalculator.new.calculate_realty user
      end

      # Если есть поля для обновления пользователя – обновляем
      user.update properties_to_update unless properties_to_update.empty?

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
      profile_event = ProfileEvent.find_or_create_by user_id: user.id, shop_id: shop.id, industry: industry, property: property, value: value
      profile_event.update counter_field_name => profile_event.public_send(counter_field_name).to_i + 1
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
