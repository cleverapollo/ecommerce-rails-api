require 'rails_helper'

describe Profile do
  describe '.create linked profile' do
    context 'empty profile' do
      subject do
        profile = Profile.create
        profile.create_linked_profile(:gender, {gender:{'m'=>0, 'f'=>100}})
        profile.create_linked_profile(:child, {gender:{'m'=>0, 'f'=>100}})
        profile.create_linked_profile(:child, {gender:{'m'=>0, 'f'=>100}})
        profile
      end
      it 'created linked gender profile' do
        expect(subject.linked_profiles(:gender).first.gender).to eq({'m'=>0, 'f'=>100})
      end
      it 'created 2 child profile' do
        expect(subject.linked_profiles(:child).to_a.size).to eq(2)
      end
      it 'not created linked child profile' do
        expect(subject.linked_profiles(:animal).to_a).to eq([])
      end
    end
  end
end
