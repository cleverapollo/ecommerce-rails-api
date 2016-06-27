require 'rails_helper'

describe UserMerger do
  let!(:shop) { create(:shop) }
  let(:master) { create(:user) }

  let(:slave) { create(:user) }


  describe '.merge' do
    subject { UserMerger.merge(master, slave) }

    context 'validations' do
      context 'when master is blank' do
        let!(:master) { nil }

        it 'raises ArgumentError' do
          expect { subject }.to raise_exception(ArgumentError)
        end
      end

      context 'when master is not User' do
        let!(:master) { 42 }

        it 'raises ArgumentError' do
          expect { subject }.to raise_exception(ArgumentError)
        end
      end

      context 'when slave is blank' do
        let!(:slave) { nil }

        it 'raises ArgumentError' do
          expect { subject }.to raise_exception(ArgumentError)
        end
      end

      context 'when slave is not User' do
        let!(:slave) { 42 }

        it 'raises ArgumentError' do
          expect { subject }.to raise_exception(ArgumentError)
        end
      end
    end

    context 'when user signs in' do
      context 'user dependencies re-linking' do

        context 'sessions' do
          let!(:session) { create(:session, user: slave) }

          it 're-links session' do
            subject
            expect(session.reload.user_id).to eq(master.id)
          end
        end

        context 'actions' do
          let!(:action) { create(:action, user: slave, item: create(:item, shop: shop), shop: shop) }

          it 're-links action' do
            subject
            expect(action.reload.user_id).to eq(master.id)
          end
        end

        context 'orders' do
          let!(:order) { create(:order, user: slave, shop: shop) }

          it 're-links order' do
            subject
            expect(order.reload.user_id).to eq(master.id)
          end
        end

        context 'interactions' do
          let!(:interaction) { create(:interaction, user: slave, shop: shop, item_id: 123) }

          it 're-links interaction' do
            subject
            expect(interaction.reload.user_id).to eq(master.id)
          end
        end

      end

      context 'client merging' do
        let!(:old_client) { create(:client, shop: shop, user: master, external_id: '256') }
        let!(:new_client) { create(:client, shop: shop, user: slave, email: 'old@rees46demo.com', last_activity_at: Date.current) }

        it 'destroys new_client' do
          subject
          expect { new_client.reload }.to raise_exception(ActiveRecord::RecordNotFound)
        end

        it 'destroys slave user' do
          subject
          expect{ slave.reload }.to raise_exception(ActiveRecord::RecordNotFound)
        end

        it 'saves new_client email in old_client' do
          subject
          expect(old_client.reload.email).to eq(new_client.email)
        end

        it 'merges two clients into one by email' do
        end

        it 'merges two clients into one by email and saves first external_id' do
        end

        it 'saves newest last_activity_at' do
          subject
          expect(old_client.reload.last_activity_at).to eq(new_client.last_activity_at)
        end

      end

      context 'client merging of the same user' do
        let!(:master_client) { create(:client, shop: shop, user: master, email: 'old@rees46demo.com') }
        let!(:slave_client) { create(:client, shop: shop, user: master, email: 'old@rees46demo.com') }

        it 'merges two clients of same user and dont lose user' do
          UserMerger.merge(master, master)
          expect{ master.reload }.not_to raise_error()
        end

        it 'merges two clients of different users and removes slave user' do
        end

      end

      context 'mailings re-linking' do
        let!(:old_client) { create(:client, shop: shop, user: master, external_id: '256') }
        let!(:new_client) { create(:client, shop: shop, user: slave, email: 'old@rees46demo.com') }

        context 'digest mailings' do
          let!(:digest_mailing) { create(:digest_mailing, shop: shop) }
          let!(:digest_mailing_batch) { create(:digest_mailing_batch, mailing: digest_mailing, shop: shop) }
          let!(:digest_mail) { create(:digest_mail, client: new_client, shop: shop, mailing: digest_mailing, batch: digest_mailing_batch) }

          it 're-links digest_mail' do
            subject
            expect(digest_mail.reload.client_id).to eq(old_client.id)
          end
        end

        context 'trigger mailings' do
          let!(:trigger_mailing) { create(:trigger_mailing, shop: shop) }
          let!(:trigger_mail) { create(:trigger_mail, client: new_client, mailing: trigger_mailing, shop: shop) }

          it 're-links trigger_mail' do
            subject
            expect(trigger_mail.reload.client_id).to eq(old_client.id)
          end
        end
      end


      context 'merge profile events and recalculate profile' do

        let!(:profile_event_1) { create(:profile_event, shop: shop, user: master, industry: 'fashion', property: 'gender', value: 'm', views: 1 ) }
        let!(:profile_event_2) { create(:profile_event, shop: shop, user: master, industry: 'fashion', property: 'gender', value: 'f', views: 1 ) }
        let!(:profile_event_3) { create(:profile_event, shop: shop, user: slave, industry: 'fashion', property: 'gender', value: 'f', views: 1, carts: 2 ) }

        let!(:profile_event_4) { create(:profile_event, shop: shop, user: master, industry: 'fashion', property: 'size_shoe', value: '38', views: 1, carts: 2 ) }
        let!(:profile_event_5) { create(:profile_event, shop: shop, user: slave, industry: 'fashion', property: 'size_shoe', value: '38', views: 1, purchases: 3 ) }
        let!(:profile_event_6) { create(:profile_event, shop: shop, user: slave, industry: 'fashion', property: 'size_shoe', value: '39', views: 1) }
        let!(:profile_event_7) { create(:profile_event, shop: shop, user: slave, industry: 'fashion', property: 'size_coat', value: '39', views: 1 ) }

        let!(:profile_event_8) { create(:profile_event, shop: shop, user: master, industry: 'fmcg', property: 'hypoallergenic', value: '1', purchases: 1) }
        let!(:profile_event_9) { create(:profile_event, shop: shop, user: slave, industry: 'cosmetic', property: 'hypoallergenic', value: '1', carts: 3 ) }

        let!(:profile_event_10) { create(:profile_event, shop: shop, user: master, industry: 'cosmetic', property: 'hair_type', value: 'long', views: 3 ) }
        let!(:profile_event_11) { create(:profile_event, shop: shop, user: slave, industry: 'cosmetic', property: 'hair_type', value: 'short', carts: 3 ) }
        let!(:profile_event_12) { create(:profile_event, shop: shop, user: master, industry: 'cosmetic', property: 'hair_condition', value: 'damage', views: 3 ) }
        let!(:profile_event_13) { create(:profile_event, shop: shop, user: slave, industry: 'cosmetic', property: 'hair_condition', value: 'normal', purchases: 3 ) }

        let!(:profile_event_14) { create(:profile_event, shop: shop, user: master, industry: 'cosmetic', property: 'skin_type_body', value: 'dry', purchases: 2 ) }
        let!(:profile_event_15) { create(:profile_event, shop: shop, user: slave, industry: 'cosmetic', property: 'skin_type_body', value: 'normal', views: 1, carts: 2 ) }
        let!(:profile_event_16) { create(:profile_event, shop: shop, user: slave, industry: 'cosmetic', property: 'skin_type_hand', value: 'normal', carts: 1 ) }
        let!(:profile_event_17) { create(:profile_event, shop: shop, user: slave, industry: 'cosmetic', property: 'skin_condition_hand', value: 'damage', carts: 2 ) }
        let!(:profile_event_18) { create(:profile_event, shop: shop, user: slave, industry: 'cosmetic', property: 'skin_condition_body', value: 'soft', carts: 2 ) }

        let!(:profile_event_19) { create(:profile_event, shop: shop, user: master, industry: 'child', property: 'age', value: '0.25_2.0_m', purchases: 2 ) }
        let!(:profile_event_20) { create(:profile_event, shop: shop, user: master, industry: 'child', property: 'age', value: '_3.0_f', views: 1, carts: 2 ) }
        let!(:profile_event_21) { create(:profile_event, shop: shop, user: slave, industry: 'child', property: 'age', value: '3_5_f', carts: 1 ) }
        let!(:profile_event_22) { create(:profile_event, shop: shop, user: slave, industry: 'child', property: 'age', value: '3_5_', carts: 2 ) }
        let!(:profile_event_23) { create(:profile_event, shop: shop, user: slave, industry: 'child', property: 'age', value: '0.5__m', carts: 2 ) }


        it 'merges profile events and recalculates profile' do
          subject
          master.reload
          expect(master.profile_events.where(industry: 'fashion', property: 'gender').count).to eq 2
          expect(master.profile_events.where(industry: 'fashion', property: 'gender', value: 'm').first.views).to eq 1
          expect(master.profile_events.where(industry: 'fashion', property: 'gender', value: 'f').first.views).to eq 2
          expect(master.profile_events.where(industry: 'fashion', property: 'gender', value: 'f').first.carts).to eq 2
          expect(master.gender).to eq 'f'

          expect(master.profile_events.where(industry: 'fashion', property: 'size_shoe').count).to eq 2
          expect(master.profile_events.where(industry: 'fashion', property: 'size_coat').count).to eq 1
          expect(master.profile_events.where(industry: 'fashion', property: 'size_shoe', value: '38').first.views).to eq 2
          expect(master.profile_events.where(industry: 'fashion', property: 'size_shoe', value: '38').first.carts).to eq 2
          expect(master.profile_events.where(industry: 'fashion', property: 'size_shoe', value: '38').first.purchases).to eq 3
          expect(master.profile_events.where(industry: 'fashion', property: 'size_shoe', value: '39').first.views).to eq 1
          expect(master.profile_events.where(industry: 'fashion', property: 'size_shoe', value: '39').first.carts).to be_nil
          expect(master.profile_events.where(industry: 'fashion', property: 'size_coat', value: '39').first.views).to eq 1
          expect(master.fashion_sizes['shoe']).to eq [38]
          expect(master.fashion_sizes['coat']).to eq [39]

          expect(master.profile_events.where(industry: 'fmcg', property: 'hypoallergenic').first.purchases).to eq 1
          expect(master.profile_events.where(industry: 'cosmetic', property: 'hypoallergenic').first.carts).to eq 3
          expect(master.allergy).to be_truthy

          expect(master.cosmetic_hair['type']).to eq 'short'
          expect(master.cosmetic_hair['condition']).to eq 'normal'

          expect(master.profile_events.where(industry: 'cosmetic', property: 'skin_type_body', value: 'dry').first.purchases).to eq 2
          expect(master.profile_events.where(industry: 'cosmetic', property: 'skin_type_body', value: 'normal').first.views).to eq 1
          expect(master.profile_events.where(industry: 'cosmetic', property: 'skin_type_body', value: 'normal').first.carts).to eq 2
          expect(master.profile_events.where(industry: 'cosmetic', property: 'skin_type_hand', value: 'normal').first.carts).to eq 1
          expect(master.profile_events.where(industry: 'cosmetic', property: 'skin_condition_hand', value: 'damage').first.carts).to eq 2
          expect(master.profile_events.where(industry: 'cosmetic', property: 'skin_condition_body', value: 'soft').first.carts).to eq 2
          expect(master.cosmetic_skin['hand']['type']).to eq ['normal']
          expect(master.cosmetic_skin['hand']['condition']).to eq ['damage']
          expect(master.cosmetic_skin['body']['type']).to eq ['dry', 'normal']
          expect(master.cosmetic_skin['body']['condition']).to eq ['soft']

          expect(master.children).to eq ([{"gender"=>"m", "age_max"=>1.0, "age_min"=>0.5}, {"gender"=>"f", "age_max"=>3.0, "age_min"=>1.5}])

        end

      end


    end
  end
end
