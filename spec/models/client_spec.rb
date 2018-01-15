require 'rails_helper'

describe Client do
  let!(:shop) { create(:shop) }
  let!(:user) { create(:user) }
  let!(:session) { create(:session, user: user) }
  let!(:client) { create(:client, session: session, shop: shop) }

  let(:email) { 'test@test.com' }
  let(:repository) { Elasticsearch::Persistence::Repository::Class }

  context 'change email' do

    it 'set email' do
      expect_any_instance_of(repository).to receive(:delete).with(session.code)
      expect(PropertyCalculatorWorker).to receive(:perform_async).with(email)
      client.update_email(email)
    end

    it 'set blank email' do
      client.update(email: email)
      client.reload
      expect_any_instance_of(repository).to_not receive(:delete)
      expect(PropertyCalculatorWorker).to receive(:perform_async).with(session.code)
      client.update_email(nil)
    end
  end
end
