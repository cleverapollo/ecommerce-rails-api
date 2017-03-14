require 'rails_helper'

describe DigestMailingLaunchWorker do
  let(:shop) { create(:shop) }
  let!(:mailings_settings) { create(:mailings_settings, shop: shop)}
  let(:mailing) { create(:digest_mailing, shop: shop, ) }
  let(:base_params) { { 'shop_id' => shop.uniqid, 'shop_secret' => shop.secret, 'id' => mailing.id } }
  describe '#perform' do
    subject { described_class.new.perform(params) }
    before { allow(DigestMailingBatchWorker).to receive(:perform_async) }

    context 'test mode' do
      let(:test_email) { 'test@rees46demo.com' }
      let(:params) { base_params.merge({ 'test_email' => test_email }) }

      it 'creates test batch' do
        subject

        batch = mailing.batches.first
        expect(batch.test_email).to eq(test_email)
      end

      it 'launches that batch' do
        subject

        batch_id = mailing.batches.first.id
        expect(DigestMailingBatchWorker).to have_received(:perform_async).with(batch_id).once
      end
    end

    context 'common mode' do
      let(:test_email) { 'test@rees46demo.com' }
      let(:params_test_email) { base_params.merge({ 'test_email' => test_email }) }
      let(:params) { base_params }
      let!(:segment) { create(:segment, shop: shop) }
      let!(:client1) { create(:client, :with_email, shop: shop) }
      let!(:client2) { create(:client, :with_email, shop: shop) }

      it 'creates test batch and common batch at once' do
        described_class.new.perform(params_test_email)
        described_class.new.perform(params)

        batch_counter = mailing.batches.count
        expect(batch_counter).to eq(2)
      end

      it 'creates common batch' do
        subject

        batch = mailing.batches.first
        expect(batch.start_id).to eq(client1.id)
        expect(batch.end_id).to eq(client2.id)
      end

      it 'launches that batch' do
        subject

        batch_id = mailing.batches.first.id
        expect(DigestMailingBatchWorker).to have_received(:perform_async).with(batch_id).once
      end

      it 'saves mailing clients count' do
        subject

        expect(mailing.reload.total_mails_count).to eq(2)
      end

      it 'saves mailing started_at' do
        expect(mailing.started_at).to eq(nil)

        subject

        expect(mailing.reload.started_at).to be_present
      end

      it 'uses activity segments' do
        client1.update segment_ids: [segment.id]
        mailing.update segment: segment
        subject
        expect(mailing.reload.total_mails_count).to eq(1)
      end

    end
  end
end
