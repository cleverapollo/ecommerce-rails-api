require 'rails_helper'

describe ItemLocationsMerger do
  describe '.merge' do
    let(:old_locations) { { '1' => { 'price' => 110 }, '2' => { 'price' => 100 }, '3' => { } } }
    subject { ItemLocationsMerger.merge(old_locations, new_locations) }

    context 'when new_locations is an array' do
      context 'when new_locations has elements' do
        let(:new_locations) { [1, 4] }

        it 'doesnt changes existing keys' do
          expect(subject['1']).to eq({ 'price' => 110 })
        end

        it 'adds new keys' do
          expect(subject.fetch('4')).to eq({ })
        end

        it 'removes absent keys' do
          expect(subject['2']).to be_nil
          expect(subject['3']).to be_nil
        end
      end
      context 'when new_locations is empty' do
        let(:new_locations) { [] }

        it 'does nothing' do
          does_nothing
        end
      end
    end

    context 'when new_locations is a hash' do
      context 'when new_locations has keys' do
        let(:new_locations) { { '1' => {}, '2' => { 'price' => 150}, '4' => { 'price' => 90 } } }

        it 'merges existing keys' do
          expect(subject['1']).to eq({ })
          expect(subject['2']).to eq({ 'price' => 150 })
        end

        it 'adds new keys' do
          expect(subject['4']).to eq({ 'price' => 90 })
        end

        it 'removes absent keys' do
          expect(subject['3']).to be_nil
        end
      end
      context 'when new_locations is empty' do
        let(:new_locations) { { } }

        it 'does nothing' do
          does_nothing
        end
      end
    end

    def does_nothing
      expect(subject).to eq(old_locations)
    end
  end
end
