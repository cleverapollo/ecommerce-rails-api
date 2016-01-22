require 'rails_helper'

describe ActionPush::Processor do
  before do
    @user = create(:user_with_session)
    @session = @user.sessions.first
    @shop = create(:shop)
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

  end

  describe '#fetch_action_for' do
  end
end
