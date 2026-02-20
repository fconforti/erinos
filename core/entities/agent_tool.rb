# frozen_string_literal: true

class AgentTool < ActiveRecord::Base
  belongs_to :agent

  validates :tool, presence: true
  validates :tool, uniqueness: { scope: :agent_id }
end
