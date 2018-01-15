class DataManager::UserProfiles

  # Запускает перерасчет всех профилей в магазине
  def self.calculate_for_shop(shop_id)
    ActiveRecord::Base.logger.level = 1
    n = 0
    ShopEmail.where(shop_id: shop_id).find_each do |shop_email|
      n += 1

      # Запускаем расчет
      PropertyCalculatorWorker.new.perform(shop_email.email)

      STDOUT.write "\r#{n}"
      sleep(1) if n % 1000 == 0
    end
    STDOUT.write "\n"
    n
  end

end
