require 'rails_helper'

describe UserMerger do
  let!(:shop) { create(:shop) }
  let(:master) { user = create(:user)
  user.profile.update({ gender: { 'f' => 1, 'm' => 98,
                                  'history' =>
                                      { 'f' => { 'views' => 1, 'purchase' => 2 },
                                        'm' => { 'views' => 3, 'purchase' => 4 } } },
                        size: { 'f' => { 'tshirt' => { 'adult' => { 'size' => "38", 'probability' => 100 } } },
                                'history' => { 'f' => { 'tshirt' => { 'adult' => { "38" => { 'views' => 1, 'purchase' => 0 } } },
                                                      'shoe' => { 'adult' => { "40" => { 'views' => 1, 'purchase' => 0 } } } } } },
                        physiology: { 'history' =>
                                          { 'f' =>
                                                { 'hair' =>
                                                      { 'skin_type' =>
                                                            { 'dry' => { 'views' => 1, 'purchase' => 1 } },
                                                        'condition' => { "colored" => { 'views' => 2, 'purchase' => 2 } } } } } },
                        # periodicly: {"history"=> {
                        #     '1'=>[ 40, 20],
                        #     '2'=>[ 50, 30]
                        # }},
                        children: [] })
  user.profile.reload
  user
  }

  let(:slave) { user = create(:user)
  user.profile.update({ gender: { 'f' => 1, 'm' => 98,
                                    'history' =>
                                        { 'f' => { 'views' => 5, 'purchase' => 6 },
                                          'm' => { 'views' => 7, 'purchase' => 8 } } },
                          size: { 'f' => { 'tshirt' => { 'adult' => { 'size' => "38", 'probability' => 100 } } },
                                  'history' => { 'f' => { 'tshirt' => { 'adult' => { "38" => { 'views' => 1, 'purchase' => 0 },
                                                                                  "40" => { 'views' => 1, 'purchase' => 1 } } } } } },
                          physiology: { 'history' =>
                                            { 'f' =>
                                                  { 'hair' =>
                                                        { 'skin_type' => { "dry" => { 'views' => 1, 'purchase' => 1 } },
                                                          'condition' => { "damaged" => { 'views' => 2, 'purchase' => 2 } } } } } },
                          # periodicly: {"history"=> {
                          #     '2'=>[ 40, 30],
                          #     '3'=>[ 30, 10]
                          # }},
                          children: [] })
  user.profile.reload
  user
  }


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

        context 'virtual profile' do
          let!(:session) { create(:session, user: slave) }
          it 'merge virtual profile gender correctly' do
            subject
            expect(master.profile.gender['history']).to eq({ "f" => {
                                                               "views" => 6,
                                                               "purchase" => 8
                                                           },
                                                             "m" => {
                                                                 "views" => 10,
                                                                 "purchase" => 12
                                                             }
                                                           })
          end

          it 'merge virtual profile sizes correctly' do
            subject
            expect(master.profile.size['history']).to eq({ "f" =>
                                                               { "tshirt" =>
                                                                     { "adult" =>
                                                                           { "38" => { "views" => 2, "purchase" => 0 },
                                                                             "40" => { "views" => 1, "purchase" => 1 } } },
                                                                 "shoe" =>
                                                                     { "adult" => { "40" => { "views" => 1, "purchase" => 0 } } } } })
          end

          # it 'merge virtual profile physiology correctly' do
          #   subject
          #   expect(master.physiology['history']).to eq({"f"=>
          #                                                   {"hair"=>
          #                                                        {"skin_type"=>
          #                                                             {"dry"=>{"views"=>2, "purchase"=>2}},
          #                                                         "condition"=>{"damaged"=>{"views"=>2, "purchase"=>2},
          #                                                                       "colored"=>{"views"=>2, "purchase"=>2}}}}})
          # end


          # it 'merge virtual profile periodicly correctly' do
          #   subject
          #   expect(master.periodicly['history']).to eq({"2"=>[30, 40, 50], "3"=>[30, 10], "1"=>[40, 20]})
          # end

        end

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
        let!(:new_client) { create(:client, shop: shop, user: slave, email: 'old@example.com') }

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



      end

      context 'client merging of the same user' do
        let!(:master_client) { create(:client, shop: shop, user: master, email: 'old@example.com') }
        let!(:slave_client) { create(:client, shop: shop, user: master, email: 'old@example.com') }

        it 'merges two clients of same user and dont lose user' do
          UserMerger.merge(master, master)
          expect{ master.reload }.not_to raise_error()
        end

        it 'merges two clients of different users and removes slave user' do
        end

      end

      context 'mailings re-linking' do
        let!(:old_client) { create(:client, shop: shop, user: master, external_id: '256') }
        let!(:new_client) { create(:client, shop: shop, user: slave, email: 'old@example.com') }

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


    end
  end
end
