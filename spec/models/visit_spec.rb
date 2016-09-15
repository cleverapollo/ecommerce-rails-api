require 'rails_helper'

RSpec.describe Visit, :type => :model do

  describe ".validations" do

    it {
      expect{ Visit.create(user_id: 1, shop_id: 1, date: Date.current) }.to change(Visit, :count).from(0).to(1)
      expect{ Visit.create(user_id: 1, shop_id: 1, date: Date.current) }.to_not change(Visit, :count)
      expect{ Visit.create(user_id: 1, date: Date.current) }.to_not change(Visit, :count)
      expect{ Visit.create(user_id: 1, shop_id: 1 ) }.to_not change(Visit, :count)
      expect{ Visit.create(shop_id: 1, date: Date.current) }.to_not change(Visit, :count)
    }

  end

end
