# frozen_string_literal: true

class Tool < ActiveRecord::Base
  has_many :agent_tools, dependent: :destroy
  has_many :agents, through: :agent_tools

  validates :name, presence: true, uniqueness: true
end
