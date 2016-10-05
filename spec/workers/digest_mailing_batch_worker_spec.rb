require 'rails_helper'

describe DigestMailingBatchWorker do
  let!(:customer) { create(:customer) }
  let!(:shop) { create(:shop, customer: customer) }
  let!(:settings) { create(:mailings_settings, shop: shop, template_type: MailingsSettings::TEMPLATE_LIQUID) }
  let!(:mailing) { create(:digest_mailing, shop: shop) }
  let!(:client) { create(:client, shop: shop, email: 'test@rees46demo.com', activity_segment: 1) }
  let!(:batch) { create(:digest_mailing_batch, mailing: mailing, start_id: client.id, end_id: client.id, shop: shop) }
  let!(:batch_without_segment) { create(:digest_mailing_batch, mailing: mailing, start_id: client.id, end_id: client.id, shop: shop) }
  let!(:batch_with_segment) { create(:digest_mailing_batch, mailing: mailing, start_id: client.id, end_id: client.id, shop: shop, activity_segment: 1) }
  subject { DigestMailingBatchWorker.new }

  describe '#perform' do
    let!(:item) { create(:item, :widgetable, shop: shop) }
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

    it 'sent from sender from settings' do
      expect(letter.from).to include(settings.send_from)
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

    it 'contains encoded email' do
      expect(letter_body.to_s).to include("r46_merger=#{CGI.escape(Base64.encode64(client.email))}")
    end

    it 'contains tracking pixel' do
      expect(letter_body.to_s).to include(DigestMail.first.tracking_url)
    end
  end

  describe '#perform with activity segment' do

    # Если вдруг на локале здесь не проходит и непонятно почему, то скорее всего это из-за current_processed_client_id
    # который исторически сохранился у вас в Redis и не удалился.
    # Нахера вообще такое надо было хранить в Redis?
    # Зайти в redis-cli и выполнить FLUSHALL
    it 'sends an email' do
      subject.perform(batch_without_segment.id)
      expect(batch_without_segment.reload.digest_mails.count).to eq(1)
    end

    it 'does not send an email for client from another segment' do
      client.update activity_segment: nil
      subject.perform(batch_with_segment.id)
      expect(batch_with_segment.reload.digest_mails.count).to eq(0)
    end

  end


  describe '#letter_body' do
    let!(:digest_mail) { create(:digest_mail, client: client, shop: shop, mailing: mailing, batch: batch).reload }
    let!(:item) { create(:item, :widgetable, shop: shop) }
    subject do
      s = DigestMailingBatchWorker.new
      s.current_client = client
      s.current_digest_mail = digest_mail
      s.mailing = mailing
      s.perform(batch.id)
      s.liquid_letter_body([item], 'test@rees46demo.com', nil)
    end

    it 'returns string' do
      expect(subject).to be_a(String)
    end
  end

  describe '#liquid_letter_body' do
    let!(:liquid_shop) { create(:shop, customer: customer) }
    let!(:liquid_settings) { create(:mailings_settings, shop: liquid_shop, template_type: MailingsSettings::TEMPLATE_LIQUID) }
    let!(:liquid_mailing) { create(:digest_mailing, shop: liquid_shop, liquid_template: '{% for item in recommended_items%}{{item.url}}{% endfor%}') }
    let!(:liquid_client) { create(:client, shop: liquid_shop, email: 'test@rees46demo.com', activity_segment: 1) }
    let!(:liquid_batch) { create(:digest_mailing_batch, mailing: liquid_mailing, start_id: liquid_client.id, end_id: liquid_client.id, shop: liquid_shop) }
    let!(:liquid_digest_mail) { create(:digest_mail, client: liquid_client, shop: liquid_shop, mailing: liquid_mailing, batch: liquid_batch).reload }
    let!(:liquid_item) { create(:item, :widgetable, shop: liquid_shop) }
    subject do
      s = DigestMailingBatchWorker.new
      s.current_client = liquid_client
      s.current_digest_mail = liquid_digest_mail
      s.mailing = liquid_mailing
      s.perform(liquid_batch.id)
      s.liquid_letter_body([liquid_item], 'test@rees46demo.com', nil)
    end

    it 'returns string' do
      content = subject
      expect(content).to be_a(String)
      expect(content.length).to_not eq(0)
    end
  end


  context 'Time zone' do
    before { allow(Time).to receive(:now).and_return(Time.parse('2016-10-05 05:00:00 UTC +00:00')) }
    let!(:customer) { create(:customer, time_zone: 'Pacific Time (US & Canada)') }
    subject do
      s = DigestMailingBatchWorker.new
      s.current_client = client
      s.mailing = mailing
      s.perform(batch.id)
    end

    it 'digest_mail date yesterday for UTC' do
     subject

     expect(DigestMail.first.date.to_s).to eq '2016-10-04'
    end
  end


  describe '#item_for_letter' do
    context 'when item is widgetable' do
      let!(:item) { create(:item, :widgetable, shop: shop) }
      let!(:digest_mail) { create(:digest_mail, client: client, shop: shop, mailing: mailing, batch: batch).reload }
      subject do
        d_m_b_w = DigestMailingBatchWorker.new
        d_m_b_w.current_digest_mail = digest_mail
        d_m_b_w.item_for_letter(item, nil)
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
        expect{ subject.item_for_letter(item, nil) }.to raise_error(Mailings::NotWidgetableItemError)
      end
    end
  end
end
