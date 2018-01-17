require 'rails_helper'

describe UserProfile::PropertyCalculator do

  let!(:shop) { create(:shop) }
  let!(:user) { create(:user) }
  let!(:session) { create(:session, user: user) }

  def create_profile_event(industry, property, value, views: 0, carts: 0, purchases: 0, s: session)
    views.times { |i| create(:profile_event_cl, shop: shop, session: s, industry: industry, property: property, value: value, event: 'view') }
    carts.times { |i| create(:profile_event_cl, shop: shop, session: s, industry: industry, property: property, value: value, event: 'cart') }
    purchases.times { |i| create(:profile_event_cl, shop: shop, session: s, industry: industry, property: property, value: value, event: 'purchase') }
  end

  describe '.calculate_gender' do
    before do
      create_profile_event('fashion', 'gender', 'm', views: 1, carts: 2, purchases: 3)
      create_profile_event('fashion', 'gender', 'f', views: 1, carts: 2, purchases: 3)
    end

    subject { UserProfile::PropertyCalculator.new.calculate_gender(session.id) }

    context 'gender undefined' do
      let!(:profile_event_1) { create(:profile_event, shop: shop, user: user, industry: 'fashion', property: 'gender', value: 'm', views: 1, carts: 2, purchases: 3) }
      let!(:profile_event_2) { create(:profile_event, shop: shop, user: user, industry: 'fashion', property: 'gender', value: 'f', views: 1, carts: 2, purchases: 3) }

      it 'returns undefined gender when both genders history is equal' do
        expect(subject).to be_nil
      end
    end


    context 'calculates as usual' do
      let!(:profile_event_1) { create(:profile_event, shop: shop, user: user, industry: 'fashion', property: 'gender', value: 'm', views: 1, carts: 2, purchases: 3) }
      let!(:profile_event_2) { create(:profile_event, shop: shop, user: user, industry: 'fashion', property: 'gender', value: 'f', views: 2, carts: 2, purchases: 3) }
      before { create_profile_event('fashion', 'gender', 'f', views: 1) }

      it 'returns female' do
        expect(subject).to eq 'f'
      end
    end

    context 'purchases more important' do
      let!(:profile_event_1) { create(:profile_event, shop: shop, user: user, industry: 'fashion', property: 'gender', value: 'f', carts: 2) }
      let!(:profile_event_2) { create(:profile_event, shop: shop, user: user, industry: 'cosmetic', property: 'gender', value: 'm', purchases: 1) }
      before do
        create_profile_event('fashion', 'gender', 'f', carts: 2)
        create_profile_event('fashion', 'gender', 'm', purchases: 1)
      end

      it 'returns male because purchase more important' do
        expect(subject).to eq 'm'
      end
    end

    context 'for a more sessions' do
      before do
        99.times do |i|
          session = Session.create!(user: user)
        end
        s = Session.create!(user: user)
        create_profile_event('fashion', 'gender', 'f', views: 1, s: s)
      end

      it 'for 101 sessions' do
        sessions = user.sessions.pluck(:id).sort
        expect(sessions.count).to eq(101)
        expect(UserProfile::PropertyCalculator.new.calculate_gender(sessions)).to eq('f')
      end
    end
  end

  describe '.calculate_fashion_sizes' do

    subject { UserProfile::PropertyCalculator.new.calculate_fashion_sizes(session.id) }

    context 'no events' do

      it 'returns nil' do
        expect(subject).to eq nil
      end

    end

    context 'with valid events' do
      before do
        create_profile_event('fashion', 'size_shoe', '38', purchases: 3)
        create_profile_event('fashion', 'size_shoe', '39', views: 2, carts: 2, purchases: 2)
        create_profile_event('fashion', 'size_shoe', '40', views: 1, carts: 1)
        create_profile_event('fashion', 'size_coat', '33', views: 1)
      end

      it 'calculates two sizes' do
        expect(subject['shoe']).to eq [38, 39]
        expect(subject['coat']).to eq [33]
      end

    end


  end


  describe 'calculate hair' do

    let!(:profile_event_1) { create(:profile_event, shop: shop, user: user, industry: 'cosmetic', property: 'hair_type', value: 'long', carts: 2) }
    let!(:profile_event_2) { create(:profile_event, shop: shop, user: user, industry: 'cosmetic', property: 'hair_type', value: 'short', purchases: 2) }
    let!(:profile_event_3) { create(:profile_event, shop: shop, user: user, industry: 'cosmetic', property: 'hair_condition', value: 'oily', purchases: 1, views: 2) }
    let!(:profile_event_4) { create(:profile_event, shop: shop, user: user, industry: 'cosmetic', property: 'hair_condition', value: 'damage', purchases: 1, carts: 1, views: 1) }

    subject { UserProfile::PropertyCalculator.new.calculate_hair(user) }

    it 'calculates hair' do
      expect(subject[:type]).to eq 'short'
      expect(subject[:condition]).to eq 'damage'
    end

  end

  describe 'calculate skin' do

    let!(:profile_event_1) { create(:profile_event, shop: shop, user: user, industry: 'cosmetic', property: 'skin_type_body', value: 'dry', purchases: 2 ) }
    let!(:profile_event_2) { create(:profile_event, shop: shop, user: user, industry: 'cosmetic', property: 'skin_type_body', value: 'normal', views: 1, carts: 2 ) }
    let!(:profile_event_3) { create(:profile_event, shop: shop, user: user, industry: 'cosmetic', property: 'skin_type_hand', value: 'normal', carts: 1 ) }
    let!(:profile_event_4) { create(:profile_event, shop: shop, user: user, industry: 'cosmetic', property: 'skin_condition_hand', value: 'damage', carts: 2 ) }
    let!(:profile_event_5) { create(:profile_event, shop: shop, user: user, industry: 'cosmetic', property: 'skin_condition_body', value: 'soft', carts: 2 ) }

    subject { UserProfile::PropertyCalculator.new.calculate_skin(user) }

    it 'calculates skin' do
      expect(subject['hand']['type']).to eq ['normal']
      expect(subject['hand']['condition']).to eq ['damage']
      expect(subject['body']['type']).to eq ['dry', 'normal']
      expect(subject['body']['condition']).to eq ['soft']
    end

  end

  describe 'calculate perfume' do

    let!(:profile_event_1) { create(:profile_event, shop: shop, user: user, industry: 'cosmetic', property: 'perfume_aroma', value: 'floral', purchases: 2 ) }
    let!(:profile_event_2) { create(:profile_event, shop: shop, user: user, industry: 'cosmetic', property: 'perfume_aroma', value: 'citrus', views: 1, carts: 2 ) }
    let!(:profile_event_3) { create(:profile_event, shop: shop, user: user, industry: 'cosmetic', property: 'perfume_aroma', value: 'woody', carts: 1 ) }
    let!(:profile_event_4) { create(:profile_event, shop: shop, user: user, industry: 'cosmetic', property: 'perfume_aroma', value: 'oriental', carts: 2 ) }

    subject { UserProfile::PropertyCalculator.new.calculate_perfume(user) }

    it 'calculates aroma' do
      expect(subject['aroma']).to eq(%w(citrus floral))
    end
  end


  describe 'calculate allergy' do

    let!(:profile_event_1) { create(:profile_event, shop: shop, user: user, industry: 'fmcg', property: 'hypoallergenic', value: '1', carts: 2) }
    let!(:profile_event_2) { create(:profile_event, shop: shop, user: user, industry: 'cosmetic', property: 'hypoallergenic', value: '1', purchases: 1, carts: 1) }

    subject { UserProfile::PropertyCalculator.new.calculate_allergy(user) }

    it 'calculates allergy' do
      expect(subject).to be_truthy
    end

  end



  describe 'calculate children' do
    before do
      create_profile_event('child', 'age', '0.25_2.0_m', purchases: 2)
      create_profile_event('child', 'age', '_3.0_f', views: 1, carts: 2)
      create_profile_event('child', 'age', '3_5_f', carts: 1)
      create_profile_event('child', 'age', '3_5_', carts: 2)
      create_profile_event('child', 'age', '0.5__m', carts: 2)
    end
    subject { UserProfile::PropertyCalculator.new.calculate_children(session.id) }

    context 'without "push_attributes_children (birthdays)"' do

      it 'calculates children' do
        result = subject
        expect(result.count).to eq 2
        expect(result.first).to eq ({gender: 'm', age: 0.5..1.0})
        expect(result.last).to eq ({gender: 'f', age: 1.5..3.0})
      end
    end

    context 'child growing up' do
      before do
        5.times { create(:profile_event_cl, shop: shop, session: session, industry: 'child', property: 'age', value: '0.25_2.0_m', event: 'purchase', date: 1.year.ago.to_date, created_at: 1.year.ago) }
      end

      it 'calculates children' do
        result = subject
        expect(result.count).to eq 2
        expect(result.first).to eq ({gender: 'm', age: 1.25..3.0})
        expect(result.last).to eq ({gender: 'f', age: 1.5..3.0})
      end
    end

    # describe 'with "push_attributes_children (birthdays)"' do
    #   let!(:profile_event_6) { create(:profile_event, shop: shop, user: user, industry: 'child', property: 'push_attributes_children', value: 'gender:m;birthday:2010-01-01' ) }
    #   let!(:profile_event_7) { create(:profile_event, shop: shop, user: user, industry: 'child', property: 'push_attributes_children', value: 'gender:m;birthday:2016-11-01' ) }
    #
    #   subject { UserProfile::PropertyCalculator.new.calculate_children(session.id) }
    #
    #   it 'calculates children' do
    #     expect(subject.count).to eq 4
    #     expect(subject.first).to eq ({ gender: "m", age_min: 0.5, age_max: 1.0 })
    #     expect(subject.last).to eq ({ gender: "f", age_min: 1.5, age_max: 3.0 })
    #   end
    # end

  end

  describe 'calculate compatibility' do

    before do
      create_profile_event('auto', 'compatibility_brand', 'Audi', purchases: 2)
      create_profile_event('auto', 'compatibility_brand', 'BMW', views: 1, carts: 2)
      create_profile_event('auto', 'compatibility_model', 'A4', carts: 2)
      create_profile_event('auto', 'compatibility_model', 'W300', carts: 2)
    end

    subject { UserProfile::PropertyCalculator.new.calculate_compatibility(session.id) }

    it 'calculates compatibility' do
      expect(subject.count).to eq 2
      expect(subject.symbolize_keys).to eq ({brand: %w(Audi BMW), model: %w(A4 W300)})
    end
  end

  describe 'calculate vds' do
    before do
      create_profile_event('auto', 'vds', 'W300', carts: 2)
      create_profile_event('auto', 'vds', 'A4345G', purchases: 1)
      create_profile_event('auto', 'vds', 'AFR3', views: 10)
    end

    subject { UserProfile::PropertyCalculator.new.calculate_vds(session.id) }

    it 'calculates vds' do
      expect(subject.count).to eq 2
      expect(subject).to eq (%w(A4345G AFR3))
    end
  end


  describe 'pets' do
    subject { UserProfile::PropertyCalculator.new.calculate_pets(user) }
    before {
      create(:profile_event, shop: shop, user: user, industry: 'pets', property: 'type', value: 'type:dog;breed:strange;age:old;size:small', views: 1 )
      create(:profile_event, shop: shop, user: user, industry: 'pets', property: 'type', value: 'type:dog;breed:strange;age:old;size:small', views: 2 )
      create(:profile_event, shop: shop, user: user, industry: 'pets', property: 'type', value: 'type:dog;age:young;size:medium', views: 3 )
      create(:profile_event, shop: shop, user: user, industry: 'pets', property: 'type', value: 'type:dog;age:old;size:medium', views: 3 )
      create(:profile_event, shop: shop, user: user, industry: 'pets', property: 'type', value: 'type:cat;breed:cat terrier;size:large', carts: 2 )
      create(:profile_event, shop: shop, user: user, industry: 'pets', property: 'type', value: 'type:cat;breed:strange;age:middle', purchases: 1 )
    }
    it 'calculates pets' do
      expect(subject.size).to eq 2
      expect(subject[0]).to eq ({'type' => 'cat', 'breed' => 'strange', 'age' => 'middle', 'score' => 5})
      expect(subject[1]).to eq ({'type' => 'cat', 'breed' => 'cat terrier', 'size' => 'large', 'score' => 4})
      # expect(subject[2]).to eq ({'type' => 'dog', 'age' => 'old', 'size' => 'medium', 'score' => 3})
      # expect(subject[3]).to eq ({'type' => 'dog', 'age' => 'young', 'size' => 'medium', 'score' => 3})
      # expect(subject[4]).to eq ({'type' => 'dog', 'breed' => 'strange', 'age' => 'old', 'size' => 'small', 'score' => 3})
    end
  end

  describe 'real_estate' do
    subject { UserProfile::PropertyCalculator.new.calculate_realty(user) }
    before {
      create(:profile_event, shop: shop, user: user, industry: 'real_estate', property: 'office_rent', value: "90.0", views: 1 )
      create(:profile_event, shop: shop, user: user, industry: 'real_estate', property: 'office_sale', value: '770.0', views: 2 )
      create(:profile_event, shop: shop, user: user, industry: 'real_estate', property: 'custom_rent', value: '324.0', views: 3 )
      create(:profile_event, shop: shop, user: user, industry: 'real_estate', property: 'custom_rent', value: '160.0', purchases: 1 )
      create(:profile_event, shop: shop, user: user, industry: 'real_estate', property: 'warehouse_rent', value: '460.5', views: 3 )
      create(:profile_event, shop: shop, user: user, industry: 'real_estate', property: 'warehouse_rent', value: '17334.0', carts: 2 )
      create(:profile_event, shop: shop, user: user, industry: 'real_estate', property: 'warehouse_rent', value: '1000.0', purchases: 3 )
    }
    it 'calculates realties' do
      expect(subject.size).to eq 2
      expect(subject['rent']).to eq ({ type: "warehouse", space: "1000.0" })
      expect(subject['sale']).to eq ({ type: "office", space: "770.0" })
    end
  end

  describe 'calculates cosmetic nails' do
    subject { UserProfile::PropertyCalculator.new.calculate_nail(user) }
    before {
      create(:profile_event, shop: shop, user: user, industry: 'cosmetic', property: 'nail_type', value: 'polish_red', views: 2 )
      create(:profile_event, shop: shop, user: user, industry: 'cosmetic', property: 'nail_type', value: 'tool', views: 3 )
      create(:profile_event, shop: shop, user: user, industry: 'cosmetic', property: 'nail_type', value: 'tool', carts: 2 )
      create(:profile_event, shop: shop, user: user, industry: 'cosmetic', property: 'nail_type', value: 'gel', views: 3 )
      create(:profile_event, shop: shop, user: user, industry: 'cosmetic', property: 'nail_type', value: 'gel', purchases: 3 )
    }
    it 'calculates nail' do
      expect(subject.size).to eq 3
      expect(subject).to eq ({ "gel"=>{"color"=>nil}, "tool"=>{"color"=>nil}, "polish"=>{"color"=>"red"} })
    end
  end


  describe 'jewelry' do
    subject { UserProfile::PropertyCalculator.new.calculate_jewelry(user) }
    before {
      create(:profile_event, shop: shop, user: user, industry: 'jewelry', property: 'metal', value: 'gold', views: 1 )
      create(:profile_event, shop: shop, user: user, industry: 'jewelry', property: 'metal', value: 'silver', views: 2 )
      create(:profile_event, shop: shop, user: user, industry: 'jewelry', property: 'color', value: 'blue', views: 3 )
      create(:profile_event, shop: shop, user: user, industry: 'jewelry', property: 'color', value: 'yellow', views: 4 )
      create(:profile_event, shop: shop, user: user, industry: 'jewelry', property: 'gem', value: 'diamond', carts: 2 )
      create(:profile_event, shop: shop, user: user, industry: 'jewelry', property: 'gem', value: 'ruby', purchases: 1 )
      create(:profile_event, shop: shop, user: user, industry: 'jewelry', property: 'gender', value: 'm', carts: 2 )
      create(:profile_event, shop: shop, user: user, industry: 'jewelry', property: 'gender', value: 'f', purchases: 1 )
      create(:profile_event, shop: shop, user: user, industry: 'jewelry', property: 'ring_size', value: '3', purchases: 1 )
      create(:profile_event, shop: shop, user: user, industry: 'jewelry', property: 'ring_size', value: '4', views: 3 )
      create(:profile_event, shop: shop, user: user, industry: 'jewelry', property: 'bracelet_size', value: '6', purchases: 1 )
      create(:profile_event, shop: shop, user: user, industry: 'jewelry', property: 'bracelet_size', value: '7', views: 3 )
      create(:profile_event, shop: shop, user: user, industry: 'jewelry', property: 'chain_size', value: '4', purchases: 1 )
      create(:profile_event, shop: shop, user: user, industry: 'jewelry', property: 'chain_size', value: '5', views: 3 )
    }
    it 'calculates metarials', :jewelry do
      expect(subject['metal']).to eq 'silver'
      expect(subject['color']).to eq 'yellow'
      expect(subject['gem']).to eq 'ruby'
      expect(subject['gender']).to eq 'f'
      expect(subject['ring_size']).to eq '3'
      expect(subject['bracelet_size']).to eq '6'
      expect(subject['chain_size']).to eq '4'
    end

  end


end
