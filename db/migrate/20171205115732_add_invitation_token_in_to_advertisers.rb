class AddInvitationTokenInToAdvertisers < ActiveRecord::Migration
  def change
    add_column :advertisers, :invitation_tokens, :jsonb, default: {}
  end
end
