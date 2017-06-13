require 'rails_helper'

describe ProfileEvent do

  describe '.track_items' do

    let!(:customer) { create(:customer) }
    let!(:shop) { create(:shop, customer: customer) }
    let!(:user) { create(:user) }

    let!(:item_1) { create(:item, shop: shop, is_fashion: true, fashion_gender: 'm' ) }
    let!(:item_2) { create(:item, shop: shop, is_fashion: true, fashion_gender: 'f' ) }
    let!(:item_3) { create(:item, shop: shop, is_cosmetic: true, cosmetic_gender: 'm' ) }
    let!(:item_4) { create(:item, shop: shop, is_child: true, child_gender: 'm' ) }
    let!(:item_5) { create(:item, shop: shop, is_fashion: true, fashion_wear_type: 'shoe', fashion_sizes: [38, 39, 40] ) }
    let!(:item_6) { create(:item, shop: shop, is_fmcg: true, fmcg_hypoallergenic: true ) }
    let!(:item_7) { create(:item, shop: shop, is_cosmetic: true, cosmetic_hypoallergenic: true ) }
    let!(:item_8) { create(:item, shop: shop, is_cosmetic: true, cosmetic_hair_type: ['long'], cosmetic_hair_condition: ['oily'] ) }
    let!(:item_9) { create(:item, shop: shop, is_cosmetic: true, cosmetic_hair_type: ['long'], cosmetic_hair_condition: ['damage'] ) }

    let!(:item_10) { create(:item, shop: shop, is_cosmetic: true, cosmetic_skin_part: ['body'], cosmetic_skin_type: ['oily'], cosmetic_skin_condition: ['damage'] ) }
    let!(:item_11) { create(:item, shop: shop, is_cosmetic: true, cosmetic_skin_part: ['hand'], cosmetic_skin_type: ['normal'], cosmetic_skin_condition: ['tattoo'] ) }
    let!(:item_12) { create(:item, shop: shop, is_cosmetic: true, cosmetic_skin_part: ['leg'], cosmetic_skin_condition: ['tattoo'] ) }
    let!(:item_13) { create(:item, shop: shop, is_cosmetic: true, cosmetic_skin_part: ['hand'], cosmetic_skin_type: ['soft'] ) }

    let!(:item_14) { create(:item, shop: shop, is_child: true, child_age_min: 0.25, child_age_max: 2 ) }
    let!(:item_15) { create(:item, shop: shop, is_child: true, child_age_min: 0.25 ) }
    let!(:item_16) { create(:item, shop: shop, is_child: true, child_age_max: 2 ) }
    let!(:item_17) { create(:item, shop: shop, is_child: true, child_gender: 'm', child_age_max: 2 ) }

    let!(:item_18) { create(:item, shop: shop, is_pets: true, pets_type: 'dog', pets_size: 'small', pets_age: 'old', pets_breed: 'strange', pets_periodic: true) }
    let!(:item_19) { create(:item, shop: shop, is_pets: true, pets_type: 'dog', pets_size: 'medium', pets_age: 'young', pets_periodic: true) }
    let!(:item_20) { create(:item, shop: shop, is_pets: true, pets_type: 'cat', pets_size: 'large', pets_breed: 'cat terrier') }
    let!(:item_21) { create(:item, shop: shop, is_pets: true, pets_type: 'cat', pets_age: 'middle', pets_breed: 'strange', pets_periodic: true) }
    let!(:item_22) { create(:item, shop: shop, is_pets: true, pets_size: 'small', pets_age: 'old', pets_breed: 'strange') }
    let!(:item_23) { create(:item, shop: shop, is_pets: true, pets_type: 'dog', pets_size: 'small', pets_age: 'old', pets_breed: 'strange', pets_periodic: true) }

    let!(:item_24) { create(:item, shop: shop, is_jewelry: true, jewelry_color: 'yellow', jewelry_metal: 'gold', jewelry_gem: 'diamond', ring_sizes: [3,4,5], bracelet_sizes: [4,5,6], chain_sizes: [6,7,8], jewelry_gender: 'f') }
    let!(:item_25) { create(:item, shop: shop, is_jewelry: true, jewelry_color: 'white', jewelry_metal: 'silver', jewelry_gem: 'ruby', ring_sizes: [3,4,5], bracelet_sizes: [4,5,6], chain_sizes: [6,7,8], jewelry_gender: 'm') }

    let!(:item_26) { create(:item, shop: shop, is_cosmetic: true, cosmetic_nail_type: 'tool') }
    let!(:item_27) { create(:item, shop: shop, is_cosmetic: true, cosmetic_perfume_aroma: ['citrus', 'green']) }
    let!(:item_28) { create(:item, shop: shop, is_cosmetic: true, cosmetic_professional: true) }


    let!(:item_simple) { create(:item, shop: shop ) }

    let!(:action) { 'view' }

    context 'common calculations' do

      it 'saves 1 event' do
        expect{ ProfileEvent.track_items(user, shop, action, [item_1]) }.to change(ProfileEvent, :count).by 1
        profile_event = ProfileEvent.first
        expect(profile_event.views).to eq 1
      end

      it 'saves 2 events' do
        expect{ ProfileEvent.track_items(user, shop, action, [item_2, item_3]) }.to change(ProfileEvent, :count).by 2
      end

      it 'changes counters' do
        ProfileEvent.track_items(user, shop, action, [item_1])
        ProfileEvent.track_items(user, shop, action, [item_1])
        profile_event = ProfileEvent.first
        expect(profile_event.views).to eq 2
      end

    end

    context 'tracks cosmetic' do

      it 'saves customer gender for cosmetic' do
        ProfileEvent.track_items(user, shop, action, [item_3])
        profile_event = ProfileEvent.first
        expect(profile_event.industry).to eq 'cosmetic'
        expect(profile_event.property).to eq 'gender'
        expect(profile_event.value).to eq 'm'
        expect(user.reload.gender).to eq 'm'
      end

      it 'saves hair type and condition for cosmetic' do
        ProfileEvent.track_items(user, shop, 'view', [item_8, item_9, item_simple])
        ProfileEvent.track_items(user, shop, 'cart', [item_8, item_simple])
        ProfileEvent.track_items(user, shop, 'purchase', [item_9, item_simple])
        expect(ProfileEvent.count).to eq 3
        expect(ProfileEvent.find_by(industry: 'cosmetic', property: 'hair_condition', value: 'damage').views).to eq 1
        expect(ProfileEvent.find_by(industry: 'cosmetic', property: 'hair_condition', value: 'damage').purchases).to eq 1
        expect(ProfileEvent.find_by(industry: 'cosmetic', property: 'hair_condition', value: 'oily').views).to eq 1
        expect(ProfileEvent.find_by(industry: 'cosmetic', property: 'hair_condition', value: 'oily').carts).to eq 1
        expect(ProfileEvent.find_by(industry: 'cosmetic', property: 'hair_type', value: 'long').views).to eq 2
        expect(ProfileEvent.find_by(industry: 'cosmetic', property: 'hair_type', value: 'long').carts).to eq 1
        expect(ProfileEvent.find_by(industry: 'cosmetic', property: 'hair_type', value: 'long').purchases).to eq 1
        expect(user.reload.cosmetic_hair['condition']).to eq('damage')
        expect(user.reload.cosmetic_hair['type']).to eq('long')
      end

      it 'saves allergy for cosmetic' do
        ProfileEvent.track_items(user, shop, 'purchase', [item_7, item_simple])
        ProfileEvent.track_items(user, shop, 'purchase', [item_7, item_simple])
        ProfileEvent.track_items(user, shop, 'purchase', [item_7, item_simple])
        expect(ProfileEvent.count).to eq 1
        profile_event = ProfileEvent.first
        expect(profile_event.industry).to eq 'cosmetic'
        expect(profile_event.property).to eq 'hypoallergenic'
        expect(profile_event.value).to eq '1'
        expect(profile_event.purchases).to eq 3
        expect(user.reload.allergy).to be_truthy
      end

      it 'saves skin for cosmetic' do
        ProfileEvent.track_items(user, shop, 'purchase', [item_10, item_simple])
        ProfileEvent.track_items(user, shop, 'cart', [item_11, item_simple])
        ProfileEvent.track_items(user, shop, 'view', [item_12, item_simple])
        ProfileEvent.track_items(user, shop, 'purchase', [item_13, item_simple])
        expect(ProfileEvent.count).to eq 6
        expect(ProfileEvent.find_by(industry: 'cosmetic', property: 'skin_type_body', value: 'oily').purchases).to eq 1
        expect(ProfileEvent.find_by(industry: 'cosmetic', property: 'skin_condition_body', value: 'damage').purchases).to eq 1
        expect(ProfileEvent.find_by(industry: 'cosmetic', property: 'skin_type_hand', value: 'normal').carts).to eq 1
        expect(ProfileEvent.find_by(industry: 'cosmetic', property: 'skin_condition_hand', value: 'tattoo').carts).to eq 1
        expect(ProfileEvent.find_by(industry: 'cosmetic', property: 'skin_condition_leg', value: 'tattoo').views).to eq 1
        expect(ProfileEvent.find_by(industry: 'cosmetic', property: 'skin_type_hand', value: 'soft').purchases).to eq 1
        expect(user.reload.cosmetic_skin['leg']['condition']).to eq(['tattoo'])
        expect(user.reload.cosmetic_skin['hand']['condition']).to eq(['tattoo'])
        expect(user.reload.cosmetic_skin['hand']['type']).to eq(['soft'])
        expect(user.reload.cosmetic_skin['body']['type']).to eq(['oily'])
        expect(user.reload.cosmetic_skin['body']['condition']).to eq(['damage'])
      end

      it 'saves nail for cosmetic' do
        ProfileEvent.track_items(user, shop, 'view', [item_26, item_simple])
        ProfileEvent.track_items(user, shop, 'view', [item_26, item_simple])
        ProfileEvent.track_items(user, shop, 'cart', [item_26, item_simple])
        ProfileEvent.track_items(user, shop, 'purchase', [item_26, item_simple])
        expect(ProfileEvent.count).to eq 1
        expect(ProfileEvent.find_by(industry: 'cosmetic', property: 'nail_type', value: 'tool').views).to eq 2
        expect(ProfileEvent.find_by(industry: 'cosmetic', property: 'nail_type', value: 'tool').carts).to eq 1
        expect(ProfileEvent.find_by(industry: 'cosmetic', property: 'nail_type', value: 'tool').purchases).to eq 1
      end

      it 'saves perfume for cosmetic' do
        ProfileEvent.track_items(user, shop, 'view', [item_27, item_simple])
        ProfileEvent.track_items(user, shop, 'cart', [item_27, item_simple])
        ProfileEvent.track_items(user, shop, 'purchase', [item_27, item_simple])
        expect(ProfileEvent.count).to eq 2
        expect(ProfileEvent.find_by(industry: 'cosmetic', property: 'perfume_aroma', value: 'citrus').views).to eq 1
        expect(ProfileEvent.find_by(industry: 'cosmetic', property: 'perfume_aroma', value: 'citrus').carts).to eq 1
        expect(ProfileEvent.find_by(industry: 'cosmetic', property: 'perfume_aroma', value: 'citrus').purchases).to eq 1
        expect(ProfileEvent.find_by(industry: 'cosmetic', property: 'perfume_aroma', value: 'green').views).to eq 1
        expect(ProfileEvent.find_by(industry: 'cosmetic', property: 'perfume_aroma', value: 'green').carts).to eq 1
        expect(ProfileEvent.find_by(industry: 'cosmetic', property: 'perfume_aroma', value: 'green').purchases).to eq 1
      end

      it 'saves professional for cosmetic' do
        ProfileEvent.track_items(user, shop, 'view', [item_28, item_simple])
        ProfileEvent.track_items(user, shop, 'cart', [item_28, item_simple])
        ProfileEvent.track_items(user, shop, 'purchase', [item_28, item_simple])
        expect(ProfileEvent.count).to eq 1
        expect(ProfileEvent.find_by(industry: 'cosmetic', property: 'professional', value: '1').views).to eq 1
        expect(ProfileEvent.find_by(industry: 'cosmetic', property: 'professional', value: '1').carts).to eq 1
        expect(ProfileEvent.find_by(industry: 'cosmetic', property: 'professional', value: '1').purchases).to eq 1
      end

    end

    context 'tracks fmcg' do

      it 'saves allergy for fmcg' do
        ProfileEvent.track_items(user, shop, 'purchase', [item_6, item_simple])
        ProfileEvent.track_items(user, shop, 'purchase', [item_6, item_simple])
        ProfileEvent.track_items(user, shop, 'purchase', [item_6, item_simple])
        expect(ProfileEvent.count).to eq 1
        profile_event = ProfileEvent.first
        expect(profile_event.industry).to eq 'fmcg'
        expect(profile_event.property).to eq 'hypoallergenic'
        expect(profile_event.value).to eq '1'
        expect(profile_event.purchases).to eq 3
        expect(user.reload.allergy).to be_truthy
      end

    end

    context 'tracks fashion' do

      it 'saves fashion gender' do
        ProfileEvent.track_items(user, shop, action, [item_1])
        profile_event = ProfileEvent.first
        expect(profile_event.industry).to eq 'fashion'
        expect(profile_event.property).to eq 'gender'
        expect(profile_event.value).to eq 'm'
        expect(user.reload.gender).to eq 'm'
      end

      it 'saves fashion size' do
        expect{ ProfileEvent.track_items(user, shop, 'cart', [item_5]) }.to change(ProfileEvent, :count).by 3
        expect( ProfileEvent.where(industry: 'fashion', property: 'size_shoe', value: '38', carts: 1).count ).to eq 1
        expect( ProfileEvent.where(industry: 'fashion', property: 'size_shoe', value: '39', carts: 1).count ).to eq 1
        expect( ProfileEvent.where(industry: 'fashion', property: 'size_shoe', value: '40', carts: 1).count ).to eq 1
        expect(user.reload.fashion_sizes['shoe']).to eq [38, 39, 40]
      end

    end

    context 'tracks child' do

      it 'saves fashion gender' do
        ProfileEvent.track_items(user, shop, action, [item_4])
        profile_event = ProfileEvent.first
        expect(profile_event.industry).to eq 'child'
        expect(profile_event.property).to eq 'gender'
        expect(profile_event.value).to eq 'm'
      end

      it 'saves child age' do
        ProfileEvent.track_items(user, shop, 'view', [item_simple, item_14])
        ProfileEvent.track_items(user, shop, 'cart', [item_15])
        ProfileEvent.track_items(user, shop, 'purchase', [item_16])
        ProfileEvent.track_items(user, shop, 'purchase', [item_17]) # Создает две записи - с возрастом и отдельно с полом
        expect(ProfileEvent.count).to eq 5
        expect( ProfileEvent.find_by(industry: 'child', property: 'age', value: '0.25_2.0_').views ).to eq 1
        expect( ProfileEvent.find_by(industry: 'child', property: 'age', value: '0.25__').carts ).to eq 1
        expect( ProfileEvent.find_by(industry: 'child', property: 'age', value: '_2.0_').purchases ).to eq 1
        expect( ProfileEvent.find_by(industry: 'child', property: 'age', value: '_2.0_m').purchases ).to eq 1
      end


    end


    context 'track pets' do

      it 'saves correct pets' do
        ProfileEvent.track_items(user, shop, 'view', [item_18, item_19, item_20])
        ProfileEvent.track_items(user, shop, 'cart', [item_21, item_22, item_23])
        expect(ProfileEvent.count).to eq 4
        expect( ProfileEvent.find_by(industry: 'pets', property: 'type', value: 'type:dog;breed:strange;age:old;size:small').views ).to eq 1
        expect( ProfileEvent.find_by(industry: 'pets', property: 'type', value: 'type:dog;breed:strange;age:old;size:small').carts ).to eq 1
        expect( ProfileEvent.find_by(industry: 'pets', property: 'type', value: 'type:dog;age:young;size:medium').views ).to eq 1
        expect( ProfileEvent.find_by(industry: 'pets', property: 'type', value: 'type:cat;breed:cat terrier;size:large').views ).to eq 1
        expect( ProfileEvent.find_by(industry: 'pets', property: 'type', value: 'type:cat;breed:strange;age:middle').carts ).to eq 1

      end

    end


    context 'tracks jewelry' do

      it 'saves correct jewelry', :jewelry do
        ProfileEvent.track_items(user, shop, 'view', [item_24])
        ProfileEvent.track_items(user, shop, 'cart', [item_25])
        expect(ProfileEvent.count).to eq 17
        expect( ProfileEvent.find_by(industry: 'jewelry', property: 'gender', value: 'f').views ).to eq 1
        expect( ProfileEvent.find_by(industry: 'jewelry', property: 'gender', value: 'm').carts ).to eq 1
        expect( ProfileEvent.find_by(industry: 'jewelry', property: 'color', value: 'yellow').views ).to eq 1
        expect( ProfileEvent.find_by(industry: 'jewelry', property: 'color', value: 'white').carts ).to eq 1
        expect( ProfileEvent.find_by(industry: 'jewelry', property: 'metal', value: 'gold').views ).to eq 1
        expect( ProfileEvent.find_by(industry: 'jewelry', property: 'metal', value: 'silver').carts ).to eq 1
        expect( ProfileEvent.find_by(industry: 'jewelry', property: 'gem', value: 'diamond').views ).to eq 1
        expect( ProfileEvent.find_by(industry: 'jewelry', property: 'gem', value: 'ruby').carts ).to eq 1
        expect( ProfileEvent.find_by(industry: 'jewelry', property: 'ring_size', value: '3').views ).to eq 1
        expect( ProfileEvent.find_by(industry: 'jewelry', property: 'ring_size', value: '3').carts ).to eq 1
        expect( ProfileEvent.find_by(industry: 'jewelry', property: 'ring_size', value: '4').views ).to eq 1
        expect( ProfileEvent.find_by(industry: 'jewelry', property: 'ring_size', value: '4').views ).to eq 1
        expect( ProfileEvent.find_by(industry: 'jewelry', property: 'ring_size', value: '5').views ).to eq 1
        expect( ProfileEvent.find_by(industry: 'jewelry', property: 'ring_size', value: '5').carts ).to eq 1
        expect( ProfileEvent.find_by(industry: 'jewelry', property: 'bracelet_size', value: '4').views ).to eq 1
        expect( ProfileEvent.find_by(industry: 'jewelry', property: 'bracelet_size', value: '4').carts ).to eq 1
        expect( ProfileEvent.find_by(industry: 'jewelry', property: 'bracelet_size', value: '5').views ).to eq 1
        expect( ProfileEvent.find_by(industry: 'jewelry', property: 'bracelet_size', value: '5').views ).to eq 1
        expect( ProfileEvent.find_by(industry: 'jewelry', property: 'bracelet_size', value: '6').views ).to eq 1
        expect( ProfileEvent.find_by(industry: 'jewelry', property: 'bracelet_size', value: '6').carts ).to eq 1
        expect( ProfileEvent.find_by(industry: 'jewelry', property: 'chain_size', value: '6').views ).to eq 1
        expect( ProfileEvent.find_by(industry: 'jewelry', property: 'chain_size', value: '6').carts ).to eq 1
        expect( ProfileEvent.find_by(industry: 'jewelry', property: 'chain_size', value: '7').views ).to eq 1
        expect( ProfileEvent.find_by(industry: 'jewelry', property: 'chain_size', value: '7').views ).to eq 1
        expect( ProfileEvent.find_by(industry: 'jewelry', property: 'chain_size', value: '8').views ).to eq 1
        expect( ProfileEvent.find_by(industry: 'jewelry', property: 'chain_size', value: '8').carts ).to eq 1
      end

    end


  end



end
