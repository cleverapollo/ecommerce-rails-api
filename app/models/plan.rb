##
# Тариф
#
class Plan < ActiveRecord::Base

  establish_connection MASTER_DB if !Rails.env.test?


  has_many :shops

  def free?
    plan_type == 'free'
  end
end
