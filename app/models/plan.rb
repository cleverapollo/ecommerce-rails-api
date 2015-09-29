##
# Тариф
#
class Plan < MasterTable

  has_many :shops

  def free?
    plan_type == 'free'
  end
end
