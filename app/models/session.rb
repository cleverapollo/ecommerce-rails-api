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

    def build_with_uniqid
      loop do
        uuid = SecureRandom.uuid

        if Session.where(uniqid: uuid).none?
          return self.new(uniqid: uuid)
        end
      end
    end

    def create_with_uniqid_and_user(options = {})
      user = User.create

      s = build_with_uniqid
      s.assign_attributes(useragent: options[:useragent], user: user)
      s.save
      s
    end
  end
end
