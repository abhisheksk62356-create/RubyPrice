class CreateCrawlRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :crawl_runs do |t|
      t.references :product, foreign_key: true
      t.string :url, null: false
      t.string :status, null: false, default: "pending"
      t.integer :http_status
      t.integer :response_time_ms
      t.datetime :started_at
      t.datetime :completed_at
      t.string :error_code
      t.text :error_message

      t.timestamps
    end

    add_index :crawl_runs, :status
    add_index :crawl_runs, :created_at
  end
end
