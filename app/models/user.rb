class User < ActiveRecord::Base
  has_many :sessions
  has_many :actions

  after_initialize :assign_ab_testing_group

  protected

    def assign_ab_testing_group
      self.ab_testing_group = (rand(2) + 1) if self.ab_testing_group.blank?
    end
end
