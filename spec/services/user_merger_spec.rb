require 'rails_helper'

describe UserMerger do
  # let!(:customer) { create(:customer) }
  # let!(:shop) { create(:shop, customer: customer) }
  # let(:master) { create(:user) }
  #
  # let(:slave) { create(:user) }
  #
  # def fork_with_new_connection
  #   config = ActiveRecord::Base.remove_connection
  #   fork do
  #     begin
  #       ActiveRecord::Base.establish_connection(config)
  #       yield
  #     ensure
  #       ActiveRecord::Base.remove_connection
  #       Process.exit!
  #     end
  #   end
  #   ActiveRecord::Base.establish_connection(config)
  # end
  #
  #
  # describe '.merge' do
  #   subject { UserMerger.merge(master, slave) }
  #
  #   context 'validations' do
  #     context 'when master is blank' do
  #       let!(:master) { nil }
  #
  #       it 'raises ArgumentError' do
  #         expect { subject }.to raise_exception(ArgumentError)
  #       end
  #     end
  #
  #     context 'when master is not User' do
  #       let!(:master) { 42 }
  #
  #       it 'raises ArgumentError' do
  #         expect { subject }.to raise_exception(ArgumentError)
  #       end
  #     end
  #
  #     context 'when slave is blank' do
  #       let!(:slave) { nil }
  #
  #       it 'raises ArgumentError' do
  #         expect { subject }.to raise_exception(ArgumentError)
  #       end
  #     end
  #
  #     context 'when slave is not User' do
  #       let!(:slave) { 42 }
  #
  #       it 'raises ArgumentError' do
  #         expect { subject }.to raise_exception(ArgumentError)
  #       end
  #     end
  #   end
  #
  #   context 'when user signs in' do
  #     context 'user dependencies re-linking' do
  #
  #       context 'sessions' do
  #         let!(:session) { create(:session, user: slave) }
  #
  #         it 're-links session' do
  #           subject
  #           expect(session.reload.user_id).to eq(master.id)
  #         end
  #       end
  #
  #       context 'orders' do
  #         let!(:order) { create(:order, user: slave, shop: shop) }
  #
  #         it 're-links order' do
  #           subject
  #           expect(order.reload.user_id).to eq(master.id)
  #         end
  #       end
  #
  #       context 'interactions' do
  #         let!(:interaction) { create(:interaction, user: slave, shop: shop, item_id: 123) }
  #
  #         it 're-links interaction' do
  #           subject
  #           expect(interaction.reload.user_id).to eq(master.id)
  #         end
  #       end
  #
  #     end
  #
  #     context 'client merging' do
  #       let!(:old_client) { create(:client, shop: shop, user: master, external_id: '256') }
  #       let!(:new_client) { create(:client, shop: shop, user: slave, email: 'old@rees46demo.com', last_activity_at: Date.current, web_push_enabled: true, fb_id: 1234, vk_id: 4321 ) }
  #       let!(:new_web_push_token) { create(:web_push_token, client: new_client, shop: shop, token: {token: '123', browser: 'safari'}) }
  #
  #       it 'destroys new_client' do
  #         subject
  #         expect { new_client.reload }.to raise_exception(ActiveRecord::RecordNotFound)
  #       end
  #
  #       it 'destroys slave user' do
  #         subject
  #         expect{ slave.reload }.to raise_exception(ActiveRecord::RecordNotFound)
  #       end
  #
  #       it 'saves new_client email, fb, vk in old_client' do
  #         subject
  #         expect(old_client.reload.email).to eq(new_client.email)
  #         expect(old_client.reload.fb_id).to eq(new_client.fb_id)
  #         expect(old_client.reload.vk_id).to eq(new_client.vk_id)
  #       end
  #
  #       it 'saves web push settings to old client' do
  #         subject
  #         old_client.reload
  #         expect(old_client.web_push_enabled).to eq(new_client.web_push_enabled)
  #         expect(old_client.last_web_push_sent_at).to eq(new_client.last_web_push_sent_at)
  #         expect(old_client.web_push_tokens.count).to eq 1
  #       end
  #
  #       it 'saves web push tokens with identically token' do
  #         create(:web_push_token, client: old_client, shop: shop, token: {token: '123', browser: 'safari'})
  #         subject
  #         old_client.reload
  #         expect(old_client.web_push_enabled).to eq(new_client.web_push_enabled)
  #         expect(old_client.last_web_push_sent_at).to eq(new_client.last_web_push_sent_at)
  #         expect(old_client.web_push_tokens.count).to eq 1
  #       end
  #
  #       it 'merges two clients into one by email' do
  #       end
  #
  #       it 'merges two clients into one by email and saves first external_id' do
  #       end
  #
  #       it 'saves newest last_activity_at' do
  #         subject
  #         expect(old_client.reload.last_activity_at).to eq(new_client.last_activity_at)
  #       end
  #
  #     end
  #
  #     context 'don\'t merging with exist fb_id' do
  #       let!(:old_client) { create(:client, shop: shop, user: master, external_id: '256', fb_id: 123456789) }
  #       let!(:new_client) { create(:client, shop: shop, user: slave, email: 'old@rees46demo.com', last_activity_at: Date.current, web_push_enabled: true, fb_id: 1234 ) }
  #
  #       it 'saves old_client and new_client' do
  #         subject
  #         expect(old_client.reload.email).to eq(nil)
  #         expect(old_client.reload.fb_id).to eq(old_client.fb_id)
  #         expect(new_client.reload.email).to be_truthy
  #         expect(new_client.reload.fb_id).to eq(new_client.fb_id)
  #       end
  #     end
  #
  #     context 'don\'t merging with exist vk_id' do
  #       let!(:old_client) { create(:client, shop: shop, user: master, external_id: '256', vk_id: 123456789) }
  #       let!(:new_client) { create(:client, shop: shop, user: slave, email: 'old@rees46demo.com', last_activity_at: Date.current, web_push_enabled: true, vk_id: 1234 ) }
  #
  #       it 'saves old_client and new_client' do
  #         subject
  #         expect(old_client.reload.email).to eq(nil)
  #         expect(old_client.reload.vk_id).to eq(old_client.vk_id)
  #         expect(new_client.reload.email).to be_truthy
  #         expect(new_client.reload.vk_id).to eq(new_client.vk_id)
  #       end
  #     end
  #
  #     context 'merging with exist fb_id and new email' do
  #       let!(:old_client) { create(:client, shop: shop, user: master, external_id: '256', fb_id: 123456789) }
  #       let!(:new_client) { create(:client, shop: shop, user: slave, email: 'old@rees46demo.com', last_activity_at: Date.current, web_push_enabled: true, vk_id: 1234 ) }
  #
  #       it 'saves old_client and new_client' do
  #         subject
  #         expect(old_client.reload.email).to eq(new_client.email)
  #         expect(old_client.reload.vk_id).to eq(new_client.vk_id)
  #         expect(old_client.reload.fb_id).to eq(old_client.fb_id)
  #         expect { new_client.reload }.to raise_exception(ActiveRecord::RecordNotFound)
  #       end
  #     end
  #
  #     context 'client merging of the same user' do
  #       let!(:master_client) { create(:client, shop: shop, user: master, email: 'old@rees46demo.com') }
  #       let!(:slave_client) { create(:client, shop: shop, user: master, email: 'old@rees46demo.com') }
  #
  #       it 'merges two clients of same user and dont lose user' do
  #         UserMerger.merge(master, master)
  #         expect{ master.reload }.not_to raise_error()
  #       end
  #
  #       it 'merges two clients of different users and removes slave user' do
  #       end
  #
  #     end
  #
  #     context 'mailings re-linking' do
  #       let!(:old_client) { create(:client, shop: shop, user: master, external_id: '256') }
  #       let!(:new_client) { create(:client, shop: shop, user: slave, email: 'old@rees46demo.com') }
  #
  #       context 'digest mailings' do
  #         let!(:digest_mailing) { create(:digest_mailing, shop: shop) }
  #         let!(:digest_mailing_batch) { create(:digest_mailing_batch, mailing: digest_mailing, shop: shop) }
  #         let!(:digest_mail) { create(:digest_mail, client: new_client, shop: shop, mailing: digest_mailing, batch: digest_mailing_batch) }
  #
  #         it 're-links digest_mail' do
  #           subject
  #           expect(digest_mail.reload.client_id).to eq(old_client.id)
  #         end
  #       end
  #
  #       context 'trigger mailings' do
  #         let!(:trigger_mailing) { create(:trigger_mailing, shop: shop) }
  #         let!(:trigger_mail) { create(:trigger_mail, client: new_client, mailing: trigger_mailing, shop: shop) }
  #
  #         it 're-links trigger_mail' do
  #           subject
  #           expect(trigger_mail.reload.client_id).to eq(old_client.id)
  #         end
  #       end
  #     end
  #
  #
  #     context 'web push re-linking' do
  #       let!(:old_client) { create(:client, shop: shop, user: master, external_id: '256') }
  #       let!(:new_client) { create(:client, shop: shop, accepted_web_push_subscription: true, web_push_subscription_popup_showed: true, web_push_subscription_permission_showed: true, user: slave, email: 'old@rees46demo.com') }
  #
  #       context 'web push triggers' do
  #         let!(:web_push_trigger_message) { create(:web_push_trigger_message, client: new_client, shop: shop, trigger_data: {sample: true}) }
  #         it 're-links web push trigger message' do
  #           subject
  #           expect(web_push_trigger_message.reload.client_id).to eq(old_client.id)
  #         end
  #       end
  #
  #       context 'web push digests' do
  #         let!(:web_push_digest_message) { create(:web_push_digest_message, client: new_client, shop: shop) }
  #         it 're-links web push digest message' do
  #           subject
  #           expect(web_push_digest_message.reload.client_id).to eq(old_client.id)
  #         end
  #       end
  #
  #       context 'web push subscriptions' do
  #         it 're-links subscriptions settings' do
  #           expect(old_client.reload.web_push_subscription_popup_showed).to be_falsey
  #           expect(old_client.reload.web_push_subscription_permission_showed).to be_falsey
  #           expect(old_client.reload.accepted_web_push_subscription).to be_falsey
  #           subject
  #           expect(old_client.reload.web_push_subscription_popup_showed).to be_truthy
  #           expect(old_client.reload.web_push_subscription_permission_showed).to be_truthy
  #           expect(old_client.reload.accepted_web_push_subscription).to be_truthy
  #         end
  #       end
  #
  #     end
  #
  #
  #     context 'merge subscriptions for triggers' do
  #
  #       let!(:subscribe_for_product_available_1) { create(:subscribe_for_product_available, shop: shop, user: master, item_id: 1, subscribed_at: Time.current ) }
  #       let!(:subscribe_for_product_available_2) { create(:subscribe_for_product_available, shop: shop, user: master, item_id: 2, subscribed_at: Time.current ) }
  #       let!(:subscribe_for_product_available_3) { create(:subscribe_for_product_available, shop: shop, user: slave, item_id: 2, subscribed_at: Time.current ) }
  #       let!(:subscribe_for_product_available_4) { create(:subscribe_for_product_available, shop: shop, user: slave, item_id: 3, subscribed_at: Time.current ) }
  #
  #       let!(:subscribe_for_product_price_1) { create(:subscribe_for_product_price, shop: shop, user: master, item_id: 1, price: 100, subscribed_at: Time.current ) }
  #       let!(:subscribe_for_product_price_2) { create(:subscribe_for_product_price, shop: shop, user: master, item_id: 2, price: 100, subscribed_at: Time.current ) }
  #       let!(:subscribe_for_product_price_3) { create(:subscribe_for_product_price, shop: shop, user: slave, item_id: 2, price: 100, subscribed_at: Time.current ) }
  #       let!(:subscribe_for_product_price_4) { create(:subscribe_for_product_price, shop: shop, user: slave, item_id: 3, price: 100, subscribed_at: Time.current ) }
  #
  #       it 'relinks subscriptions' do
  #         subject
  #         master.reload
  #         expect(master.subscribe_for_product_availables.count).to eq 3
  #         expect(master.subscribe_for_product_prices.count).to eq 3
  #       end
  #
  #     end
  #
  #
  #
  #     context 'merge profile events and recalculate profile' do
  #
  #       let!(:profile_event_1) { create(:profile_event, shop: shop, user: master, industry: 'fashion', property: 'gender', value: 'm', views: 1 ) }
  #       let!(:profile_event_2) { create(:profile_event, shop: shop, user: master, industry: 'fashion', property: 'gender', value: 'f', views: 1 ) }
  #       let!(:profile_event_3) { create(:profile_event, shop: shop, user: slave, industry: 'fashion', property: 'gender', value: 'f', views: 1, carts: 2 ) }
  #
  #       let!(:profile_event_4) { create(:profile_event, shop: shop, user: master, industry: 'fashion', property: 'size_shoe', value: '38', views: 1, carts: 2 ) }
  #       let!(:profile_event_5) { create(:profile_event, shop: shop, user: slave, industry: 'fashion', property: 'size_shoe', value: '38', views: 1, purchases: 3 ) }
  #       let!(:profile_event_6) { create(:profile_event, shop: shop, user: slave, industry: 'fashion', property: 'size_shoe', value: '39', views: 1) }
  #       let!(:profile_event_7) { create(:profile_event, shop: shop, user: slave, industry: 'fashion', property: 'size_coat', value: '39', views: 1 ) }
  #
  #       let!(:profile_event_8) { create(:profile_event, shop: shop, user: master, industry: 'fmcg', property: 'hypoallergenic', value: '1', purchases: 1) }
  #       let!(:profile_event_9) { create(:profile_event, shop: shop, user: slave, industry: 'cosmetic', property: 'hypoallergenic', value: '1', carts: 3 ) }
  #
  #       let!(:profile_event_10) { create(:profile_event, shop: shop, user: master, industry: 'cosmetic', property: 'hair_type', value: 'long', views: 3 ) }
  #       let!(:profile_event_11) { create(:profile_event, shop: shop, user: slave, industry: 'cosmetic', property: 'hair_type', value: 'short', carts: 3 ) }
  #       let!(:profile_event_12) { create(:profile_event, shop: shop, user: master, industry: 'cosmetic', property: 'hair_condition', value: 'damage', views: 3 ) }
  #       let!(:profile_event_13) { create(:profile_event, shop: shop, user: slave, industry: 'cosmetic', property: 'hair_condition', value: 'normal', purchases: 3 ) }
  #
  #       let!(:profile_event_14) { create(:profile_event, shop: shop, user: master, industry: 'cosmetic', property: 'skin_type_body', value: 'dry', purchases: 2 ) }
  #       let!(:profile_event_15) { create(:profile_event, shop: shop, user: slave, industry: 'cosmetic', property: 'skin_type_body', value: 'normal', views: 1, carts: 2 ) }
  #       let!(:profile_event_16) { create(:profile_event, shop: shop, user: slave, industry: 'cosmetic', property: 'skin_type_hand', value: 'normal', carts: 1 ) }
  #       let!(:profile_event_17) { create(:profile_event, shop: shop, user: slave, industry: 'cosmetic', property: 'skin_condition_hand', value: 'damage', carts: 2 ) }
  #       let!(:profile_event_18) { create(:profile_event, shop: shop, user: slave, industry: 'cosmetic', property: 'skin_condition_body', value: 'soft', carts: 2 ) }
  #
  #       let!(:profile_event_19) { create(:profile_event, shop: shop, user: master, industry: 'child', property: 'age', value: '0.25_2.0_m', purchases: 2 ) }
  #       let!(:profile_event_20) { create(:profile_event, shop: shop, user: master, industry: 'child', property: 'age', value: '_3.0_f', views: 1, carts: 2 ) }
  #       let!(:profile_event_21) { create(:profile_event, shop: shop, user: slave, industry: 'child', property: 'age', value: '3_5_f', carts: 1 ) }
  #       let!(:profile_event_22) { create(:profile_event, shop: shop, user: slave, industry: 'child', property: 'age', value: '3_5_', carts: 2 ) }
  #       let!(:profile_event_23) { create(:profile_event, shop: shop, user: slave, industry: 'child', property: 'age', value: '0.5__m', carts: 2 ) }
  #
  #       let!(:profile_event_24) { create(:profile_event, shop: shop, user: master, industry: 'pets', property: 'type', value: 'type:dog', carts: 2 ) }
  #       let!(:profile_event_25) { create(:profile_event, shop: shop, user: slave, industry: 'pets', property: 'type', value: 'type:cat', carts: 2 ) }
  #
  #       let!(:profile_event_26) { create(:profile_event, shop: shop, user: slave, industry: 'cosmetic', property: 'perfume_aroma', value: 'floral', carts: 2 ) }
  #
  #       def expect_master(master)
  #         expect(master.profile_events.where(industry: 'fashion', property: 'gender').count).to eq 2
  #         expect(master.profile_events.where(industry: 'fashion', property: 'gender', value: 'm').first.views).to eq 1
  #         expect(master.profile_events.where(industry: 'fashion', property: 'gender', value: 'f').first.views).to eq 2
  #         expect(master.profile_events.where(industry: 'fashion', property: 'gender', value: 'f').first.carts).to eq 2
  #         expect(master.gender).to eq 'f'
  #
  #         expect(master.profile_events.where(industry: 'fashion', property: 'size_shoe').count).to eq 2
  #         expect(master.profile_events.where(industry: 'fashion', property: 'size_coat').count).to eq 1
  #         expect(master.profile_events.where(industry: 'fashion', property: 'size_shoe', value: '38').first.views).to eq 2
  #         expect(master.profile_events.where(industry: 'fashion', property: 'size_shoe', value: '38').first.carts).to eq 2
  #         expect(master.profile_events.where(industry: 'fashion', property: 'size_shoe', value: '38').first.purchases).to eq 3
  #         expect(master.profile_events.where(industry: 'fashion', property: 'size_shoe', value: '39').first.views).to eq 1
  #         expect(master.profile_events.where(industry: 'fashion', property: 'size_shoe', value: '39').first.carts).to be_nil
  #         expect(master.profile_events.where(industry: 'fashion', property: 'size_coat', value: '39').first.views).to eq 1
  #         expect(master.fashion_sizes['shoe']).to eq [38]
  #         expect(master.fashion_sizes['coat']).to eq [39]
  #
  #         expect(master.profile_events.where(industry: 'fmcg', property: 'hypoallergenic').first.purchases).to eq 1
  #         expect(master.profile_events.where(industry: 'cosmetic', property: 'hypoallergenic').first.carts).to eq 3
  #         expect(master.allergy).to be_truthy
  #
  #         expect(master.cosmetic_hair['type']).to eq 'short'
  #         expect(master.cosmetic_hair['condition']).to eq 'normal'
  #
  #         expect(master.profile_events.where(industry: 'cosmetic', property: 'skin_type_body', value: 'dry').first.purchases).to eq 2
  #         expect(master.profile_events.where(industry: 'cosmetic', property: 'skin_type_body', value: 'normal').first.views).to eq 1
  #         expect(master.profile_events.where(industry: 'cosmetic', property: 'skin_type_body', value: 'normal').first.carts).to eq 2
  #         expect(master.profile_events.where(industry: 'cosmetic', property: 'skin_type_hand', value: 'normal').first.carts).to eq 1
  #         expect(master.profile_events.where(industry: 'cosmetic', property: 'skin_condition_hand', value: 'damage').first.carts).to eq 2
  #         expect(master.profile_events.where(industry: 'cosmetic', property: 'skin_condition_body', value: 'soft').first.carts).to eq 2
  #         expect(master.cosmetic_skin['hand']['type']).to eq ['normal']
  #         expect(master.cosmetic_skin['hand']['condition']).to eq ['damage']
  #         expect(master.cosmetic_skin['body']['type']).to eq ['dry', 'normal']
  #         expect(master.cosmetic_skin['body']['condition']).to eq ['soft']
  #
  #         expect(master.cosmetic_perfume['aroma']).to eq ['floral']
  #
  #         expect(master.children).to eq ([{"gender"=>"m", "age_max"=>1.0, "age_min"=>0.5}, {"gender"=>"f", "age_max"=>3.0, "age_min"=>1.5}])
  #
  #         expect(master.profile_events.where(industry: 'pets', property: 'type', value: 'type:dog').first.carts).to eq 2
  #         expect(master.profile_events.where(industry: 'pets', property: 'type', value: 'type:cat').first.carts).to eq 2
  #         expect(master.pets[0]).to eq ( {'type' => 'cat', 'score' => 4 } )
  #         expect(master.pets[1]).to eq ( {'type' => 'dog', 'score' => 4 } )
  #       end
  #
  #       it 'merges profile events and recalculates profile' do
  #         subject
  #         expect_master(master.reload)
  #       end
  #
  #       context 'merge remnants' do
  #         subject {
  #           slave.delete
  #           UserMerger.merge_remnants(master.id, slave.id)
  #         }
  #         it 'merges profile events and recalculates profile' do
  #           subject
  #           expect_master(master.reload)
  #         end
  #       end
  #
  #     end
  #
  #
  #   end
  # end
end
