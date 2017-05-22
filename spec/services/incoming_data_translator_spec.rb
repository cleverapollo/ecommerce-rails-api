require 'rails_helper'

describe IncomingDataTranslator do
  it 'valid email' do
    expect(IncomingDataTranslator.email_valid?('test@gmail.com')).to be_truthy
  end
  it 'invalid email' do
    expect(IncomingDataTranslator.email_valid?('tanechka-a;leshina@inbox.ru')).to be_falsey
  end
end