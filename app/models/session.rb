##
# Сессия.
#
class Session < ActiveRecord::Base
  include RequestLogger

  # Хуки на запись сессии
  # after_save :record_session, if: Proc.new { |sess| sess.code == '2756db03-8e68-4e22-aee9-da1f0b12b0c2' }
  # after_initialize :record_session, if: Proc.new { |sess| sess.code == '2756db03-8e68-4e22-aee9-da1f0b12b0c2' }
  # around_save :record_session, if: Proc.new { |sess| sess.code == '2756db03-8e68-4e22-aee9-da1f0b12b0c2' }
  # before_update :record_session, if: Proc.new { |sess| sess.code == '2756db03-8e68-4e22-aee9-da1f0b12b0c2' }
  # after_update :record_session, if: Proc.new { |sess| sess.code == '2756db03-8e68-4e22-aee9-da1f0b12b0c2' }
  # after_commit :record_session, if: Proc.new { |sess| sess.code == '2756db03-8e68-4e22-aee9-da1f0b12b0c2' }

  # def record_session
  #   open('log/err_session.out', 'a') do |f|
  #     f << "\n\n\n-----------AFTER_SAVE--------#{Time.now}------------"
  #     f << self.inspect
  #     f << "\n"
  #     f << caller
  #     f << "\n"
  #     f << "-----------------------------------------------------"
  #     f << "\n\n\n\n"
  #   end
  # end


  include UserLinkable

  # Для партицируемых таблиц необходимо сначала получить ID, а потом создавать запись
  before_create :fetch_nextval

  validates :code, presence: true

  class << self

    # Поиск сессии по коду
    # @return [Session]
    def find_by_code(code)
      with_partition(code).find_by(code: code)
    end
    # @return [Session]
    def find_by_code!(code)
      find_by_code(code) or raise ActiveRecord::RecordNotFound.new("Couldn't find session")
    end

    # Получить подходящую по параметрам сессию.
    def fetch(params = {})
      session = nil

      # Если указан код
      if params[:code].present?

        # Если код в массиве
        if params[:code].is_a?(Array)

          # Ищем первую существующую сессию
          params[:code].each do |code|
            session = find_by_code(code)
            break if session.present?
          end
        else
          # Просто находим по коду
          session = find_by_code(params[:code])
        end
      end

      # Найти сессию по коду.
      if session.present?

        # Убедиться, что у сессии есть юзер.
        if session.user.blank?
          session.create_user
        end

        # Сохранить параметры бразуера в сессию.
        [:city, :country, :language].each do |field|
          if session.send(field).blank? && params[field].present?
            session.send("#{field}=", params[:field])
          end
        end

        session.atomic_save! if session.changed?
      else
        # Создать новую, сгенерировать код и юзера.
        session = create_with_code_and_user(params)
      end

      session
    end

    # Создать новую сессию с уникальным кодом.
    def build_with_code
      loop do
        code = SecureRandom.uuid

        if find_by_code(code).blank?
          return self.new(code: code)
        end
      end
    end

    # Создать новую сессию с уникальным кодом и пользователем.
    def create_with_code_and_user(params = {})
      user = User.atomic_create!

      s = build_with_code
      s.assign_attributes(user: user,
                          country: params[:country].present? ? params[:country] : nil,
                          city: params[:city].present? ? params[:city] : nil,
                          language: params[:language] ? params[:language] : nil)
      s.atomic_save!
      s
    end


    # Дополнительное условие нужно именно для того, чтобы планировщик знал, в какой партиции искать
    def with_partition(code)
      where('abs(hashtext(code)) % 10 = abs(hashtext(?)) % 10', code)
    end
  end

  # Переопределяем метод, т.к. при создании нового юзера, сессия не обновляется
  def create_user
    transaction do
      user = super
      atomic_save! if changed? && !new_record?
      user
    end
  end

  # Обновление текущей сессии с дополнительным фильтром для нужной партиции
  def atomic_save
    if new_record?
      super
    elsif changed?
      attrs = {}
      changed.each do |c|
        attrs[c] = self[c]
      end
      Session.with_partition(self.code).where(id: self.id).update_all(attrs)
    else
      true
    end
  end
  def atomic_save!
    atomic_save or raise ActiveRecordError.new('Session save not updated')
  end

  private

  def fetch_nextval
    self.id = Session.connection.select_value("SELECT nextval('sessions_id_seq')") unless self.id
  end

end
