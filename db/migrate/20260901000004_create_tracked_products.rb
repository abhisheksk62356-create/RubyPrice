class CreateTrackedProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :tracked_products do |t|
      t.references :user, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.decimal :target_price, precision: 12, scale: 2
      t.boolean :monitoring_enabled, null: false, default: true
      t.string :label

      t.timestamps
    end

    add_index :tracked_products, [ :user_id, :product_id ], unique: true
  end
end
