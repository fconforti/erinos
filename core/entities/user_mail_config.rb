# frozen_string_literal: true

class UserMailConfig < ActiveRecord::Base
  belongs_to :user

  validates :email, presence: true
  validates :imap_host, presence: true
  validates :smtp_host, presence: true
  validates :password, presence: true
  validates :user_id, uniqueness: true
end
