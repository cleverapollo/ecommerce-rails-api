##
# Сессия.
#
class Session < MasterTable
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

  validates :code, presence: true
  attr_accessor :segment_changed

  class << self
    # Получить подходящую по параметрам сессию.
    def fetch(params = {})

      # Найти сессию по коду.
      session = params[:code].present? ? find_by(code: params[:code]) : nil
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

        if Session.find_by(code: code).blank?
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
  end
end
