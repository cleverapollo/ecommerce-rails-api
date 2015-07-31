##
# Сессия.
#
class Session < ActiveRecord::Base

  establish_connection MASTER_DB


  include UserLinkable

  validates :code, presence: true

  class << self
    # Получить подходящую по параметрам сессию.
    def fetch(params = {})
      ActiveRecord::Base.transaction do
        session = nil

        if params[:code].present? && session = find_by(code: params[:code])
          # Найти сессию по коду.

          # Убедиться, что у сессии есть юзер.

          if session.user.blank?
            session.create_user
          end

          # Сохранить параметры бразуера в сессию.
          [:useragent, :city, :country, :language].each do |field|
            if session.send(field).blank? && params[field].present?
              session.send("#{field}=", params[:field])
            end
          end

          session.save if session.changed?
        else
          # Создать новую, сгенерировать код и юзера.
          session = create_with_code_and_user(params)
        end

        session
      end
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
      user = User.create!

      s = build_with_code
      s.assign_attributes(user: user,
                          useragent: params[:useragent],
                          country: params[:country].present? ? params[:country] : nil,
                          city: params[:city].present? ? params[:city] : nil,
                          language: params[:language])
      s.save!
      s
    end
  end
end
