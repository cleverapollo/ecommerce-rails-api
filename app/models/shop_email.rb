class ShopEmail < ActiveRecord::Base
  belongs_to :shop

  validates :shop_id, :email, presence: true

  before_save :fix_empty_segment

  scope :email_confirmed, -> { where(email_confirmed: true) }
  scope :with_segment, -> (segment_id) { where('shop_emails.segment_ids @> ARRAY[?]', segment_id) }
  scope :with_segments, -> (segment_ids) { where('shop_emails.segment_ids && ARRAY[?]::int[]', segment_ids) }
  scope :suitable_for_digest_mailings, -> { where(digests_enabled: true) }
  scope :with_clients, -> { joins('LEFT JOIN clients ON clients.shop_id = shop_emails.shop_id AND clients.email = shop_emails.email') }

  class << self

    # Создает или возвращает ранее созданный
    # @param [Shop] shop
    # @param [String] email Сюда должен попадать уже проверенный и валидный email
    # @param [Client] client
    # @param [Boolean] result
    def fetch(shop, email, client: nil, result: false)
      ShopEmail.connection.insert(ActiveRecord::Base.send(:sanitize_sql_array, [
          'INSERT INTO shop_emails (shop_id, email, digests_enabled, triggers_enabled, segment_ids) VALUES(?, ?, ?, ?, ?) ON CONFLICT (shop_id, email) DO NOTHING', shop.id, email, client.try(:digests_enabled), client.try(:triggers_enabled), client.try(:segment_ids)
      ]))
      ShopEmail.find_by!(shop: shop, email: email) if result
    end

  end

  # @param [Symbol] mailings_type Тип отписки / подписки
  # @param [Boolean] subscribe Подписываемся / Отписываемся
  # @param [String] mail_code Код письма
  def unsubscribe_from(mailings_type, subscribe, mail_code = nil)
    client = Client.find_by(email: email, shop_id: shop_id)

    case mailings_type.to_sym
      when :digest
        update_columns(digests_enabled: subscribe)
        DigestMail.where(code: mail_code).update_all(unsubscribed: subscribe ? nil : true) if mail_code.present?

        # todo удалить, поддержка старой версии
        client.update_columns(digests_enabled: subscribe) if client.present?
      when :trigger
        update_columns(triggers_enabled: subscribe)
        TriggerMail.where(code: mail_code).update_all(unsubscribed: subscribe ? nil : true) if mail_code.present?

        # todo удалить, поддержка старой версии
        client.update_columns(triggers_enabled: subscribe) if client.present?
      else
        false
    end
  end

  def purge_email!
    if self.email.present?
      InvalidEmail.connection.insert(ActiveRecord::Base.send(:sanitize_sql_array, [
          'INSERT INTO invalid_emails (email, reason, created_at, updated_at) VALUES(?, ?, ?, ?) ON CONFLICT (email) DO NOTHING', self.email, 'mark_as_bounced', Time.now, Time.now
      ]))

      # Отключаем все подписки, но email не удаляем, чтобы повторно не включать
      update(digests_enabled: false, triggers_enabled: false)
    end
  end

  # Добавляет сегмент
  # @param [Integer] segment_id
  def add_segment(segment_id)
    self.segment_ids ||= []
    self.segment_ids << segment_id unless self.segment_ids.include? segment_id
    self
  end

  protected

  # Исправляет значение сегмента, если пустой массив
  def fix_empty_segment
    self.segment_ids = nil if !self.segment_ids.nil? && self.segment_ids.empty?
  end

end
