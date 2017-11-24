# Токены мгновенной авторизации пользователя из ссылок в сервисных письмах.
# Ежедневно удаляем токены, которые были просрочены
class InstantAuthToken < ActiveRecord::Base
  before_create :set_date

  validates :token, uniqueness: true
  validates :customer_id, :token, presence: true
  belongs_to :customer

  class << self
    # Создает токен и возвращает объект
    # @param customer [Customer]
    # @return InstantAuthToken
    def fetch(customer)
      InstantAuthToken.create customer_id: customer.id, token: SecureRandom.uuid
    end

    # Удаляет устаревшие
    def cleanup
      InstantAuthToken.where('date <= ?', 2.days.ago).delete_all
    end

  end

  private

  def set_date
    self.date = Date.current if date.nil?
  end
end
