class Session < ActiveRecord::Base
  belongs_to :user

  class << self
    def fetch(opts = {})
      session = find_by(uniqid: opts[:uniqid])

      if session.present?
        if session.user.blank?
          session.create_user
        end
      else
        session = create_with_uniqid_and_user(opts)
      end

      session
    end

    def create_with_uniqid_and_user(options = {})
      user = User.create

      loop do
        uuid = SecureRandom.uuid

        if Session.where(uniqid: uuid).none?
          return self.create(uniqid: uuid, user: user, useragent: options[:useragent])
        end
      end
    end
  end
end
