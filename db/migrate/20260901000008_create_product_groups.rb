class CreateProductGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :product_groups do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false

      t.timestamps
    end

    add_reference :tracked_products, :product_group, foreign_key: true, null: true
  end
end
