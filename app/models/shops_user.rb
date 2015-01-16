class ShopsUser < ActiveRecord::Base
  belongs_to :shop
  belongs_to :user

  before_create :assign_ab_testing_group

  validates :shop, presence: true

  scope :who_saw_subscription_popup, -> { where(subscription_popup_showed: true) }
  scope :with_email, -> { where('email IS NOT NULL') }

  protected
    def assign_ab_testing_group
      return if self.ab_testing_group.present?

      if shop.group_1_count.to_i > shop.group_2_count.to_i
        self.ab_testing_group = 2
      else
        self.ab_testing_group = 1
      end

      shop.send("group_#{self.ab_testing_group}_count").incr
    end
end
