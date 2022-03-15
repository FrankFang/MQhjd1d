class CreateValidationCodes < ActiveRecord::Migration[7.0]
  def change
    create_table :validation_codes do |t|
      t.string :email
      t.integer :kind, default: 1, null: false
      t.string :code, limit: 100
      t.datetime :used_at

      t.timestamps
    end
  end
end
