class CreateJobs < ActiveRecord::Migration[8.0]
  def change
    create_table :jobs do |t|
      t.string :service, null: false
      t.string :status, null: false, default: "queued"
      t.text :params
      t.text :result
      t.integer :progress, default: 0
      t.integer :total, default: 0
      t.text :error
      t.timestamps
    end

    add_index :jobs, :service
    add_index :jobs, :status
  end
end
