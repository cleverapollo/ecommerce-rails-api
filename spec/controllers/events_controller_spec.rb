require 'rails_helper'

describe EventsController do
  describe 'POST push' do
    before { allow(ActionPush::Params).to receive(:extract).and_return(OpenStruct.new(action: 'view')) }
    before { allow(ActionPush::Processor).to receive(:new).and_return(ActionPush::Processor.new(OpenStruct.new(action: 'view'))) }
    before { allow_any_instance_of(ActionPush::Processor).to receive(:process).and_return(true) }
    let!(:session) { create(:session, user: create(:user)) }

    it 'extracts parameters' do
      post :push, ssid: session.code

      expect(ActionPush::Params).to have_received(:extract)
    end

    it 'passes extracted parameters to push service' do
      post :push, ssid: session.code

      expect(ActionPush::Processor).to have_received(:new)
    end

    context 'when all goes fine' do
      it 'responds with ok status' do
        post :push, ssid: session.code

        expect(response.status).to eq(200)
      end

      it 'responds with ok message' do
        post :push, ssid: session.code

        expect(response.body).to eq({ status: 'success' }.to_json)
      end
    end

    context 'when error happens' do
      before { allow(ActionPush::Params).to receive(:extract).and_raise(ActionPush::Error.new) }
      it 'responds with client error' do
        post :push, ssid: session.code

        expect(response.status).to eq(400)
      end
    end
  end
end
