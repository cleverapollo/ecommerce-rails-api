require 'spec_helper'
require 'open-uri'

describe Rees46ML::File do
  [
    File.expand_path("files/yandex.xml", File.dirname(__FILE__)),
    File.expand_path("files/rees.xml", File.dirname(__FILE__))
  ].each do |path|
    context "parse #{ path }" do
      let(:file) { Rees46ML::File.new open(path), Logger.new(STDOUT).tap{|l| l.level = Logger::DEBUG } }

      it { expect{ file.lazy.take(500).each(&:attributes) }.to_not raise_error }
      # it { binding.pry }
      # it { d = file.lazy.select{|s| s.with_usupported_elements? }.take(5).force; binding.pry }

      it do
        yml_shop = file.lazy.detect{ |element| element.is_a?(Rees46ML::Shop) }
        yml_shop.categories.valid?
        yml_shop.locations.valid?

        file.lazy.select{ |element| element.is_a?(Rees46ML::Offer) }.each_with_index do |offer, index|
          category_ids = yml_shop.categories.path_to(offer.category_id)
          location_ids = offer.locations.flat_map{ |l| yml_shop.locations.path_to(l.id) }
        end
      end
    end
  end

  if ENV["INTEGRATION"]
    [
      "http://aromati-vostoka.ru/marketplace/22288.xml",
      "http://blasternerf.ru/feed/bnf.yml",
      "http://www.tsum.ru/upload/rees46.xml",
      "http://www.sexysecret.moscow/marketplace/17427.xml",
      "http://love-z.ru/upload/yml-new.1.xml",
      "http://static.ozone.ru/multimedia/yml/facet/div_tech.xml",
      "http://daril-ka.ru/export/yandex_market/15759/cbb9f688",
      "http://point-of-rise.ru/yandexmarket/70217e97-799e-4540-a006-ef8acb44a6fb.xml",
      "http://www.car-dvr.ru/yandex.xml",
      "http://antoshkaspb.ru/yandexmarket/7ff682cd-d656-453a-9506-775350f39455.xml"
    ].each do |path|
      context "parse #{ path }" do
        let(:file) { Rees46ML::File.new open(path) }

        it { expect{ file.lazy.take(500).each(&:attributes) }.to_not raise_error }
      end
    end
  end
end
