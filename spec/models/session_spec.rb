require 'rails_helper'

describe Session do
  describe '.fetch' do
    context 'with existing session' do
      before { @session = create(:session, user: create(:user)) }
      subject { Session.fetch(code: @session.code, useragent: 'Testerbot' ) }

      it 'returns that session' do
        expect(subject).to eq @session
      end

      context 'when user exists' do
        it 'returns session with that user' do
          expect(subject.user).to eq @session.user
        end
      end

      context 'when user not exists' do
        before { @session.user.destroy }

        it 'returns session with new user' do
          expect(subject.user).to be_an_instance_of(User)
        end
      end
    end

    context 'without existing session' do
      subject { Session.fetch(code: nil, useragent: 'Testerbot' ) }

      it 'creates new session' do
        expect{ subject }.to change(Session, :count).from(0).to(1)
      end

      it 'creates user for new session' do
        expect{ subject }.to change(User, :count).from(0).to(1)
      end

      it 'returns new session' do
        expect(subject).to be_an_instance_of(Session)
      end
    end
  end

  describe '.create_with_code_and_user' do
    subject { Session.create_with_code_and_user(useragent: 'Testerbot') }

    it 'returns session' do
      expect(subject).to be_an_instance_of(Session)
    end

    it 'assigns user to returned session' do
      expect(subject.user).to be_an_instance_of(User)
    end

    it 'assigns useragent to returned session' do
      expect(subject.useragent).to eq 'Testerbot'
    end
  end
end
