class RemoveAbTestingGroupFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :ab_testing_group
  end
end
