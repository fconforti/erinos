# frozen_string_literal: true

class Conversation < ActiveRecord::Base
  belongs_to :agent, optional: true
  has_many :messages, dependent: :destroy
end
