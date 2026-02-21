# frozen_string_literal: true

class UserTool < ActiveRecord::Base
  belongs_to :user

  validates :tool, presence: true
  validates :tool, uniqueness: { scope: :user_id }
end
