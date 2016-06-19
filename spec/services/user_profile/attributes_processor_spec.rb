require 'rails_helper'

describe UserProfile::AttributesProcessor do
  describe '.process' do
    let!(:shop) { create(:shop) }
    let!(:user) { create(:user) }
    let!(:client) { create(:client, user: user, shop: shop) }
    let!(:first_mail_user) { create(:user)}
    let!(:second_mail_user) { create(:user)}
    let!(:third_mail_user) { create(:user)}

    let!(:attributes) { { 'gender' => 'f', 'type' => 'shoe', 'size' => 'e44', 'email' => 'old@rees46demo.com' } }

    let!(:first_client) { create(:client, shop: shop, user: first_mail_user, email: 'old@rees46demo.com') }
    let!(:second_client) { create(:client, shop: shop, user: second_mail_user, email: 'old@rees46demo.com') }
    let!(:third_client) { create(:client, shop: shop, user: third_mail_user, email: 'old@rees46demo.com') }

    subject { UserProfile::AttributesProcessor.process(shop, user, attributes) }

    it 'set correct email' do
      subject
      expect { user.reload.clients.first.email = 'test@rees46demo.com' }
    end

    context 'when profile attribute is new' do
      pending "Add gender check"
    end

  end
end
