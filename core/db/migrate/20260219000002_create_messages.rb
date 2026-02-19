# frozen_string_literal: true

class CreateMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.string :role, null: false
      t.text :content, null: false
      t.datetime :created_at, null: false
    end
  end
end
