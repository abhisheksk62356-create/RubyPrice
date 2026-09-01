class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.string :url, null: false
      t.string :canonical_url, null: false
      t.string :domain, null: false
      t.string :image_url
      t.decimal :current_price, precision: 12, scale: 2
      t.decimal :previous_price, precision: 12, scale: 2
      t.string :currency, null: false, default: "EUR"
      t.string :availability, null: false, default: "unknown"
      t.datetime :last_checked_at
      t.boolean :monitoring_enabled, null: false, default: true

      t.timestamps
    end

    add_index :products, :canonical_url, unique: true
    add_index :products, :domain
    add_index :products, :monitoring_enabled
  end
end
