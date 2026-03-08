class UserCredential < ActiveRecord::Base
  belongs_to :user
  validates :provider, presence: true, uniqueness: { scope: :user_id }
end
