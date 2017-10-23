class HomeController < ApplicationController
  def index
    if WhiteLabel.personaclick?
      render text: 'PersonaClick'
    else
      render text: 'Battlecruiser operational.'
    end
  end
end
