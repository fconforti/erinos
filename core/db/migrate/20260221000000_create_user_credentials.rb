# frozen_string_literal: true

class CreateUserCredentials < ActiveRecord::Migration[8.0]
  def change
    create_table :user_credentials do |t|
      t.references :user, null: false, foreign_key: true
      t.string :type, null: false
      t.json :data, null: false, default: {}
      t.timestamps
    end
    add_index :user_credentials, [:user_id, :type], unique: true
  end
end
