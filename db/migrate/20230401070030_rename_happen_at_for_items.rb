class RenameHappenAtForItems < ActiveRecord::Migration[7.0]
  def change
    rename_column :items, :happen_at, :happened_at
  end
end
