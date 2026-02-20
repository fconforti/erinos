# frozen_string_literal: true

class CreateIdentityLinks < ActiveRecord::Migration[8.0]
  def change
    create_table :identity_links do |t|
      t.references :user, null: false, foreign_key: true
      t.string :code, null: false
      t.string :status, null: false, default: "pending"
      t.datetime :expires_at, null: false
      t.timestamps
    end

    add_index :identity_links, :code, unique: true
  end
end
