# before { @params = { ssid: sample_session_id, action: 'view', shop_id: 1, rating: 3 } }

# context 'parameters validation' do
#   shared_examples 'client error' do
#     it 'responds with 400' do
#       post :push, @params
#       expect(response.status).to eq(400)
#     end
#   end

#   context 'without ssid' do
#     before { @params[:ssid] = nil }
#     it_behaves_like 'client error'
#   end

#   context 'without action' do
#     before { @params[:action] = nil }
#     it_behaves_like 'client error'
#   end

#   context 'with unknown action' do
#     before { @params[:action] = 'potato' }
#     it_behaves_like 'client error'
#   end

#   context 'without shop_id' do
#     before { @params[:shop_id] = nil }
#     it_behaves_like 'client error'
#   end

#   context 'with incorrect rating' do
#     before { @params[:rating] = 6 }
#     it_behaves_like 'client error'
#   end
# end