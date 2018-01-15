class PropertyCalculatorWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  # Собирает всю информацию о профиле юзера по email
  # todo Возможно нужно вынести в отдельный сервис, который будет только этим и заниматься
  def perform(key)

    # Если ключ состоит из email
    if key.include?('@')
      # Находим все сессии клиента по email
      sessions = Client.where(email: key).where.not(session_id: nil).pluck(:session_id)
      return if sessions.blank?
    else
      # Находим сессию по коду
      sessions = Session.find_by_code(key).try(:id)
      return if sessions.blank?
    end

    properties = Hash.recursive
    properties[:id] = key
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

end
