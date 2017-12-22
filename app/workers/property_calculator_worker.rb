class PropertyCalculatorWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  # Собирает всю информацию о профиле юзера по email
  # todo Возможно нужно вынести в отдельный сервис, который будет только этим и заниматься
  def perform(email)
    Client.where(email: email).each do
      # @type [Client] client
      |client|


    end
  end
end
