# Comentario del seguimiento comercial de un presupuesto, con su fecha/hora y
# el usuario que lo dejó (los antiguos pueden no tener usuario).
class QuoteComment < ApplicationRecord
  belongs_to :quote, inverse_of: :comments
  belongs_to :user, optional: true

  validates :body, presence: true

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }

  def author_name
    user&.name.presence || user&.email_address || "—"
  end
end
