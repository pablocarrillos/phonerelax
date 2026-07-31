class Post < ApplicationRecord
  validates :title, :slug, :body, presence: true
  validates :slug, uniqueness: true

  scope :recent_first, -> { order(published_on: :desc, id: :desc) }

  def to_param
    slug
  end
end
