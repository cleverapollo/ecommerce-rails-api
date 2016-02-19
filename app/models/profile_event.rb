# Модель еще не доделана.
# Подразумевается, что здесь мы будем копить все плоские данные по профилю и после этого пересчитывать их
# в атомарные значения для модели User.
# Таким образом откажемся от Mongo.
class ProfileEvent < MasterTable
  belongs_to :user

  class << self

    def relink_user(options = {})
      master_user = options.fetch(:to)
      slave_user = options.fetch(:from)
      where(user_id: slave_user.id).each do |slave_row|
        master_row = find_by(user_id: master_user.id, shop_id: slave_row.shop_id, industry: slave_row.industry, category: slave_row.category, property: slave_row.property,  value: slave_row.value)
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
          if hash_for_update.keys.any?
            master_row.update hash_for_update
          end
          slave_row.delete
        else
          slave_row.update user_id: master_user.id
        end
      end
    end



    def track(item, event)

      # Работаем только с поддерживаемыми событиями
      return if !%w(views carts purchases).include?(event)

      # TODO: доделать трекинг

    end



  end

end
