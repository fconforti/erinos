# frozen_string_literal: true

class CreateModels < ActiveRecord::Migration[8.0]
  def change
    create_table :models do |t|
      t.string :provider, null: false
      t.string :name, null: false
      t.json :credentials, null: false, default: {}
      t.timestamps
    end

    add_index :models, %i[provider name], unique: true
  end
end
