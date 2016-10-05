require 'rails_helper'

describe ActionPush::Processor do
  before do

    User.all.destroy_all
    Session.all.destroy_all

    @user = create(:user_with_session)
    @session = @user.sessions.first
    @customer = create(:customer)
    @shop = create(:shop, customer: @customer)
    @client = create(:client, shop: @shop, user: @user)

    create(:item_category, shop: @shop, external_id: '123', taxonomy: 'apparel.shoe')
    create(:item_category, shop: @shop, external_id: '321', taxonomy: 'apparel.shirt')
    create(:item_category, shop: @shop, external_id: '333')

    @items = [ create(:item, shop: @shop, category_ids: ['123', '321', '333']) ]

    @sample_params = OpenStruct.new(action: 'view', items: @items, user: @user, shop: @shop)
  end

  describe '.new' do
    subject { ActionPush::Processor.new(@sample_params) }

    it 'stores accepted params and stores it in @params' do
      expect(subject.params).to eq(@sample_params)
    end

    it 'fetches concrete action class and stores it in @concrete_action_class' do
      expect(subject.concrete_action_class).to eq(Actions::View)
    end
  end

  describe '#process' do

    before { @instance = ActionPush::Processor.new(@sample_params) }

    it 'fetches every items action' do
      @instance.process
    end

    it 'writes taxonomy to user' do
      @instance.process
      expect(UserTaxonomy.where(user_id: @user.id).count).to eq(2)
    end


    it 'disables cart if items array is empty' do
      params = OpenStruct.new(action: 'cart', items: @items, user: @user, shop: @shop)
      instance = ActionPush::Processor.new(params)
      instance.process
      expect(@user.actions.where(item_id: @items.first.id).first.rating).to eq Actions::Cart::RATING
      params = OpenStruct.new(action: 'cart', items: [], user: @user, shop: @shop)
      instance = ActionPush::Processor.new(params)
      instance.process
      expect(@user.actions.where(item_id: @items.first.id).first.rating).to eq Actions::RemoveFromCart::RATING
    end



  end



  describe '#process track clicks' do

    context 'trigger mailings' do

      let!(:trigger_mailing) { create(:trigger_mailing, shop: @shop) }
      let!(:trigger_mail) { create(:trigger_mail, shop: @shop, clicked: false, client: @client, mailing: trigger_mailing) }

      it 'marks trigger mail as clicked' do
        @sample_params.trigger_mail_code = trigger_mail.code
        @instance = ActionPush::Processor.new(@sample_params)
        @instance.process
        expect(trigger_mail.reload.clicked).to be_truthy
      end

    end

    context 'digest mailings' do

      let!(:digest_mailing) { create(:digest_mailing, shop: @shop) }
      let!(:digest_mailing_batch) { create(:digest_mailing_batch, shop: @shop, mailing: digest_mailing) }
      let!(:digest_mail) { create(:digest_mail, shop: @shop, clicked: false, client: @client, mailing: digest_mailing, batch: digest_mailing_batch) }

      it 'marks digest mail as clicked' do
        @sample_params.digest_mail_code = digest_mail.code
        @instance = ActionPush::Processor.new(@sample_params)
        @instance.process
        expect(digest_mail.reload.clicked).to be_truthy
      end

    end

    context 'web push triggers' do

      let!(:web_push_trigger) { create(:web_push_trigger, shop: @shop, message: 'asdasdasd', subject: 'asdasdasd') }
      let!(:web_push_trigger_message) { create(:web_push_trigger_message, shop: @shop, clicked: false, client: @client, web_push_trigger: web_push_trigger, trigger_data: {a: 3}) }

      it 'marks message clicked' do
        @sample_params.web_push_trigger_code = web_push_trigger_message.code
        @instance = ActionPush::Processor.new(@sample_params)
        @instance.process
        expect(web_push_trigger_message.reload.clicked).to be_truthy
      end

    end

    context 'web push digests' do

      let!(:web_push_digest) { create(:web_push_digest, shop: @shop, message: 'asdasdasd', url: 'asdasdasd', subject: 'asdasdasd') }
      let!(:web_push_digest_message) { create(:web_push_digest_message, shop: @shop, clicked: false, client: @client, web_push_digest: web_push_digest) }

      it 'marks message as clicked' do
        @sample_params.web_push_digest_code = web_push_digest_message.code
        @instance = ActionPush::Processor.new(@sample_params)
        @instance.process
        expect(web_push_digest_message.reload.clicked).to be_truthy
      end

    end

    context 'remarketing' do

      let!(:rtb_impression) { create(:rtb_impression, shop_id: @shop.id, item_id: @items.first.id, user_id: @user.id) }

      it 'marks job as clicked' do
        @sample_params.action = 'purchase'
        @sample_params.r46_returner_code = rtb_impression.code
        @sample_params.items = [@items.first]
        @sample_params.items.first.amount = 1
        @instance = ActionPush::Processor.new(@sample_params)
        @instance.process
        expect(rtb_impression.reload.clicked).to be_truthy
        expect(rtb_impression.reload.purchased).to be_truthy
      end

    end

  end


  describe '#fetch_action_for' do
  end
end
