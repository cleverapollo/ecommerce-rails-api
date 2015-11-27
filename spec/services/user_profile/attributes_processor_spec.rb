require 'rails_helper'

describe UserProfile::AttributesProcessor do
  describe '.process' do
    let!(:shop) { create(:shop) }
    let!(:user) { create(:user) }
    let!(:client) { create(:client, user: user, shop: shop) }
    let!(:first_mail_user) { create(:user)}
    let!(:second_mail_user) { create(:user)}
    let!(:third_mail_user) { create(:user)}

    let!(:attributes) { { 'gender' => 'f', 'type' => 'shoe', 'size' => 'e44', 'email' => 'old@example.com' } }

    let!(:first_client) { create(:client, shop: shop, user: first_mail_user, email: 'old@example.com') }
    let!(:second_client) { create(:client, shop: shop, user: second_mail_user, email: 'old@example.com') }
    let!(:third_client) { create(:client, shop: shop, user: third_mail_user, email: 'old@example.com') }

    subject { UserProfile::AttributesProcessor.process(shop, user, attributes) }

    it 'set correct email' do
      subject
      expect { user.reload.clients.first.email = 'test@example.com' }
    end

    context 'when profile attribute is new' do
      it 'stores profile attribute' do
        expect { subject }.to change { ProfileAttribute.count }.from(0).to(1)
      end

      it 'fix gender attribute' do
        subject
        expect(first_mail_user.profile.gender).to(eq( {'f'=>100, 'm'=>0, 'fixed'=>true} ))
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
