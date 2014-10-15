require 'spec_helper'

describe Action do
  describe '.get_implementation_for' do
    subject { Action.get_implementation_for(@action_type) }

    context 'with existing action type' do
      Action::TYPES.each do |type|
        context "for type #{type}" do
          before { @action_type = type }

          it 'returns class implementation' do
            expect(subject).to be_a(Class)
          end
        end
      end
    end

    context 'without existing aciton type' do
      before { @action_type = 'potato' }

      it 'raises ActionPush::Error' do
        expect{ subject }.to raise_error(ActionPush::Error)
      end
    end
  end

  describe '#update_concrete_action_attrs' do
    it 'raises NotImplementedError' do
      expect{ Action.new.update_concrete_action_attrs }.to raise_error(NotImplementedError)
    end
  end

  describe '#update_rating_and_last_action' do
    it 'raises NotImplementedError' do
      expect{ Action.new.update_rating_and_last_action('anything') }.to raise_error(NotImplementedError)
    end
  end

  describe '#needs_to_update_rating?' do
    it 'raises NotImplementedError' do
      expect{ Action.new.needs_to_update_rating? }.to raise_error(NotImplementedError)
    end
  end

end
