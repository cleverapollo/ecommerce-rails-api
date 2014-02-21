class Session < ActiveRecord::Base
  belongs_to :user

  def self.create_with_uniqid_and_user(options = {})
    user = User.create

    loop do
      uuid = SecureRandom.uuid

      if Session.where(uniqid: uuid).none?
        return self.create(uniqid: uuid, user: user, useragent: options[:useragent])
      end
    end
  end
end
