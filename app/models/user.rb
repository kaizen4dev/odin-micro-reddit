class User < ApplicationRecord
  has_many :comments
  has_many :posts

  validates :username, uniqueness: true, presence: true, length: { in: 3..20 }
end
