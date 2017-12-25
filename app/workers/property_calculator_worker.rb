class PropertyCalculatorWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  # Собирает всю информацию о профиле юзера по email
  # todo Возможно нужно вынести в отдельный сервис, который будет только этим и заниматься
  def perform(email)
    clients = Client.where(email: email).joins(:session).pluck('sessions.id, clients.user_id')
  end
end
