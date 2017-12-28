require 'rails_helper'

describe ProfileEvent do
  let!(:customer) { create(:customer) }
  let!(:shop) { create(:shop, customer: customer) }
  let!(:user) { create(:user) }
  let!(:session) { create(:session, user: user) }
  let!(:client) { create(:client, :with_email, user: user, session: session, shop: shop) }

  describe '.track_items' do

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
    let!(:item_27) { create(:item, shop: shop, is_cosmetic: true, cosmetic_perfume_aroma: 'citrus', cosmetic_perfume_family: 'wood') }
    let!(:item_28) { create(:item, shop: shop, is_cosmetic: true, cosmetic_professional: true) }


    let!(:item_29) { create(:item, shop: shop, is_realty: true, realty_type: "office", realty_space_final: 90.0, realty_action: "rent")}
    let!(:item_30) { create(:item, shop: shop, is_realty: true, realty_type: "office", realty_space_final: 770.0, realty_action: "sale")}
    let!(:item_31) { create(:item, shop: shop, is_realty: true, realty_type: "custom", realty_space_final: 324.0, realty_action: "rent")}
    let!(:item_32) { create(:item, shop: shop, is_realty: true, realty_type: "custom", realty_space_final: 160.0, realty_action: "rent")}
    let!(:item_33) { create(:item, shop: shop, is_realty: true, realty_type: "warehouse", realty_space_min: 230.0, realty_space_max: 691.0, realty_action: "rent")}
    let!(:item_34) { create(:item, shop: shop, is_realty: true, realty_type: "warehouse", realty_space_final: 1000.0, realty_action: "rent")}
    let!(:item_35) { create(:item, shop: shop, is_realty: true, realty_type: "warehouse", realty_space_min: 6500.0, realty_space_max: 28168.0, realty_action: "rent")}

    let!(:item_36) { create(:item, shop: shop, is_cosmetic: true, cosmetic_nail_type: 'tool') }
    let!(:item_37) { create(:item, shop: shop, is_cosmetic: true, cosmetic_nail_type: 'tool') }
    let!(:item_38) { create(:item, shop: shop, is_cosmetic: true, cosmetic_nail_type: 'gel') }
    let!(:item_39) { create(:item, shop: shop, is_cosmetic: true, cosmetic_nail_type: 'polish', cosmetic_nail_color: 'red') }

    let!(:item_simple) { create(:item, shop: shop ) }
    let!(:session) { create(:session, user: user) }

    let!(:action) { 'view' }

    context 'common calculations' do

      it 'saves 1 event' do
        expect(ClickhouseQueue).to receive(:profile_events).once

        ProfileEvent.track_items(user, shop, action, [item_1], session_id: session.id, current_session_code: SecureRandom.uuid)
      end

      it 'saves 2 events' do
        expect(ClickhouseQueue).to receive(:profile_events).twice

        ProfileEvent.track_items(user, shop, action, [item_2, item_3], session_id: session.id, current_session_code: SecureRandom.uuid)
      end

      it 'changes counters' do
        expect(ClickhouseQueue).to receive(:profile_events).twice

        ProfileEvent.track_items(user, shop, action, [item_1], session_id: session.id, current_session_code: SecureRandom.uuid)
        ProfileEvent.track_items(user, shop, action, [item_1], session_id: session.id, current_session_code: SecureRandom.uuid)
      end

    end

    context 'tracks cosmetic' do

      it 'saves customer gender for cosmetic' do
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(event: action, industry: 'cosmetic', property: 'gender', value: 'm')).once
        expect(PropertyCalculatorWorker).to receive(:perform_async).with(client.email)

        ProfileEvent.track_items(user, shop, action, [item_3], session_id: session.id, current_session_code: SecureRandom.uuid)
      end

      it 'saves hair type and condition for cosmetic' do
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(event: 'view', industry: 'cosmetic', property: 'hair_condition', value: 'oily'))
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(event: 'view', industry: 'cosmetic', property: 'hair_type', value: 'long'))
        expect(PropertyCalculatorWorker).to receive(:perform_async).with(client.email)

        ProfileEvent.track_items(user, shop, 'view', [item_8, item_simple], session_id: session.id, current_session_code: SecureRandom.uuid)
      end

      it 'saves allergy for cosmetic' do
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(event: 'purchase', industry: 'cosmetic', property: 'hypoallergenic', value: '1'))
        expect(PropertyCalculatorWorker).to receive(:perform_async).with(client.email)

        ProfileEvent.track_items(user, shop, 'purchase', [item_7, item_simple], session_id: session.id, current_session_code: SecureRandom.uuid)
      end

      it 'saves skin for cosmetic' do
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(event: 'purchase', industry: 'cosmetic', property: 'skin_type_body', value: 'oily'))
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(event: 'purchase', industry: 'cosmetic', property: 'skin_condition_body', value: 'damage'))
        expect(PropertyCalculatorWorker).to receive(:perform_async).with(client.email)

        ProfileEvent.track_items(user, shop, 'purchase', [item_10, item_simple], session_id: session.id, current_session_code: SecureRandom.uuid)
      end

      it 'saves nail for cosmetic' do
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(event: 'view', industry: 'cosmetic', property: 'nail_type', value: 'tool')).exactly(3).times
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(event: 'view', industry: 'cosmetic', property: 'nail_type', value: 'gel'))
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(event: 'view', industry: 'cosmetic', property: 'nail_type', value: 'polish_red'))
        expect(PropertyCalculatorWorker).to receive(:perform_async).with(client.email)

        ProfileEvent.track_items(user, shop, 'view', [item_26, item_36, item_37, item_38, item_39, item_simple], session_id: session.id, current_session_code: SecureRandom.uuid)
      end

      it 'saves perfume for cosmetic' do
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(event: 'view', industry: 'cosmetic', property: 'perfume_aroma', value: 'citrus'))
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(event: 'view', industry: 'cosmetic', property: 'perfume_family', value: 'wood'))
        expect(PropertyCalculatorWorker).to receive(:perform_async).with(client.email)

        ProfileEvent.track_items(user, shop, 'view', [item_27, item_simple], session_id: session.id, current_session_code: SecureRandom.uuid)
      end

      it 'saves professional for cosmetic' do
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(event: 'view', industry: 'cosmetic', property: 'professional', value: '1'))
        expect(PropertyCalculatorWorker).to receive(:perform_async).with(client.email)

        ProfileEvent.track_items(user, shop, 'view', [item_28, item_simple], session_id: session.id, current_session_code: SecureRandom.uuid)
      end

    end

    context 'tracks fmcg' do

      it 'saves allergy for fmcg' do
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(event: 'purchase', industry: 'fmcg', property: 'hypoallergenic', value: '1'))
        expect(PropertyCalculatorWorker).to receive(:perform_async).with(client.email)

        ProfileEvent.track_items(user, shop, 'purchase', [item_6, item_simple], session_id: session.id, current_session_code: SecureRandom.uuid)
      end

    end

    context 'tracks fashion' do

      it 'saves fashion gender' do
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(event: action, industry: 'fashion', property: 'gender', value: 'm')).once
        expect(PropertyCalculatorWorker).to receive(:perform_async).with(client.email)

        ProfileEvent.track_items(user, shop, action, [item_1], session_id: session.id, current_session_code: SecureRandom.uuid)
      end

      it 'saves fashion size' do
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(event: 'cart', industry: 'fashion', property: 'size_shoe', value: '38'))
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(event: 'cart', industry: 'fashion', property: 'size_shoe', value: '39'))
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(event: 'cart', industry: 'fashion', property: 'size_shoe', value: '40'))
        expect(PropertyCalculatorWorker).to receive(:perform_async).with(client.email)

        ProfileEvent.track_items(user, shop, 'cart', [item_5], session_id: session.id, current_session_code: session.code)
      end

      it 'saves overrided value if exists' do
        niche_attributes = {}
        niche_attributes[item_5.id] = { fashion_size: '30' }
        options = { niche_attributes: niche_attributes, session_id: session.id, current_session_code: session.code }
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(session_id: session.id, current_session_code: session.code, shop_id: shop.id, event: 'cart', industry: 'fashion', property: 'size_shoe', value: '30')).once
        expect(PropertyCalculatorWorker).to receive(:perform_async).with(client.email)
        ProfileEvent.track_items(user, shop, 'cart', [item_5], options)
      end

    end

    context 'tracks child' do

      it 'saves fashion gender' do
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(event: 'view', industry: 'child', property: 'gender', value: 'm'))
        expect(PropertyCalculatorWorker).to receive(:perform_async).with(client.email)

        ProfileEvent.track_items(user, shop, action, [item_4], session_id: session.id, current_session_code: SecureRandom.uuid)
      end

      it 'saves child age' do
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(event: 'view', industry: 'child', property: 'age', value: '0.25_2.0_'))
        expect(PropertyCalculatorWorker).to receive(:perform_async).with(client.email)

        ProfileEvent.track_items(user, shop, 'view', [item_simple, item_14], session_id: session.id, current_session_code: SecureRandom.uuid)
      end

      it 'saves child age 2' do
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(event: 'cart', industry: 'child', property: 'age', value: '0.25__'))
        expect(PropertyCalculatorWorker).to receive(:perform_async).with(client.email)

        ProfileEvent.track_items(user, shop, 'cart', [item_15], session_id: session.id, current_session_code: SecureRandom.uuid)
      end

      it 'saves child age 3' do
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(event: 'purchase', industry: 'child', property: 'age', value: '_2.0_'))
        expect(PropertyCalculatorWorker).to receive(:perform_async).with(client.email)

        ProfileEvent.track_items(user, shop, 'purchase', [item_16], session_id: session.id, current_session_code: SecureRandom.uuid)
      end

      it 'saves child age 4' do
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(event: 'purchase', industry: 'child', property: 'age', value: '_2.0_m'))
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(event: 'purchase', industry: 'child', property: 'gender', value: 'm'))
        expect(PropertyCalculatorWorker).to receive(:perform_async).with(client.email)

        ProfileEvent.track_items(user, shop, 'purchase', [item_17], session_id: session.id, current_session_code: SecureRandom.uuid) # Создает две записи - с возрастом и отдельно с полом
      end


    end


    context 'track pets' do

      it 'saves correct pets' do
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(event: 'view', industry: 'pets', property: 'type', value: 'type:dog;breed:strange;age:old;size:small'))
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(event: 'view', industry: 'pets', property: 'type', value: 'type:dog;age:young;size:medium'))
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(event: 'view', industry: 'pets', property: 'type', value: 'type:cat;breed:cat terrier;size:large'))
        expect(PropertyCalculatorWorker).to receive(:perform_async).with(client.email)

        ProfileEvent.track_items(user, shop, 'view', [item_18, item_19, item_20], session_id: session.id, current_session_code: SecureRandom.uuid)
      end

    end


    context 'tracks jewelry' do

      it 'saves correct jewelry', :jewelry do
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(event: 'view', industry: 'jewelry', property: 'gender', value: 'f'))
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(event: 'view', industry: 'jewelry', property: 'color', value: 'yellow'))
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(event: 'view', industry: 'jewelry', property: 'metal', value: 'gold'))
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(event: 'view', industry: 'jewelry', property: 'gem', value: 'diamond'))
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(event: 'view', industry: 'jewelry', property: 'ring_size', value: '3'))
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(event: 'view', industry: 'jewelry', property: 'ring_size', value: '4'))
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(event: 'view', industry: 'jewelry', property: 'ring_size', value: '5'))
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(event: 'view', industry: 'jewelry', property: 'bracelet_size', value: '4'))
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(event: 'view', industry: 'jewelry', property: 'bracelet_size', value: '5'))
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(event: 'view', industry: 'jewelry', property: 'bracelet_size', value: '6'))
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(event: 'view', industry: 'jewelry', property: 'chain_size', value: '6'))
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(event: 'view', industry: 'jewelry', property: 'chain_size', value: '7'))
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(event: 'view', industry: 'jewelry', property: 'chain_size', value: '8'))
        expect(PropertyCalculatorWorker).to receive(:perform_async).with(client.email)

        ProfileEvent.track_items(user, shop, 'view', [item_24], session_id: session.id, current_session_code: SecureRandom.uuid)
      end

    end

    context 'track realty' do

      it 'saves count realties' do
        expect(PropertyCalculatorWorker).to receive(:perform_async).with(client.email).twice
        expect(ClickhouseQueue).to receive(:profile_events).exactly(7).times

        ProfileEvent.track_items(user, shop, 'view', [item_29, item_30, item_31], session_id: session.id, current_session_code: session.code)
        ProfileEvent.track_items(user, shop, 'cart', [item_32, item_33, item_34, item_35], session_id: session.id, current_session_code: session.code)
      end

      it 'saves correct realties' do
        expect(ClickhouseQueue).to receive(:profile_events).with(hash_including(event: 'view', industry: 'real_estate', property: 'office_rent', value: '90.0'))
        ProfileEvent.track_items(user, shop, 'view', [item_29], session_id: session.id, current_session_code: session.code)
      end

    end

  end

  describe '.track_push_attributes' do
    context 'tracks children attributes' do
      let(:attributes_1) { { kids: [{ gender: 'm', birthday: '2014-02-10' }, { gender: 'f', birthday: '2010-02-10' }] } }
      let(:attributes_2) { { kids: ['not valid'] } }
      let(:attributes_3) { { email: 'email@example.com' } }
      let(:attributes_4) { { kids: [{ gender: 'm' }] } }
      let(:attributes_5) { { kids: [{ gender: 'f', birthday: '2014/102-10' }] } }
      let(:attributes_6) { { kids: [{ gender: 'm', birthday: '1980-02-10' }] } }
      let(:attributes_7) { { kids: [{ birthday: '2014-12-10' }] } }
      let(:attributes_8) { { kids: [{ gender: 'x', birthday: '2014-02-10' }] } }
      let(:attributes_9) { { kids: [{ gender: 'x', birthday: '2014-200-100' }] } }

      it 'create two push_attributes_children events' do
        ProfileEvent.track_push_attributes(user, shop, 'push_attributes_children', attributes_1)
        expect(ProfileEvent.count).to eq 2
      end

      it 'do not create push_attributes_children event if format "kids" data is not valid' do
        ProfileEvent.track_push_attributes(user, shop, 'push_attributes_children', attributes_2)
        expect(ProfileEvent.count).to eq 0
      end

      it 'do not create push_attributes_children event without "kids" attribute data' do
        ProfileEvent.track_push_attributes(user, shop, 'push_attributes_children', attributes_3)
        expect(ProfileEvent.count).to eq 0
      end

      it 'create push_attributes_children event only with gender' do
        ProfileEvent.track_push_attributes(user, shop, 'push_attributes_children', attributes_4)
        expect(ProfileEvent.count).to eq 1
        expect(ProfileEvent.first.value.include?('gender:')).to eq true
        expect(ProfileEvent.first.value.include?('birthday:')).to eq false
      end

      it 'create push_attributes_children event only with gender if age is not valid format' do
        ProfileEvent.track_push_attributes(user, shop, 'push_attributes_children', attributes_5)
        expect(ProfileEvent.count).to eq 1
        expect(ProfileEvent.first.value.include?('gender:')).to eq true
        expect(ProfileEvent.first.value.include?('birthday:')).to eq false
      end

      it 'create push_attributes_children event only with gender if age is more than 18 years' do
        ProfileEvent.track_push_attributes(user, shop, 'push_attributes_children', attributes_6)
        expect(ProfileEvent.count).to eq 1
        expect(ProfileEvent.first.value.include?('gender:')).to eq true
        expect(ProfileEvent.first.value.include?('birthday:')).to eq false
      end

      it 'create push_attributes_children event only with age' do
        ProfileEvent.track_push_attributes(user, shop, 'push_attributes_children', attributes_7)
        expect(ProfileEvent.count).to eq 1
        expect(ProfileEvent.first.value.include?('birthday:')).to eq true
        expect(ProfileEvent.first.value.include?('gender:')).to eq false
      end

      it 'create push_attributes_children event only with age if gender is not valid' do
        ProfileEvent.track_push_attributes(user, shop, 'push_attributes_children', attributes_8)
        expect(ProfileEvent.count).to eq 1
        expect(ProfileEvent.first.value.include?('birthday:')).to eq true
        expect(ProfileEvent.first.value.include?('gender:')).to eq false
      end

      it 'do not create push_attributes_children event if "kids" data is not valid' do
        ProfileEvent.track_push_attributes(user, shop, 'push_attributes_children', attributes_9)
        expect(ProfileEvent.count).to eq 0
      end
    end
  end

end
