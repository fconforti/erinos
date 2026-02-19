# frozen_string_literal: true

class AgentTool < ActiveRecord::Base
  belongs_to :agent
  belongs_to :tool

  validates :agent_id, uniqueness: { scope: :tool_id }
end
