require 'spec_helper'

describe UserFetcher do
  before { @shop = create(:shop) }
  describe '.new' do
    before { @opts = { ssid: 1, uniqid: 2, shop_id: @shop.id } }
    before { @fetcher = UserFetcher.new(@opts) }

    it 'accepts hash as options' do
      expect(@fetcher).to be_an_instance_of(UserFetcher)
    end

    [:ssid, :uniqid, :shop_id].each do |attr|
      it "stores #{attr} in @#{attr}" do
        expect(@fetcher.public_send(attr)).to eq(@opts.fetch(attr))
      end
    end
  end

  describe '#fetch' do
    before { @opts = { ssid: '1', uniqid: '2', shop_id: @shop.id } }
    shared_examples 'creates session and user' do
      it 'creates session' do
        expect{ subject }.to change(Session, :count).from(0).to(1)
      end

      it 'creates user' do
        expect{ subject }.to change(User, :count).from(0).to(1)
      end

      it 'links user with session' do
        subject
        expect(Session.first!.user).to eq(User.first!)
      end

      it 'returns created user' do
        expect(subject).to eq(User.first!)
      end
    end

    subject { UserFetcher.new(@opts).fetch }
    context 'without any params' do
      it_behaves_like 'creates session and user'
    end

    context 'only with ssid' do
      context 'when session exists' do
        before do
          @session = create(:session_with_user)
          @opts = { ssid: @session.uniqid, shop_id: @shop.id }
        end
        subject { UserFetcher.new(@opts).fetch }

        it 'not creates new session' do
          expect{ subject }.not_to change(Session, :count)
        end

        context 'when session\'s user exists' do
          it 'not creates new user' do
            expect{ subject }.not_to change(User, :count)
          end

          it 'returns that session\'s user' do
            expect(subject).to eq(@session.user)
          end
        end

        context 'when session\'s user not exists' do
          before { User.destroy_all }

          it 'creates new user' do
            expect{ subject }.to change(User, :count).from(0).to(1)
          end

          it 'attaches created user to session' do
            subject
            expect(@session.reload.user).to eq(User.first!)
          end

          it 'returns created user' do
            expect(subject).to eq(User.first!)
          end
        end
      end

      context 'when session doesnt exists' do
        before do
          Session.destroy_all
          User.destroy_all
        end

        it_behaves_like 'creates session and user'
      end
    end

    context 'only with uniqid' do
      before do
        @u_s_r = create(:user_shop_relation, shop_id: @shop.id)
        @opts = { uniqid: @u_s_r.uniqid, shop_id: @u_s_r.shop_id }
      end

      context 'when user-shop relation exists' do
        it 'returns user of relation' do
          expect(subject).to eq(@u_s_r.user)
        end

        it 'ensures that user has session' do
          expect(subject.sessions.count).to eq(1)
        end
      end

      context 'when user-shop relation doesn\'t exists' do
        before do
          UserShopRelation.destroy_all
          User.destroy_all
        end

        it_behaves_like 'creates session and user'

        it 'creates user-shop relation' do
          expect{ subject }.to change(UserShopRelation, :count).from(0).to(1)
        end

        it 'links user with user-shop relation' do
          subject
          expect(UserShopRelation.first!.user).to eq(User.first!)
        end
      end
    end

    context 'with ssid and uniqid' do
      context 'when they are for equal user' do
        before do
          @u_s_r = create(:user_shop_relation, shop_id: @shop.id)
          @session = create(:session, user: @u_s_r.user)
          @opts = { ssid: @session.uniqid, uniqid: @u_s_r.uniqid, shop_id: @u_s_r.shop_id }
        end

        it 'doesn\'t creates new user' do
          expect{ subject }.not_to change(User, :count)
        end

        it 'doesn\'t creates new session' do
          expect{ subject }.not_to change(Session, :count)
        end

        it 'doesn\'t creates new user-shop relation' do
          expect{ subject }.not_to change(UserShopRelation, :count)
        end

        it 'returns that user' do
          expect(subject).to eq(@u_s_r.user)
        end
      end

      context 'when they are for different users' do
        before do
          @u_s_r = create(:user_shop_relation, shop_id: @shop.id)
          @session = create(:session, user: create(:user))
          @opts = { ssid: @session.uniqid, uniqid: @u_s_r.uniqid, shop_id: @u_s_r.shop_id }
        end

        it 'merges users' do
          allow(UserMerger).to receive(:merge)
          subject
          expect(UserMerger).to have_received(:merge).with(@u_s_r.user, @session.user)
        end

        it 'returns user by uniqid' do
          expect(subject).to eq(@u_s_r.user)
        end

        it 'attaches session to uniqid user' do
          subject
          expect(@session.reload.user).to eq(@u_s_r.user)
        end
      end
    end
  end
end
