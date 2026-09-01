class CreatePriceHistories < ActiveRecord::Migration[8.1]
  def change
    create_table :price_histories do |t|
      t.references :product, null: false, foreign_key: true
      t.decimal :price, precision: 12, scale: 2, null: false
      t.string :currency, null: false, default: "EUR"
      t.datetime :checked_at, null: false
    end

    add_index :price_histories, [ :product_id, :checked_at ]
  end
end
