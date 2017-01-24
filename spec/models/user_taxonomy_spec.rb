require 'rails_helper'

RSpec.describe UserTaxonomy, :type => :model do

  let!(:category) { create(:category, taxonomy: 'apparel') }
  let!(:shop) { create(:shop, category: category) }
  let!(:user) { create(:user) }
  let!(:item_category) { create(:item_category, shop: shop, taxonomy: 'shoes.keds', external_id: SecureRandom.uuid) }
  let!(:item) { create(:item, shop: shop, category_ids: [item_category.external_id] ) }

  subject { UserTaxonomy.track(user, [item], shop, 'view') }

  it 'tracks valid taxonomy' do
    expect{subject}.to change{ UserTaxonomy.count }.by(2)
    expect( UserTaxonomy.where(taxonomy: 'apparel.shoes.keds').exists ).to be_truthy
    expect( UserTaxonomy.find_by(taxonomy: 'apparel.shoes.keds').event ).to eq 'view'
    expect( UserTaxonomy.where(taxonomy: 'apparel').exists ).to be_truthy
    expect( UserTaxonomy.find_by(taxonomy: 'apparel').event ).to eq 'view'
  end

end
