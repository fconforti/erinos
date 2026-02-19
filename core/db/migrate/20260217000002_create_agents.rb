# frozen_string_literal: true

class CreateAgents < ActiveRecord::Migration[8.0]
  def change
    create_table :agents do |t|
      t.references :model, null: false, foreign_key: true
      t.string :name, null: false
      t.text :instructions, null: false
      t.boolean :default, null: false, default: false
      t.timestamps
    end
    
    add_index :agents, :name, unique: true
  end
end
