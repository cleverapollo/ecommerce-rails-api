require 'rails_helper'

describe UserFetcher do
  let!(:shop) { create(:shop) }

  describe '.new' do
    let!(:params) { { session_code: 1, external_id: 2, shop: shop } }
    subject { UserFetcher.new(params) }

    it 'accepts hash as options' do
      expect(subject).to be_an_instance_of(UserFetcher)
    end

    [:session_code, :external_id, :shop].each do |attr|
      it "stores #{attr} in @#{attr}" do
        expect(subject.public_send(attr)).to eq(params.fetch(attr))
      end
    end
  end

  describe '#fetch' do
    let!(:user) { create(:user) }
    let!(:session) { create(:session, user: user) }
    subject { UserFetcher.new(params).fetch }


    context 'first visit' do
      let!(:params) { { session_code: session.code, shop: shop } }

      it "returns session's user" do
        expect(subject).to eq(session.user)
      end

      it 'doesnt create new session' do
        expect{ subject }.to_not change(Session, :count)
      end

      it 'doesnt create new user' do
        expect{ subject }.to_not change(User, :count)
      end

      it 'links user with shop' do
        expect{ subject }.to change(Client, :count).from(0).to(1)

        client = Client.first!
        expect(client.shop).to eq(shop)
        expect(client.user).to eq(session.user)
        expect(client.external_id).to eq(nil)
      end
    end

    context 'second visit' do
      let!(:client) { create(:client, shop: shop, user: session.user, external_id: nil) }
      let!(:params) { { session_code: session.code, shop: shop } }

      it "returns session's user" do
        expect(subject).to eq(session.user)
      end

      it 'doesnt create new session' do
        expect{ subject }.to_not change(Session, :count)
      end

      it 'doesnt create new user' do
        expect{ subject }.to_not change(User, :count)
      end

      it 'doesnt create new link' do
        expect{ subject }.to_not change(Client, :count)
      end
    end

    context 'when external_id is passed' do
      let!(:external_id) { '256' }
      let!(:client) { create(:client, shop: shop, user: session.user, external_id: nil) }
      let!(:params) { { session_code: session.code, shop: shop, external_id: external_id } }

      it "returns session's user" do
        expect(subject).to eq(session.user)
      end

      it 'doesnt create new session' do
        expect{ subject }.to_not change(Session, :count)
      end

      it 'doesnt create new user' do
        expect{ subject }.to_not change(User, :count)
      end

      it 'doesnt create new link' do
        expect{ subject }.to_not change(Client, :count)
      end

      it 'saves external_id to link' do
        expect(client.reload.external_id).to eq(nil)
        subject
        expect(client.reload.external_id).to eq(external_id)
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
  end
end
