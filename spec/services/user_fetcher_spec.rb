require 'rails_helper'

describe UserFetcher do
  let!(:shop) { create(:shop) }

  describe '#fetch' do
    let!(:user) { create(:user) }
    let!(:session) { create(:session, user: user, code: '12345678') }
    subject { UserFetcher.new(params).fetch }


    context 'first visit' do
      let!(:params) { { session_code: session.code, shop: shop, location: "3" } }

      it "returns session's user" do
        expect(subject).to eq(session.user)
      end

      it 'doesnt create new session' do
        expect { subject }.to_not change(Session, :count)
      end

      it 'doesnt create new user' do
        expect { subject }.to_not change(User, :count)
      end

      it 'links user with shop' do
        expect { subject }.to change(Client, :count).from(0).to(1)

        client = Client.first!
        expect(client.shop).to eq(shop)
        expect(client.user).to eq(session.user)
        expect(client.external_id).to eq(nil)
      end

      it 'saves client location' do
        subject
        client = Client.first!
        expect(client.location).to eq("3")
      end


    end

    context 'second visit' do
      let!(:client) { create(:client, shop: shop, user: session.user, external_id: nil) }
      let!(:params) { { session_code: session.code, shop: shop } }

      it "returns session's user" do
        expect(subject).to eq(session.user)
      end

      it 'doesnt create new session' do
        expect { subject }.to_not change(Session, :count)
      end

      it 'doesnt create new user' do
        expect { subject }.to_not change(User, :count)
      end

      it 'doesnt create new link' do
        expect { subject }.to_not change(Client, :count)
      end
    end

    context 'when external_id is passed' do
      let!(:external_id) { '256' }
      let!(:client) { create(:client, shop: shop, user: session.user, external_id: nil) }
      let!(:params) { { session_code: session.code, shop: shop, external_id: external_id, email: 'test@example.com', location: '256' } }

      it "returns session's user" do
        expect(subject).to eq(session.user)
      end

      it 'doesnt create new session' do
        expect { subject }.to_not change(Session, :count)
      end

      it 'doesnt create new user' do
        expect { subject }.to_not change(User, :count)
      end

      it 'doesnt create new link' do
        expect { subject }.to_not change(Client, :count)
      end

      it 'saves external_id to link' do
        expect(client.reload.external_id).to eq(nil)
        subject
        client.reload
        expect(client.external_id).to eq(external_id)
        expect(client.email).to eq('test@example.com')
        expect(client.location).to eq('256')
      end
    end

    context 'when external_id is passed and another link exists' do
      let!(:external_id) { '256' }
      let!(:old_user) { create(:user) }
      let!(:old_session) { create(:session, code: '1234567890', user: old_user) }
      let!(:old_client) { create(:client, shop: shop, user: old_user, external_id: external_id) }
      let!(:params) { { session_code: session.code, shop: shop, external_id: external_id } }

      it "returns old session's user" do
        expect(subject).to eq(old_session.user)
      end

      it 'calls merger' do
        allow(UserMerger).to receive(:merge)

        subject

        expect(UserMerger).to have_received(:merge).with(old_user, user)
      end
    end


    context 'when had mail' do

      let!(:params) { { session_code: session.code, shop: shop, location: '256', email: 'old@example.com' } }

      let!(:first_mail_user) { create(:user) }
      let!(:second_mail_user) { create(:user) }
      let!(:third_mail_user) { create(:user) }

      let!(:client) { create(:client, shop: shop, user: session.user, email: 'old@example.com') }


      it 're-links by mail' do
        subject
        expect(Client.where(email: 'old@example.com').count).to eq(1)
      end

    end

    context 'when mail not in base' do

      let!(:params) { { session_code: session.code, shop: shop, location: '256', email: 'old@example.com' } }

      it 're-links by mail' do
        subject
        expect(Client.where(email: 'old@example.com').count).to eq(1)
      end

    end


    context 'when two user has same email and different external_id' do
      let!(:user_1) { create(:user) }
      let!(:user_2) { create(:user) }
      let!(:session_1) { create(:session, user: user_1, code: 's1s1s1') }
      let!(:session_2) { create(:session, user: user_2, code: 's2s2s2') }
      let!(:params_1) { {session_code: session_1.code, shop: shop, location: '256', email: 'some@email.com', external_id: '1'} }
      let!(:params_2) { {session_code: session_2.code, shop: shop, location: '256', email: 'some@email.com', external_id: '2'} }

      it 'saves old user_id for new client' do
        UserFetcher.new(params_1).fetch
        expect(UserFetcher.new(params_2).fetch.id).to eq(user_1.id)
      end

    end

  end
end
