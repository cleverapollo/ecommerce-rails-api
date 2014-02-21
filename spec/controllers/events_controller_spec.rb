require 'spec_helper'

describe EventsController do
  describe 'POST push' do
    before { allow(ActionPush::ParamsExtractor).to receive(:extract).and_return({ some_parameters: 1 }) }
    before { allow(ActionPush::Processor).to receive(:process).and_return(true) }

    it 'extracts parameters' do
      post :push

      expect(ActionPush::ParamsExtractor).to have_received(:extract)
    end

    it 'passes extracted parameters to push service' do
      post :push

      expect(ActionPush::Processor).to have_received(:process).with({ some_parameters: 1 })
    end

    context 'when all goes fine' do
      it 'responds with ok status' do
        post :push

        expect(response.status).to eq(200)
      end

      it 'responds with ok message' do
        post :push

        expect(response.body).to eq({ status: 'success' }.to_json)
      end
    end

    context 'when error happens' do
      before { allow(ActionPush::ParamsExtractor).to receive(:extract).and_raise(PushEventError.new) }
      it 'responds with client error' do
        post :push

        expect(response.status).to eq(400)
      end
    end
  end
end
