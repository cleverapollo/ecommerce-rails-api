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

      it 'raises ArgumentError' do
        expect{ subject }.to raise_error(ArgumentError)
      end
    end
  end
end
