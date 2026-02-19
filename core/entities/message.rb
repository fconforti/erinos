# frozen_string_literal: true

class Message < ActiveRecord::Base
  belongs_to :conversation
  validates :role, inclusion: { in: %w[user assistant system] }
  validates :content, presence: true
end
