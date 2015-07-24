##
# Тариф
#
class Plan < ActiveRecord::Base

  establish_connection MASTER_DB


  has_many :shops

  def free?
    plan_type == 'free'
  end
end
