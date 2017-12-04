class AddJobIdInToDigestMailing < ActiveRecord::Migration
  def change
    add_column :digest_mailings, :job_id, :string
  end
end
