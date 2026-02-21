# frozen_string_literal: true

class CreateUserIdentityLinks < ActiveRecord::Migration[8.0]
  def change
    create_table :user_identity_links do |t|
      t.references :user, null: false, foreign_key: true
      t.string :code, null: false
      t.string :status, null: false, default: "pending"
      t.datetime :expires_at, null: false
      t.timestamps
    end

    add_index :user_identity_links, :code, unique: true
  end
end
