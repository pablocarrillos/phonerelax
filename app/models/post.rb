class Post < ApplicationRecord
  include Translatable
  translates :title, :excerpt, :body

  validates :title, :slug, :body, presence: true
  validates :slug, uniqueness: true
  validates :slug_pt, :slug_en, uniqueness: true, allow_blank: true

  # Si hay título traducido pero no slug propio, se genera automáticamente.
  before_validation :ensure_localized_slugs

  scope :recent_first, -> { order(published_on: :desc, id: :desc) }

  # Localiza por el slug de cualquier idioma (para poder resolver /pt/blog/<slug_pt>,
  # /en/blog/<slug_en> o el español).
  scope :by_any_slug, ->(value) { where(slug: value).or(where(slug_pt: value)).or(where(slug_en: value)) }

  # Slug del idioma dado (cae al español si no hay traducción o es el idioma por defecto).
  def slug_for(locale)
    return slug if locale.to_sym == I18n.default_locale

    column = "slug_#{locale}"
    (respond_to?(column) ? public_send(column) : nil).presence || slug
  end

  # La URL del post usa el slug del idioma activo.
  def to_param
    slug_for(I18n.locale)
  end

  private

  def ensure_localized_slugs
    self.slug_pt = title_pt.to_s.parameterize.presence if slug_pt.blank? && title_pt.present?
    self.slug_en = title_en.to_s.parameterize.presence if slug_en.blank? && title_en.present?
  end
end
