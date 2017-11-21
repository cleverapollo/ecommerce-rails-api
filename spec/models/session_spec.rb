require 'rails_helper'

describe Session do
  describe '.fetch' do
    context 'with existing session' do
      before { @session = create(:session, user: create(:user)) }
      subject { Session.fetch(code: @session.code ) }

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
      subject { Session.fetch(code: nil ) }

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
    subject { Session.create_with_code_and_user() }

    it 'returns session' do
      expect(subject).to be_an_instance_of(Session)
    end

    it 'assigns user to returned session' do
      expect(subject.user).to be_an_instance_of(User)
    end

  end

  describe '.create_user' do
    it 'updated session user_id' do
      session = Session.create! user_id: 999999999, code: 'fakecode'
      expect(session.user.blank?).to be_truthy
      session.create_user
      expect(Session.find_by(code: 'fakecode').user_id).not_to eq(999999999)
    end
  end

  describe '.atomic_save' do
    let!(:session) { create(:session, user_id: 1, code: 'fakecode') }
    it '.works' do
      expect(session.user_id).to eq(1)
      session.user_id = 2
      expect(session.atomic_save).to be_truthy
      expect(Session.find_by_code('fakecode').user_id).to eq(2)
      session.user_id = 1
      expect(session.atomic_save).to be_truthy
      expect(Session.find_by_code('fakecode').user_id).to eq(1)
    end
  end
end
