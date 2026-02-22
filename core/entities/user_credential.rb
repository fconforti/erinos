# frozen_string_literal: true

class UserCredential < ActiveRecord::Base
  belongs_to :user
  validates :type, presence: true, uniqueness: { scope: :user_id }
  validates :data, presence: true
end
