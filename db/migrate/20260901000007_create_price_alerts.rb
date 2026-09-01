class CreatePriceAlerts < ActiveRecord::Migration[8.1]
  def change
    create_table :price_alerts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.decimal :target_price, precision: 12, scale: 2, null: false
      t.decimal :triggered_price, precision: 12, scale: 2
      t.datetime :triggered_at
      t.string :status, null: false, default: "pending"

      t.timestamps
    end

    add_index :price_alerts, :status
  end
end
