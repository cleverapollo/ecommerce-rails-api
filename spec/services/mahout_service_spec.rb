require 'spec_helper'

describe MahoutService do
  describe '.recommendations' do
    before do
      @tunnel = Object.new
      allow(@tunnel).to receive(:recommend_block) {
        [1, 2, 3]
      }

      allow(BrB::Tunnel).to receive(:create) {
        @tunnel
      }
    end

    it 'calls recommend_block on brb tunnel' do
      MahoutService.recommendations(1, {})

      expect(@tunnel).to have_received(:recommend_block).with(1, {})
    end
  end
end
