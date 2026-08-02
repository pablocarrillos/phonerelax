# Landings por sector (colegios, eventos, empresas, oposiciones). El contenido de
# cada sector vive en los locales bajo la clave `sectors.<sector>`.
class SectorsController < ApplicationController
  allow_unauthenticated_access

  SECTORS = %w[colegios eventos empresas oposiciones].freeze

  def show
    @sector = params[:sector]
    raise ActiveRecord::RecordNotFound unless SECTORS.include?(@sector)
  end
end
