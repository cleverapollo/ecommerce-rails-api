class Currency < MasterTable
  after_find :protect_it

  readonly

  class << self

    def rub
      Currency.find_by code: 'rub'
    end

    def usd
      Currency.find_by code: 'usd'
    end

    def eur
      Currency.find_by code: 'eur'
    end

    def gbp
      Currency.find_by code: 'gbp'
    end

  end


  def rub?
    code == 'rub'
  end

  def usd?
    code == 'rub'
  end

  def eur?
    code == 'eur'
  end

  def gbp?
    code == 'gbp'
  end


  # Переводит сумму из текушей валюты в указанную
  # @param [Currency] to
  # @return Float
  def recalculate_to(to, amount)
    return 0.0 if amount == 0
    if self.id == to.id
      amount.to_f
    else
      if rub?
        return amount.to_f / to.exchange_rate
      end
      if to.rub?
        return amount.to_f * exchange_rate
      end
      amount.to_f * exchange_rate / to.exchange_rate
    end
  end
end
