class User < ActiveRecord::Base
  has_many :user_credentials
  has_many :schedules
  has_many :memories

  validates :name, presence: true, uniqueness: true
  validates :pin, presence: true, uniqueness: true
  validates :telegram_id, uniqueness: true, allow_nil: true
end
