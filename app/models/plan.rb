class Plan < ActiveRecord::Base
  has_many :shops

  def free?
    plan_type == 'free'
  end
end
