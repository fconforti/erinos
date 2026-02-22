# frozen_string_literal: true

class User < ActiveRecord::Base
  has_many :user_credentials, dependent: :destroy
  has_many :user_identities, dependent: :destroy
  has_many :user_identity_links, dependent: :destroy
  has_many :user_contacts, dependent: :destroy
  has_many :user_tools, dependent: :destroy
  has_many :conversations, dependent: :destroy

  def credential(type)
    user_credentials.find_by(type: type)
  end
end
