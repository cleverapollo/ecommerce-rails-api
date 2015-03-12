require 'rails_helper'

describe UserProfile::AttributesProcessor do
  describe '.process' do
    let!(:shop) { create(:shop) }
    let!(:user) { create(:user) }
    let!(:attributes) { { 'gender' => 'f', 'type' => 'shoe', 'size' => 'e44' } }

    subject { UserProfile::AttributesProcessor.process(shop, user, attributes) }

    context 'when profile attribute is new' do
      it 'stores profile attribute' do
        expect{ subject }.to change { ProfileAttribute.count }.from(0).to(1)
      end
    end

    context 'when profile attribute already logged' do
      before { ProfileAttribute.create(user: user, shop: shop, value: attributes) }
      it 'does nothing' do
        expect{ subject }.to_not change { ProfileAttribute.count }
      end
    end
  end
end
