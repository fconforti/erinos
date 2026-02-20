# frozen_string_literal: true

class User < ActiveRecord::Base
  has_many :identities, dependent: :destroy
  has_many :identity_links, dependent: :destroy
  has_many :conversations, dependent: :destroy
end
