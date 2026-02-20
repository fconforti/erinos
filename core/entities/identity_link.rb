# frozen_string_literal: true

class IdentityLink < ActiveRecord::Base
  belongs_to :user

  before_validation :set_defaults, on: :create

  validates :code, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: %w[pending claimed expired] }
  validates :expires_at, presence: true

  private

  def set_defaults
    self.code ||= SecureRandom.alphanumeric(6).upcase
    self.status ||= "pending"
    self.expires_at ||= Time.current + 300
  end
end
