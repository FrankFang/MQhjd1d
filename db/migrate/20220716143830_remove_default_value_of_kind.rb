class RemoveDefaultValueOfKind < ActiveRecord::Migration[7.0]
  def change
    change_column_default :items, :kind, from: 1, to: nil
    change_column_default :tags, :kind, from: 1, to: nil
  end
end
