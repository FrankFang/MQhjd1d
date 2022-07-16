class AddDeletedAtForItems < ActiveRecord::Migration[7.0]
  def change
    add_column :items, :deleted_at, :datetime
  end
end
