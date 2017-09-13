module RecRule
  class Params

    attr_accessor :limit, :rules, :raw, :rules
    # @return [Shop]
    attr_accessor :shop
    # @return [User]
    attr_accessor :user
    # @return [Session]
    attr_accessor :session

    # @param [RecommenderBlock] recommender_block
    # @param [Hash] params
    def initialize(recommender_block, params)
      self.limit = recommender_block.limit
      self.rules = recommender_block.rules
      self.shop = recommender_block.shop
      self.rules = recommender_block.rules
      self.raw = params

      extract_user
    end

    # Извлекает текущий товар
    # @return [Item]
    def item
      if @item.blank?
        if raw[:item_id].present?
          @item = Slavery.on_slave { Item.find_by(uniqid: raw[:item_id].to_s, shop_id: shop.id) }
        end
      end
      @item
    end

    def cart_item_ids
      if @cart_item_ids.nil?
        @cart_item_ids = ClientCart.find_by(shop: shop, user: user).try(:items) || []
      end
      @cart_item_ids
    end

    private

    # Извлекает юзера через сессию
    #
    # @private
    # @raise [Recommendations::IncorrectParams] в случае, если не удалось найти сессию.
    def extract_user
      if raw[:email].present?
        email = IncomingDataTranslator.email(raw[:email])
        client = Client.find_by email: email, shop_id: shop.id
        if client.nil?
          begin
            client = Client.create!(shop_id: shop.id, email: email, user_id: User.create.id)
          rescue # Concurrency?
            client =  Client.find_by email: email, shop_id: shop.id
          end
        end
        raise Recommendations::IncorrectParams.new('Client not found') if client.blank?

        self.session = Session.find_by user_id: client.user_id
        if self.session.nil?
          self.session = Session.create user_id: client.user_id
        end
      else
        self.session = Session.find_by_code(raw[:ssid])
        raise Recommendations::IncorrectParams.new('Invalid session') if self.session.blank?
      end

      # Убедиться, что у сессии есть юзер.
      if self.session.user.blank?
        self.session.create_user
      end
      self.user = self.session.user
    end

  end
end
