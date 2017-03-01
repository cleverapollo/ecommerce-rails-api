require 'rails_helper'

describe TriggerMailing do

  describe '.valid_image_size?' do

    context 'validness' do

      it 'valid' do
        expect(TriggerMailing.valid_image_size?(120)).to be_truthy
        expect(TriggerMailing.valid_image_size?(140)).to be_truthy
        expect(TriggerMailing.valid_image_size?(160)).to be_truthy
        expect(TriggerMailing.valid_image_size?(180)).to be_truthy
        expect(TriggerMailing.valid_image_size?(200)).to be_truthy
        expect(TriggerMailing.valid_image_size?(220)).to be_truthy
      end

      it 'invalid' do
        expect(TriggerMailing.valid_image_size?(1)).to be_falsey
      end

    end

  end

end
