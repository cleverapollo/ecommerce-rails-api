require 'factory_girl_rails' if Rails.env.development?

module Experimentor
  module PopulateHelper

    # Методы-сокращалки
    [:shop, :item, :user].each do |accessor|
      define_method accessor do
        @populate_data[accessor]
      end
    end

    def create(what, params={})
      @populate_data||={}
      @populate_data[what]||=[]
      @populate_data[what].push(FactoryGirl.create(what,params))
      @populate_data[what].last
    end

    def create_action(shop_data, user_data, item_data, action = 'view', recommended_by='similar')
      session = create(:session, user: user_data, code:SecureRandom.uuid)

      params = {
          event: action,
          shop_id: shop_data.uniqid,
          ssid: session.code,
          item_id: [item_data.id],
          #price: [14375, 25000],
          #is_available: [1, 0],
          #category: [191, 15],
          attributes: ['{"gender":"m","type":"shoe","sizes":["e39.5","e41","e41.5"],"brand":"ARTIOLI"}'],
          recommended_by: recommended_by
      }


      # Извлекаем данные из входящих параметров
      extracted_params = ActionPush::Params.extract(params)
      # Запускаем процессор с извлеченными данными
      ActionPush::Processor.new(extracted_params).process
    end

    def clear_model(model)
      model.delete_all
      model.reset_primary_key
      model.reset_sequence_name
      model.connection.reset_pk_sequence!(model.table_name)
    end

    def clear_all
      clear_model(Item)
      clear_model(User)
      clear_model(Action)
      clear_model(ItemCategory)
    end
  end
end
