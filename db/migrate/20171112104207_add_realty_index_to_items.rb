class AddRealtyIndexToItems < ActiveRecord::Migration
  def change
    add_column :items, :realty_action, :string
    add_index "items", ["realty_action"], where: "((is_available = true) AND (ignored = false) AND (is_realty IS TRUE) AND (realty_action IS NOT NULL))"
    add_index "items", ["realty_type"], where: "((is_available = true) AND (ignored = false) AND (is_realty IS TRUE) AND (realty_type IS NOT NULL))"
    add_index "items", ["realty_space_min"], where: "((is_available = true) AND (ignored = false) AND (is_realty IS TRUE) AND (realty_space_min IS NOT NULL))"
    add_index "items", ["realty_space_max"], where: "((is_available = true) AND (ignored = false) AND (is_realty IS TRUE) AND (realty_space_max IS NOT NULL))"
    add_index "items", ["realty_space_final"], where: "((is_available = true) AND (ignored = false) AND (is_realty IS TRUE) AND (realty_space_final IS NOT NULL))"
  end
end
