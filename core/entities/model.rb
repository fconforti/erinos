# frozen_string_literal: true

class Model < ActiveRecord::Base
  has_many :agents

  validates :name, :provider, presence: true
  validates :name, uniqueness: { scope: :provider } 
end
