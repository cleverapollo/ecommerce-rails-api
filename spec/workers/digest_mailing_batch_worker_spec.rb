require 'rails_helper'

describe DigestMailingBatchWorker do
  let!(:shop) { create(:shop) }
  let!(:settigns) { create(:mailings_settings, shop: shop) }
  let!(:mailing) { create(:digest_mailing, shop: shop) }
  let!(:client) { create(:client, shop: shop, email: 'test@example.com') }
  let!(:batch) { create(:digest_mailing_batch, mailing: mailing, start_id: client.id, end_id: client.id, shop: shop) }
  subject { DigestMailingBatchWorker.new }

  describe '#perform' do
    let!(:item) { create(:item, shop: shop) }
    let!(:action) { create(:action, shop: shop, item: item, user: client.user) }
    let!(:letter) do
      batch.current_processed_client_id = nil
      ActionMailer::Base.deliveries = []
      subject.perform(batch.id)
      ActionMailer::Base.deliveries.first
    end
    let!(:letter_body) do
      letter.parts.first.body.to_s
    end

    it 'sends an email' do
      expect(letter).to be_present
    end

    it 'sent to audience' do
      expect(letter.to).to include(client.email)
    end

    it 'sent from sender from settigns' do
      expect(letter.from).to include(settigns.send_from)
    end

    it 'contains item name' do
      expect(letter_body.to_s).to include(item.name)
    end

    it 'contains item URL' do
      expect(letter_body.to_s).to include(item.url)
    end

    it 'contains unsubscribe URL' do
      expect(letter_body.to_s).to include(client.reload.digest_unsubscribe_url)
    end

    it 'contains tracking pixel' do
      expect(letter_body.to_s).to include(DigestMail.first.tracking_url)
    end
  end

  describe '#letter_body' do
    let!(:digest_mail) { create(:digest_mail, client: client, shop: shop, mailing: mailing, batch: batch).reload }
    let!(:item) { create(:item, shop: shop) }
    subject do
      s = DigestMailingBatchWorker.new
      s.current_client = client
      s.current_digest_mail = digest_mail
      s.mailing = mailing
      s.perform(batch.id)
      s.letter_body([item], 'test@example.com')
    end

    it 'returns string' do
      expect(subject).to be_a(String)
    end
  end

  describe '#item_for_letter' do
    context 'when item is widgetable' do
      let!(:item) { create(:item, shop: shop) }
      let!(:digest_mail) { create(:digest_mail, client: client, shop: shop, mailing: mailing, batch: batch).reload }
      subject do
        d_m_b_w = DigestMailingBatchWorker.new
        d_m_b_w.current_digest_mail = digest_mail
        d_m_b_w.item_for_letter(item)
      end

      it 'returns hash' do
        expect(subject).to be_a(Hash)
      end

      %i(name url image_url description).each do |key|
        it "contains #{key}" do
          expect(subject[key].nil?).to be_falsey
        end
      end

      context 'URL params' do
        %w(utm_source utm_medium utm_campaign recommended_by).each do |url_param|
          it "contains #{url_param}" do
            expect(subject[:url]).to include("#{url_param}=")
          end
        end

        it 'contains rees46_digest_mail_code' do
          expect(subject[:url]).to include("rees46_digest_mail_code=#{digest_mail.code}")
        end
      end
    end

    context 'when item is not widgetable' do
      let!(:item) { create(:item, shop: shop, name: nil, widgetable: false) }

      it 'raises Mailings::NotWidgetableItemError' do
        expect{ subject.item_for_letter(item) }.to raise_error(Mailings::NotWidgetableItemError)
      end
    end
  end
end
