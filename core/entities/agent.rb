# frozen_string_literal: true

class Agent < ActiveRecord::Base
  belongs_to :model
  has_many :agent_tools, dependent: :destroy

  validates :name, presence: true
end
