# Модель еще не доделана.
# Подразумевается, что здесь мы будем копить все плоские данные по профилю и после этого пересчитывать их
# в атомарные значения для модели User.
# Таким образом откажемся от Mongo.

# Назначение полей:
# user_id – идентификатор покупателя (пользователя)
# shop_id - идентификатор магазина, в котором происходит событие
# industry - отрасль, к которой относится событие: Recommender::Base::MODIFICATIONS
# property - свойство профиля: gender, size_shoe, size_coat, hyppoalergenic, etc.
# value - значение свойства: m|f (gender), 38 (size), etc.
# views - количество просмотров такого товара
# carts - количество добавлений в корзину такого товара
# purchases - количество покупок такого товара

class ProfileEvent < MasterTable
  belongs_to :user
  belongs_to :shop

  class << self

    def relink_user(options = {})
      master_user = options.fetch(:to)
      slave_user = options.fetch(:from)
      where(user_id: slave_user.id).each do |slave_row|
        master_row = find_by(user_id: master_user.id, shop_id: slave_row.shop_id, industry: slave_row.industry, property: slave_row.property,  value: slave_row.value)
        if master_row
          hash_for_update = {}
          hash_for_update[:views] = (slave_row.views + master_row.views) if slave_row.views.present? && master_row.views.present?
          hash_for_update[:views] = slave_row.views if slave_row.views.present? && !master_row.views.present?
          hash_for_update[:views] = master_row.views if !slave_row.views.present? && master_row.views.present?
          hash_for_update[:carts] = (slave_row.carts + master_row.carts) if slave_row.carts.present? && master_row.carts.present?
          hash_for_update[:carts] = slave_row.carts if slave_row.carts.present? && !master_row.carts.present?
          hash_for_update[:carts] = master_row.carts if !slave_row.carts.present? && master_row.carts.present?
          hash_for_update[:purchases] = (slave_row.purchases + master_row.purchases) if slave_row.purchases.present? && master_row.purchases.present?
          hash_for_update[:purchases] = slave_row.purchases if slave_row.purchases.present? && !master_row.purchases.present?
          hash_for_update[:purchases] = master_row.purchases if !slave_row.purchases.present? && master_row.purchases.present?
          master_row.update hash_for_update unless hash_for_update.empty?
          slave_row.delete
        else
          slave_row.update user_id: master_user.id
        end
      end
    end



    # Записывает пользователю для каждого товара отраслевые характеристики в историю действий
    # для последующего изменения свойств профиля.
    # @param user [User]
    # @param shop [Shop]
    # @param action [Action]
    # @param items [Item[]] Array of items
    # @return Boolean
    # @throws Exception
    def track_items(user, shop, action, items)

      # Check
      return unless %w(view cart purchase).include?(action)
      raise Exception.new('Items collection is empty') unless items.any?
      raise Exception.new('User is not provided') if user.class != User

      # Определяем имя количественного поля по типу события (views, carts, purchases)
      counter_field_name = action.pluralize.to_sym

      # Хеш обновлений свойств пользователя
      properties_to_update = {}

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
              profile_event = ProfileEvent.find_or_create_by user_id: user.id, shop_id: shop.id, industry: 'cosmetic', property: 'hypoallergenic', value: '1'
              profile_event.update counter_field_name => profile_event.public_send(counter_field_name).to_i + 1
              properties_to_update[:allergy] = UserProfile::PropertyCalculator.new.calculate_allergy user
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
              item.fashion_sizes.each do |size|
                profile_event = ProfileEvent.find_or_create_by user_id: user.id, shop_id: shop.id, industry: 'fashion', property: "size_#{item.fashion_wear_type}", value: size
                profile_event.update counter_field_name => profile_event.public_send(counter_field_name).to_i + 1
                properties_to_update[:fashion_sizes] = UserProfile::PropertyCalculator.new.calculate_fashion_sizes user
              end
            end

          end

        end

      end

      # Если есть поля для обновления пользователя – обновляем
      user.update properties_to_update unless properties_to_update.empty?

      true
    end



  end

end
