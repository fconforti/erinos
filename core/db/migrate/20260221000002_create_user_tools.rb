# frozen_string_literal: true

class CreateUserTools < ActiveRecord::Migration[8.0]
  def change
    create_table :user_tools do |t|
      t.references :user, null: false, foreign_key: true
      t.string :tool, null: false
      t.timestamps
    end

    add_index :user_tools, %i[user_id tool], unique: true
  end
end
