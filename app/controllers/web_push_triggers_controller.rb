##
# Контроллер, отвечающий за триггерные веб пуш рассылки.
#
class WebPushTriggersController < ApplicationController
  include ShopAuthenticator

  def send_test
    raise NotImplementedError
  end

end
