# frozen_string_literal: true

class User < ActiveRecord::Base
  has_one :user_mail_config, dependent: :destroy
  has_many :user_identities, dependent: :destroy
  has_many :user_identity_links, dependent: :destroy
  has_many :user_tools, dependent: :destroy
  has_many :conversations, dependent: :destroy
end
