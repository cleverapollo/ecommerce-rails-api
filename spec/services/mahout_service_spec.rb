require 'spec_helper'

describe MahoutService do
  describe '.user_based' do
    before do
      @tunnel = Object.new
      allow(@tunnel).to receive(:user_based_block) {
        [1, 2, 3]
      }

      allow(BrB::Tunnel).to receive(:create) {
        @tunnel
      }
    end

    it 'calls recommend_block on brb tunnel' do
      MahoutService.user_based(1, {})

      expect(@tunnel).to have_received(:user_based_block).with(1, {})
    end
  end
end
