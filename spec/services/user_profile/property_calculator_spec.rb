require 'rails_helper'

describe UserProfile::PropertyCalculator do

  describe '.calculate_gender' do
    let!(:shop) { create(:shop) }
    let!(:user) { create(:user) }
    let!(:profile_event_1) { create(:profile_event, shop: shop, user: user, industry: 'fashion', property: 'gender', value: 'm', views: 1, carts: 2, purchases: 3) }

    subject { UserProfile::PropertyCalculator.new.calculate_gender(user) }

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

      it 'returns female' do
        expect(subject).to eq 'f'
      end
    end

    context 'purchases more important' do
      let!(:profile_event_1) { create(:profile_event, shop: shop, user: user, industry: 'fashion', property: 'gender', value: 'f', carts: 2) }
      let!(:profile_event_2) { create(:profile_event, shop: shop, user: user, industry: 'cosmetic', property: 'gender', value: 'm', purchases: 1) }

      it 'returns male because purchase more important' do
        expect(subject).to eq 'm'
      end
    end
  end

  describe '.calculate_fashion_sizes' do

    let!(:shop) { create(:shop) }
    let!(:user) { create(:user) }


    subject { UserProfile::PropertyCalculator.new.calculate_fashion_sizes(user) }

    context 'no events' do

      it 'returns nil' do
        expect(subject).to eq nil
      end

    end

    context 'with valid events' do

      let!(:profile_event_1) { create(:profile_event, shop: shop, user: user, industry: 'fashion', property: 'size_shoe', value: '38', purchases: 3) }
      let!(:profile_event_2) { create(:profile_event, shop: shop, user: user, industry: 'fashion', property: 'size_shoe', value: '39', views: 1, carts: 2, purchases: 2) }
      let!(:profile_event_3) { create(:profile_event, shop: shop, user: user, industry: 'fashion', property: 'size_shoe', value: '40', views: 1, carts: 1) }
      let!(:profile_event_4) { create(:profile_event, shop: shop, user: user, industry: 'fashion', property: 'size_coat', value: '33', views: 1) }

      it 'calculates two sizes' do
        expect(subject['shoe']).to eq [38, 39]
        expect(subject['coat']).to eq [33]
      end

    end


  end


  describe 'calculate hair' do

    let!(:shop) { create(:shop) }
    let!(:user) { create(:user) }

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

    let!(:shop) { create(:shop) }
    let!(:user) { create(:user) }

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


  describe 'calculate allergy' do

    let!(:shop) { create(:shop) }
    let!(:user) { create(:user) }

    let!(:profile_event_1) { create(:profile_event, shop: shop, user: user, industry: 'fmcg', property: 'hypoallergenic', value: '1', carts: 2) }
    let!(:profile_event_2) { create(:profile_event, shop: shop, user: user, industry: 'cosmetic', property: 'hypoallergenic', value: '1', purchases: 1, carts: 1) }

    subject { UserProfile::PropertyCalculator.new.calculate_allergy(user) }

    it 'calculates allergy' do
      expect(subject).to be_truthy
    end

  end



  describe 'calculate children' do

    let!(:shop) { create(:shop) }
    let!(:user) { create(:user) }

    let!(:profile_event_1) { create(:profile_event, shop: shop, user: user, industry: 'child', property: 'age', value: '0.25_2.0_m', purchases: 2 ) }
    let!(:profile_event_2) { create(:profile_event, shop: shop, user: user, industry: 'child', property: 'age', value: '_3.0_f', views: 1, carts: 2 ) }
    let!(:profile_event_3) { create(:profile_event, shop: shop, user: user, industry: 'child', property: 'age', value: '3_5_f', carts: 1 ) }
    let!(:profile_event_4) { create(:profile_event, shop: shop, user: user, industry: 'child', property: 'age', value: '3_5_', carts: 2 ) }
    let!(:profile_event_5) { create(:profile_event, shop: shop, user: user, industry: 'child', property: 'age', value: '0.5__m', carts: 2 ) }

    subject { UserProfile::PropertyCalculator.new.calculate_children(user) }

    it 'calculates children' do
      expect(subject.count).to eq 2
      expect(subject.first).to eq ({gender: "m", age_min: 0.5, age_max: 1.0})
      expect(subject.last).to eq ({gender: "f", age_min: 1.5, age_max: 3.0})
    end

  end

  describe 'calculate compatibility' do

    let!(:shop) { create(:shop) }
    let!(:user) { create(:user) }

    let!(:profile_event_1) { create(:profile_event, shop: shop, user: user, industry: 'auto', property: 'compatibility_brand', value: 'Audi', purchases: 2 ) }
    let!(:profile_event_2) { create(:profile_event, shop: shop, user: user, industry: 'auto', property: 'compatibility_brand', value: 'BMW', views: 1, carts: 2 ) }
    let!(:profile_event_3) { create(:profile_event, shop: shop, user: user, industry: 'auto', property: 'compatibility_brand', value: 'Toyota', carts: 1 ) }
    let!(:profile_event_4) { create(:profile_event, shop: shop, user: user, industry: 'auto', property: 'compatibility_model', value: 'A4', carts: 2 ) }
    let!(:profile_event_5) { create(:profile_event, shop: shop, user: user, industry: 'auto', property: 'compatibility_model', value: 'W300', carts: 2 ) }
    let!(:profile_event_6) { create(:profile_event, shop: shop, user: user, industry: 'auto', property: 'vds', value: 'W300', carts: 2 ) }
    let!(:profile_event_7) { create(:profile_event, shop: shop, user: user, industry: 'auto', property: 'vds', value: 'A4345G', purchases: 1 ) }
    let!(:profile_event_8) { create(:profile_event, shop: shop, user: user, industry: 'auto', property: 'vds', value: 'AFR3', views: 10 ) }

    subject { UserProfile::PropertyCalculator.new.calculate_compatibility(user) }

    it 'calculates compatibility' do
      expect(subject.count).to eq 2
      expect(subject.symbolize_keys).to eq ({brand: %w(Audi BMW), model: %w(A4 W300)})
    end
  end

  describe 'calculate vds' do

    let!(:shop) { create(:shop) }
    let!(:user) { create(:user) }

    let!(:profile_event_1) { create(:profile_event, shop: shop, user: user, industry: 'auto', property: 'vds', value: 'W300', carts: 2 ) }
    let!(:profile_event_2) { create(:profile_event, shop: shop, user: user, industry: 'auto', property: 'vds', value: 'A4345G', purchases: 1 ) }
    let!(:profile_event_3) { create(:profile_event, shop: shop, user: user, industry: 'auto', property: 'vds', value: 'AFR3', views: 10 ) }

    subject { UserProfile::PropertyCalculator.new.calculate_vds(user) }

    it 'calculates vds' do
      expect(subject.count).to eq 2
      expect(subject).to eq (%w(A4345G AFR3))
    end
  end


  describe 'pets' do
    let!(:shop) { create(:shop) }
    let!(:user) { create(:user) }
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


  describe 'jewelry' do
    let!(:shop) { create(:shop) }
    let!(:user) { create(:user) }
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
