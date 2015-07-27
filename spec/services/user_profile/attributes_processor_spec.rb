require 'rails_helper'

describe UserProfile::AttributesProcessor do
  describe '.process' do
    let!(:shop) { create(:shop) }
    let!(:user) { create(:user) }
    let!(:attributes) { { 'gender' => 'f', 'type' => 'shoe', 'size' => 'e44', 'email' => 'test@example.com' } }

    subject { UserProfile::AttributesProcessor.process(shop, user, attributes) }

    it 'set correct email' do
      subject
      expect { user.clients.first.email = 'test@example.com' }
    end

    context 'when profile attribute is new' do
      it 'stores profile attribute' do
        expect { subject }.to change { ProfileAttribute.count }.from(1).to(2)
      end
    end

    context 'when profile attribute already logged' do
      before { ProfileAttribute.create(user: user, shop: shop, value: attributes) }
      it 'does nothing' do
        expect { subject }.to_not change { ProfileAttribute.count }
      end

    end
  end
end
