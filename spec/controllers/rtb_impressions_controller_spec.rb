require 'rails_helper'

describe RtbImpressionsController do

  describe 'POST create' do
    let(:shop) { create(:shop) }
    let(:rtb_job) { create(:rtb_job, shop: shop, item_id: 1, price: 1000, user_id: 1 )}
    context 'when rtb_job ID is correct' do
      it 'creates rtb impression and returns it code' do
        post :create, shop_id: shop.uniqid, rtb_job_id: rtb_job.id
        expect(response.code).to eq('200')
        expect(JSON.parse(response.body)).to eq ({'code' => rtb_job.rtb_impressions.first.code})
      end
    end

    context 'when rtb_job ID is not correct' do
      it 'renders error' do
        post :create, shop_id: shop.uniqid, rtb_job_id: '-1'
        expect(response.code).to eq('404')
      end
    end

    # Because advertising platform can show our ad after ad become disabled
    context 'when rtb_job inactive' do
      it 'creates impression anyway' do
        rtb_job.update active: false
        post :create, shop_id: shop.uniqid, rtb_job_id: rtb_job.id
        expect(response.code).to eq('200')
        expect(JSON.parse(response.body)).to eq ({'code' => rtb_job.rtb_impressions.first.code})
      end
    end

  end

end
