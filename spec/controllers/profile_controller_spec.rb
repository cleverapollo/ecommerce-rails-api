require 'rails_helper'

RSpec.describe ProfileController, :type => :controller do

  describe "GET check" do
    it "returns http success" do
      get :check
      expect(response).to have_http_status(:success)
    end
  end

end
