require 'rails_helper'

describe Audience do
  let!(:shop) { create(:shop) }
  subject { create(:audience, shop: shop).reload }

  describe '#unsubscribe_url' do
    it 'returns unsubscribe URL' do
      expect(subject.unsubscribe_url).to eq("http://127.0.0.1:8080/subscriptions/unsubscribe?code=#{subject.code}&type=digest")
    end
  end

  describe '#deactivate' do
    it 'deactivates audience' do
      subject.deactivate!
      expect(subject.active).to be_falsey
    end
  end

  describe '#try_to_attach_to_user!' do
    subject { create(:audience, shop: shop, external_id: '123', user_id: nil) }

    context 'when correct user exists' do
      let!(:u_s_r) { create(:user_shop_relation, shop: shop, uniqid: '123') }

      it 'attaches to user' do
        subject.try_to_attach_to_user!
        expect(subject.user).to eq(u_s_r.user)
      end
    end

    context 'when correct user doesnt exists' do
      it 'does nothing' do
        subject.try_to_attach_to_user!
        expect(subject.user).to be_nil
      end
    end
  end
end
