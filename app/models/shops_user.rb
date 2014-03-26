class ShopsUser < ActiveRecord::Base
  belongs_to :shop
  belongs_to :user

  after_initialize :assign_ab_testing_group

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
