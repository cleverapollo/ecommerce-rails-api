class Session < ActiveRecord::Base
  belongs_to :user

  class << self
    def fetch(opts = {})
      session = nil

      if opts[:uniqid].present? && session = find_by(uniqid: opts[:uniqid])
        if session.user.blank?
          session.create_user
        end

        [:useragent, :city, :country, :language].each do |field|
          if session.send(field).blank? && opts[field].present?
            session.send("#{field}=", opts[:field])
          end
        end

        session.save if session.changed?
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
      s.assign_attributes \
                          user: user,
                          useragent: options[:useragent],
                          country: options[:country].present? ? options[:country] : nil,
                          city: options[:city].present? ? options[:city] : nil,
                          language: options[:language]
      s.save
      s
    end
  end
end
