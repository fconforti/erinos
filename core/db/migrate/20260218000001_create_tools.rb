# frozen_string_literal: true

class CreateTools < ActiveRecord::Migration[8.0]
  def change
    create_table :tools do |t|
      t.string :name, null: false
      t.timestamps
    end

    add_index :tools, :name, unique: true
  end
end
