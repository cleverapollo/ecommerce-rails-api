class PropertyCalculatorWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  # Собирает всю информацию о профиле юзера по email
  # todo Возможно нужно вынести в отдельный сервис, который будет только этим и заниматься
  def perform(email)

    # Находим все сессии клиента по email
    sessions = Client.where(email: email).where.not(session_id: nil).pluck(:session_id)
    return if sessions.blank?

    properties = hash_with_default_hash
    properties[:id] = email
    properties[:gender] = UserProfile::PropertyCalculator.new.calculate_gender(sessions)
    properties[:fashion_sizes] = UserProfile::PropertyCalculator.new.calculate_fashion_sizes(sessions)
    properties[:compatibility] = UserProfile::PropertyCalculator.new.calculate_compatibility(sessions)
    properties[:children] = UserProfile::PropertyCalculator.new.calculate_children (sessions)

    # Обновляем профиль в Elastic
    People::Profile.new(properties.compact).save
  ensure
    ActiveRecord::Base.clear_active_connections!
    ActiveRecord::Base.connection.close
  end

  private

  # Динамическое создание ключей в кеше, как это реализовано в нормальных языках
  def hash_with_default_hash
    Hash.new { |hash, key| hash[key] = hash_with_default_hash }
  end
end
