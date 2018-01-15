require 'rails_helper'

describe ProfileEvent do
  let!(:customer) { create(:customer) }
  let!(:shop) { create(:shop, customer: customer) }
  let!(:user) { create(:user) }
  let!(:session) { create(:session, user: user) }
  let!(:client) { create(:client, :with_email, user: user, session: session, shop: shop) }

  let(:calculator) { UserProfile::PropertyCalculator }

  before { allow_any_instance_of(Elasticsearch::Persistence::Repository::Class).to receive(:save) }

  context 'with email' do
    subject { PropertyCalculatorWorker.new.perform(client.email) }

    it 'works' do
      expect_any_instance_of(calculator).to receive(:calculate_gender).with([session.id])
      expect_any_instance_of(calculator).to receive(:calculate_fashion_sizes).with([session.id])
      expect_any_instance_of(calculator).to receive(:calculate_compatibility).with([session.id])
      expect_any_instance_of(calculator).to receive(:calculate_children).with([session.id])

      subject
    end
  end

  context 'without email' do
    subject { PropertyCalculatorWorker.new.perform(session.code) }

    it 'works' do
      expect_any_instance_of(calculator).to receive(:calculate_gender).with(session.id)
      expect_any_instance_of(calculator).to receive(:calculate_fashion_sizes).with(session.id)
      expect_any_instance_of(calculator).to receive(:calculate_compatibility).with(session.id)
      expect_any_instance_of(calculator).to receive(:calculate_children).with(session.id)

      subject
    end
  end
end
