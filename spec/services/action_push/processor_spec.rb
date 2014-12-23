require 'rails_helper'

describe ActionPush::Processor do
  before do
    @user = create(:user_with_session)
    @session = @user.sessions.first
    @shop = create(:shop)
    @items = [ create(:item, shop: @shop) ]

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
  end

  describe '#fetch_action_for' do
  end
end
