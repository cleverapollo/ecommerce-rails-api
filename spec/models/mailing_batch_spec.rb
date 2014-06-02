require 'spec_helper'

describe MailingBatch do
  context 'state methods' do
    let(:mailing) { create(:mailing) }
    let(:mailing_batch) { create(:mailing_batch, mailing: mailing, started_at: 1.week.ago) }

    describe '#process!' do
      it 'marks batch as processing' do
        mailing_batch.process!

        expect(mailing_batch.state).to eq('processing')
      end
    end

    describe '#finish!' do
      it 'marks batch as finished' do
        mailing_batch.finish!

        expect(mailing_batch.state).to eq('finished')
      end

      it 'stores duration' do
        mailing_batch.finish!

        expect(mailing_batch.statistics[:duration]).to be_a(Float)
      end
    end

    describe '#fail!' do
      it 'marks batch as failed' do
        mailing_batch.fail!

        expect(mailing_batch.state).to eq('failed')
      end
    end
  end
end
