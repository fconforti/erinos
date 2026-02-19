# frozen_string_literal: true

class Conversation < ActiveRecord::Base
  belongs_to :agent
  has_many :messages, dependent: :destroy
end
