require 'spec_helper'

describe ActionPush::Processor do
  describe '.process' do
    before { @params = OpenStruct.new(action: 'view') }
    subject { ActionPush::Processor.process(@params) }
    before { allow(Action).to receive(:get_factory).and_return(Actions::View) }
    before { allow(Actions::View).to receive(:push).and_return(true) }
    before { subject }

    it 'gets action factory' do
      expect(Action).to have_received(:get_factory).with(@params.action)
    end

    it 'passes params to factory.push' do
      expect(Actions::View).to have_received(:push).with(@params)
    end
  end
end
