require "rails_helper"

describe Shop do
  it { expect(build(:shop)).to be_valid }

  describe "#allow_industrial?" do
    let(:plan)      { create(:plan) }
    let(:paid_till) { DateTime.now + 1.day }
    let(:shop)      { create(:shop, plan: plan, paid_till: paid_till) }

    context "plan type: free" do
      let(:plan) { create(:plan, plan_type: "free") }

      it { expect(shop.allow_industrial?).to be false }
    end

    context "plan type: custom" do
      let(:plan) { create(:plan, plan_type: "custom") }

      it { expect(shop.allow_industrial?).to be true }
    end

    context "expired paid_till" do
      let(:paid_till) { DateTime.now - 1.day }

      it { expect(shop.allow_industrial?).to be false }
    end
  end

  describe "#has_imported_yml?" do
    it { expect(build(:shop, :with_imported_yml).has_imported_yml?).to be true }
    it { expect(build(:shop, yml_file_url: nil).has_imported_yml?).to be false }
    it { expect(build(:shop, yml_loaded: false).has_imported_yml?).to be false }
    it { expect(build(:shop, yml_errors: 10).has_imported_yml?).to be false }
  end

  describe "#yml_expired?" do
    it { expect(build(:shop, last_valid_yml_file_loaded_at: nil, yml_load_period: 10, yml_errors: 0).yml_allow_import?).to be true }
    it { expect(build(:shop, last_valid_yml_file_loaded_at: nil, yml_load_period: 10, yml_errors: 5).yml_allow_import?).to be false }
    it { expect(build(:shop, last_valid_yml_file_loaded_at: Time.now, yml_load_period: 10, yml_errors: 0).yml_allow_import?).to be false }
    it { expect(build(:shop, last_valid_yml_file_loaded_at: Time.now, yml_load_period: 10, yml_errors: 5).yml_allow_import?).to be false }
    it { expect(build(:shop, last_valid_yml_file_loaded_at: Time.now.yesterday, yml_load_period: 10, yml_errors: 0).yml_allow_import?).to be true }
    it { expect(build(:shop, last_valid_yml_file_loaded_at: Time.now.yesterday, yml_load_period: 10, yml_errors: 5).yml_allow_import?).to be false }
  end

  describe ".import_yml_files" do
    let!(:shop) { create(:shop, :active, :connected, :with_imported_yml) }

    context "any yml allow import" do
      before { allow_any_instance_of(Shop).to receive(:yml_allow_import?).and_return(true) }
      before { Shop.import_yml_files }

      it { expect(YmlImporter).to have_enqueued_job(shop.id) }
    end

    context "any yml forbid import" do
      before { allow_any_instance_of(Shop).to receive(:yml_allow_import?).and_return(false) }
      before { Shop.import_yml_files }

      it { expect(YmlImporter).to_not have_enqueued_job(shop.id) }
    end
  end
end
