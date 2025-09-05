class Post < ApplicationRecord
  belongs_to :user
  has_many :comments

  validates :title, presence: true, length: { in: 3..40 }
  validates :body, presence: true, length: { maximum: 100000 }
end
