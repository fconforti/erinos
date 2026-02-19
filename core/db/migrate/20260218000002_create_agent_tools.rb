# frozen_string_literal: true

class CreateAgentTools < ActiveRecord::Migration[8.0]
  def change
    create_table :agent_tools do |t|
      t.references :agent, null: false, foreign_key: true
      t.references :tool, null: false, foreign_key: true
      t.timestamps
    end

    add_index :agent_tools, %i[agent_id tool_id], unique: true
  end
end
