class AddKindToTags < ActiveRecord::Migration[7.0]
  def change
    add_column :tags, :kind, :integer, default: 1, null: false
  end
end
