class Product < ApplicationRecord
  include Translatable
  translates :name, :description

  has_many :order_lines, dependent: :restrict_with_error
  has_many :product_images, -> { ordered }, dependent: :destroy, inverse_of: :product
  has_one_attached :cover_image
  has_many :price_tiers, -> { ordered }, dependent: :destroy, inverse_of: :product
  accepts_nested_attributes_for :price_tiers, allow_destroy: true,
                                              reject_if: ->(attrs) { attrs["min_units"].blank? && attrs["unit_price"].blank? }

  # Componentes cuando el producto es un pack (N unidades de otros productos).
  has_many :pack_items, -> { ordered }, foreign_key: :pack_id, dependent: :destroy, inverse_of: :pack
  has_many :components, through: :pack_items
  accepts_nested_attributes_for :pack_items, allow_destroy: true,
                                             reject_if: ->(attrs) { attrs["component_id"].blank? }

  validates :name, :price, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :stock, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # El precio de un pack se calcula con el escalado de sus componentes; se
  # guarda en `price` como caché para el admin y los datos estructurados.
  before_validation :sync_pack_price

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :name) }
  scope :packs, -> { where(pack: true) }
  scope :singles, -> { where(pack: false) }

  # URL amigable: usa el handle de Shopify como slug (/producto/funda-...);
  # si faltara, cae al id para no romper enlaces.
  def to_param
    shopify_handle.presence || id.to_s
  end

  # Resuelve el parámetro de la URL: slug (handle) o, para enlaces antiguos, id numérico.
  def self.find_by_param(param)
    find_by(shopify_handle: param) || (find_by(id: param) if param.to_s.match?(/\A\d+\z/))
  end

  def self.find_by_param!(param)
    find_by_param(param) || raise(ActiveRecord::RecordNotFound, "Couldn't find Product with param #{param.inspect}")
  end

  # Unidades disponibles: para un pack, cuántos packs se pueden montar con el
  # stock de sus componentes (el mínimo); para el resto, su propio stock.
  def available_stock
    return stock unless pack?
    return 0 if pack_items.empty?

    pack_items.map { |item| item.component.stock / item.quantity }.min
  end

  # Agotado: se sigue mostrando en la tienda pero no se puede comprar.
  def out_of_stock?
    available_stock <= 0
  end

  # Descuenta del stock las unidades vendidas: de cada componente si es un pack,
  # o del propio producto si no lo es.
  def consume_stock!(units)
    if pack?
      pack_items.includes(:component).each do |item|
        c = item.component
        c.update!(stock: [ c.stock - (item.quantity * units), 0 ].max)
      end
    else
      update!(stock: [ stock - units, 0 ].max)
    end
  end

  # Devuelve al stock las unidades (al borrar un pedido cobrado o deshacer).
  def restore_stock!(units)
    if pack?
      pack_items.includes(:component).each { |item| item.component.increment!(:stock, item.quantity * units) }
    else
      increment!(:stock, units)
    end
  end

  # Portada: la imagen subida desde el admin o, para productos antiguos que aún
  # no la tienen, la ruta estática guardada en image_url.
  def cover_url
    if cover_image.attached?
      Rails.application.routes.url_helpers.rails_blob_path(cover_image, only_path: true)
    else
      image_url
    end
  end

  def pack?
    pack
  end

  # PVP (IVA incluido) para una cantidad: para un pack, el precio del pack (suma
  # de sus componentes a su escalado); si no, aplica el escalado del producto o
  # el precio normal de la tienda.
  def price_for_quantity(quantity)
    return pack_unit_price if pack?

    tier = price_tiers.where(min_units: ..quantity).reorder(min_units: :desc).first
    return price unless tier

    (tier.unit_price * (1 + (vat_percentage.to_d / 100))).round(2)
  end

  # Precio (IVA incl.) de una unidad del pack: cada componente valorado a su
  # escalado por la cantidad incluida en el pack.
  def pack_unit_price
    pack_items.sum { |item| item.component.price_for_quantity(item.quantity) * item.quantity }
  end

  # Precio a mostrar en la tienda: calculado para packs, el guardado para el resto.
  def display_price
    pack? ? pack_unit_price : price
  end

  # Desglose del pack: por componente, precio normal vs. precio en pack y ahorro.
  # => [{ component:, quantity:, base_unit:, pack_unit:, line_total:, base_total:, saving: }]
  def pack_breakdown
    pack_items.map do |item|
      c = item.component
      base_unit = c.price                              # PVP normal (IVA incl.)
      pack_unit = c.price_for_quantity(item.quantity)  # con el escalado del pack
      { component: c, quantity: item.quantity, base_unit: base_unit, pack_unit: pack_unit,
        line_total: pack_unit * item.quantity, base_total: base_unit * item.quantity,
        saving: (base_unit - pack_unit) * item.quantity }
    end
  end

  # Precio del pack comprando los productos sueltos (para comparar) y ahorro total.
  def pack_base_total
    pack_breakdown.sum { |r| r[:base_total] }
  end

  def pack_total_saving
    pack_breakdown.sum { |r| r[:saving] }
  end

  # Precio SIN IVA para una cantidad (para ventas exentas: Canarias, exportación,
  # entrega intracomunitaria…). Es el PVP con IVA descontado el porcentaje.
  def net_price_for_quantity(quantity)
    (price_for_quantity(quantity) / (1 + (vat_percentage.to_d / 100))).round(2)
  end

  # Galería de la ficha: las imágenes gestionadas, o la de portada si no hay ninguna.
  def gallery_urls
    urls = product_images.map(&:src)
    urls.presence || [ cover_url ].compact_blank
  end

  private

  # Guarda en `price` el precio calculado del pack (caché para admin y schema);
  # los productos normales conservan su precio introducido a mano.
  def sync_pack_price
    self.price = pack_unit_price if pack?
  end
end
