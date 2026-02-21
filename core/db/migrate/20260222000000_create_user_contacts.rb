# frozen_string_literal: true

class CreateUserContacts < ActiveRecord::Migration[8.0]
  def change
    create_table :user_contacts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false
      t.string :phone
      t.timestamps
    end
    add_index :user_contacts, [:user_id, :email], unique: true
  end
end
