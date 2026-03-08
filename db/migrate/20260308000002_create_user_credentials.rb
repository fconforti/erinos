class CreateUserCredentials < ActiveRecord::Migration[8.1]
  def change
    create_table :user_credentials do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.json :data, null: false, default: {}
      t.timestamps
    end

    add_index :user_credentials, [:user_id, :provider], unique: true
  end
end
