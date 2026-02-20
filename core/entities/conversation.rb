# frozen_string_literal: true

class Conversation < ActiveRecord::Base
  belongs_to :agent
  belongs_to :user
  has_many :messages, dependent: :destroy
end
