class MasterTable < ActiveRecord::Base
  self.abstract_class = true
  establish_connection :"#{Rails.env}_master"


  protected

  # Prevent from changes models editable on main website
  def protect_it
    readonly!
  end

end