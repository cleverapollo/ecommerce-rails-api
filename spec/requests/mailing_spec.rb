require 'spec_helper'

describe "Mailing" do
  let!(:shop) { create(:shop) }

  before do
    @items = []

    5.times { @items << create(:item, shop: shop) }
  end

  it 'performs mailing' do
    mailing_params = {
      shop_id: shop.uniqid,
      shop_secret: shop.secret,

      send_from: 'tester <tester@tester.ru>',
      subject: 'Test email',
      template: '{{recommendations}}',
      recommendations_limit: 5,

      items: @items.map{|i| { id: i.uniqid, template: "#{i.uniqid}" } }
    }

    post 'mailings', mailing_params

    mailing = Mailing.first

    perform_params = {
      shop_id: shop.uniqid,
      shop_secret: shop.secret,

      id: mailing.token,

      users: (1..3).map{|i| { id: i, email: "#{i}@mail.ru" }}
    }

    Sidekiq::Testing.inline! do
      puts Benchmark.measure {
        post "mailings/#{mailing.token}/perform", perform_params
      }
    end

    expect(ActionMailer::Base.deliveries.count).to eq(3)
  end
end
