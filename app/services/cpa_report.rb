class CpaReport

  class << self

    def fee(order, shop)
      v = 0
      if order.source_type == 'RtbImpression'
        v = order.value * shop.remarketing_cpa / 100.0
        v = shop.remarketing_cpa_cap if v > shop.remarketing_cpa_cap
      end
      if order.source_type == 'RtbPropeller'
        v = order.value * shop.remarketing_cpa / 100.0
        v = shop.remarketing_cpa_cap if v > shop.remarketing_cpa_cap
      end
      if order.source_type == 'TriggerMail'
        v = order.value * shop.triggers_cpa / 100.0
        v = shop.triggers_cpa_cap if v > shop.triggers_cpa_cap
      end
      if order.source_type == 'DigestMail'
        v = order.value * shop.digests_cpa / 100.0
        v = shop.digests_cpa_cap if v > shop.digests_cpa_cap
      end
      v
    end

  end

end
